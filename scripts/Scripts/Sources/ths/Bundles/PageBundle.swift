import CommandKit
import CryptoKit
import Foundation
import Yams

// MARK: - Page Bundle

/// A post's folder in the site repo, `content/blog/<slug>/`, as a set of files keyed by their path
/// in the folder.
///
/// A bundle `ths` generated carries two fields under `params` in its front matter:
///
/// - `vaultSource` is the note it came from, written as `$THS_SOURCE_DIR/<path>` so it doesn't
///   depend on where the vault is.
/// - `generatedHash` is the `contentHash` of the bundle as `ths` wrote it. If the files on disk no
///   longer hash to it, someone changed the bundle after the last sync.
///
/// A bundle with `vaultSource` is managed by `ths`. Any other bundle was made some other way, and
/// `ths` never changes or deletes it.
struct PageBundle: Equatable, Sendable {
	static let indexName = "index.md"
	/// Files the operating system drops into folders, which aren't part of a bundle.
	static let ignoredNames: Set = [".DS_Store"]

	let files: [String: Data]

	// MARK: Generating

	/// Builds the bundle for a post, reading its images from the vault.
	static func generate(for post: BlogPost, body: ConvertedBody) throws -> PageBundle {
		var files: [String: Data] = [:]
		for image in body.images {
			do {
				files[image.name] = try Data(contentsOf: image.source)
			} catch {
				throw RuntimeError("Couldn't read \(image.source.path(percentEncoded: false)): \(error.localizedDescription)")
			}
		}

		files[indexName] = Data(index(for: post, body: body, hash: nil).utf8)
		let hash = contentHash(of: files)
		files[indexName] = Data(index(for: post, body: body, hash: hash).utf8)
		return PageBundle(files: files)
	}

	/// The bundle's `index.md`. Values are written as JSON strings, which are also valid YAML
	/// double-quoted strings, so any text survives. The `generatedHash` line is left out when `hash`
	/// is `nil`, which is how `contentHash` sees the file.
	static func index(for post: BlogPost, body: ConvertedBody, hash: String?) -> String {
		var lines = ["---"]
		lines.append("title: \(quoted(body.title ?? ""))")
		lines.append("slug: \(quoted(post.slug ?? ""))")
		if let date = post.date {
			lines.append("date: \(date)")
		}
		lines.append("draft: \(post.status != .published)")
		if let description = post.description {
			lines.append("description: \(quoted(description))")
		}
		if !post.tags.isEmpty {
			lines.append("tags:")
			lines += post.tags.map { "  - \(quoted($0))" }
		}
		lines.append("params:")
		lines.append("  vaultSource: \(quoted(vaultSource(for: post)))")
		if let hash {
			lines.append("  generatedHash: \(quoted(hash))")
		}
		lines.append("---")
		lines.append("")
		return lines.joined(separator: "\n") + "\n" + body.markdown
	}

	static func vaultSource(for post: BlogPost) -> String {
		"$\(SitePaths.sourceVariable)/\(post.relativePath)"
	}

	private static func quoted(_ value: String) -> String {
		let encoder = JSONEncoder()
		encoder.outputFormatting = [.withoutEscapingSlashes]
		return String(decoding: try! encoder.encode(value), as: UTF8.self)
	}

	// MARK: Hashing

	/// A SHA-256 over every file in the bundle, sorted by path, with the `generatedHash` line removed
	/// from `index.md` so the hash can be stored in the file it covers. Each file contributes its
	/// path, a NUL byte, its size as 8 big-endian bytes, and its contents, so no two different
	/// bundles hash the same.
	static func contentHash(of files: [String: Data]) -> String {
		var hasher = SHA256()
		for path in files.keys.sorted() {
			var data = files[path]!
			if path == indexName {
				data = removingHashLine(from: data)
			}
			hasher.update(data: Data(path.utf8))
			hasher.update(data: Data([0]))
			withUnsafeBytes(of: UInt64(data.count).bigEndian) { hasher.update(bufferPointer: $0) }
			hasher.update(data: data)
		}
		return "sha256:" + hasher.finalize().map { String(format: "%02x", $0) }.joined()
	}

	private static func removingHashLine(from data: Data) -> Data {
		let text = String(decoding: data, as: UTF8.self)
		return Data(text.replacing(/\n  generatedHash: "[^"\n]*"/, with: "", maxReplacements: 1).utf8)
	}

	/// The bundle's files with the `generatedHash` line removed from `index.md`, for comparing a
	/// bundle on disk with a freshly generated one regardless of what hash each stores.
	var filesWithoutHash: [String: Data] {
		var files = files
		if let index = files[Self.indexName] {
			files[Self.indexName] = Self.removingHashLine(from: index)
		}
		return files
	}
}

// MARK: - Existing Bundle

/// A bundle already in the site repo.
struct ExistingBundle: Equatable, Sendable {
	let slug: String
	let directory: URL
	let bundle: PageBundle
	/// `params.vaultSource`, or `nil` when `ths` didn't generate the bundle.
	let vaultSource: String?
	/// `params.generatedHash`, as stored in the front matter.
	let storedHash: String?
	/// Whether the front matter says `draft: true`. A bundle without the field is published, which
	/// matches Hugo.
	let isDraft: Bool

	var isManaged: Bool {
		vaultSource != nil
	}

	/// Whether the files on disk are still the ones `ths` wrote.
	var matchesStoredHash: Bool {
		storedHash == PageBundle.contentHash(of: bundle.files)
	}

	/// Reads every bundle in `content/blog/` of the site repo. Files directly in `content/blog/`,
	/// like the section's `_index.md`, aren't bundles.
	static func readAll(in siteDirectory: URL) throws -> [String: ExistingBundle] {
		let blogDirectory = siteDirectory.appending(path: "content/blog", directoryHint: .isDirectory)
		let entries = try FileManager.default.contentsOfDirectory(
			at: blogDirectory,
			includingPropertiesForKeys: [.isDirectoryKey],
			options: [.skipsHiddenFiles],
		)

		var bundles: [String: ExistingBundle] = [:]
		for entry in entries where (try? entry.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true {
			let bundle = try read(from: entry)
			bundles[bundle.slug] = bundle
		}
		return bundles
	}

	static func read(from directory: URL) throws -> ExistingBundle {
		let base = directory.standardizedFileURL.path(percentEncoded: false)
		guard let enumerator = FileManager.default.enumerator(
			at: directory,
			includingPropertiesForKeys: [.isRegularFileKey],
		) else {
			throw RuntimeError("Couldn't read \(base).")
		}

		var files: [String: Data] = [:]
		for case let url as URL in enumerator {
			guard
				!PageBundle.ignoredNames.contains(url.lastPathComponent),
				(try url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true
			else {
				continue
			}
			let path = url.standardizedFileURL.path(percentEncoded: false)
			files[String(path.dropFirst(base.count).trimmingPrefix("/"))] = try Data(contentsOf: url)
		}

		let frontmatter = files[PageBundle.indexName].flatMap {
			try? Frontmatter.parse(String(decoding: $0, as: UTF8.self))
		}
		let params = frontmatter?.properties["params"]?.mapping
		return ExistingBundle(
			slug: directory.lastPathComponent,
			directory: directory,
			bundle: PageBundle(files: files),
			vaultSource: params?["vaultSource"]?.string,
			storedHash: params?["generatedHash"]?.string,
			isDraft: frontmatter?.string("draft") == "true",
		)
	}
}
