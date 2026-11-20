import CommandKit
import CryptoKit
import Foundation

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
	/// The contents of every file in the bundle, keyed by its path in the folder.
	var files: [String: Data]

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

// MARK: - Static Members

extension PageBundle {
	/// The name of the Markdown file Hugo renders as the page.
	static let indexName = "index.md"
	/// Files the operating system drops into folders, which aren't part of a bundle.
	static let ignoredNames: Set = [".DS_Store"]

	// MARK: Generating

	/// Builds the bundle for a post, reading its images from the vault.
	static func generate(for post: BlogPost, body: ConvertedBody) throws -> PageBundle {
		var files: [String: Data] = [:]
		for image in body.images {
			do {
				files[image.name] = try Data(contentsOf: image.source)
			} catch {
				throw RuntimeError(
					"Couldn't read \(image.source.path(percentEncoded: false)): \(error.localizedDescription)"
				)
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
	///
	/// The front matter is written by hand rather than serialized with Yams, so the `generatedHash`
	/// line always has the exact form `removingHashLine` looks for, and the bytes that get hashed
	/// don't depend on how Yams formats YAML.
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

	/// The `vaultSource` for a post, its path written from `$THS_SOURCE_DIR`.
	static func vaultSource(for post: BlogPost) -> String {
		"$\(SitePaths.sourceVariable)/\(post.relativePath)"
	}

	// MARK: Hashing

	/// A SHA-256 over every file in the bundle, sorted by path, with the `generatedHash` line removed
	/// from `index.md` so the hash can be stored in the file it covers. Each file contributes these,
	/// in order, so no two different bundles hash the same:
	///
	/// - Its path
	/// - A NUL byte
	/// - Its size as 8 big-endian bytes
	/// - Its contents
	static func contentHash(of files: [String: Data]) -> String {
		var hasher = SHA256()
		for (path, contents) in files.sorted(by: { $0.key < $1.key }) {
			let data = path == indexName ? removingHashLine(from: contents) : contents
			hasher.update(data: Data(path.utf8))
			hasher.update(data: Data([0]))
			withUnsafeBytes(of: UInt64(data.count).bigEndian) { hasher.update(bufferPointer: $0) }
			hasher.update(data: data)
		}
		return "sha256:" + hasher.finalize().map { String(format: "%02x", $0) }.joined()
	}
}

// MARK: - Private Helpers

extension PageBundle {
	private static func quoted(_ value: String) -> String {
		let encoder = JSONEncoder()
		encoder.outputFormatting = [.withoutEscapingSlashes]
		do {
			guard let json = try String(bytes: encoder.encode(value), encoding: .utf8) else {
				preconditionFailure("JSONEncoder wrote a string that isn't UTF-8.")
			}

			return json
		} catch {
			preconditionFailure("JSONEncoder couldn't encode a string: \(error)")
		}
	}

	private static func removingHashLine(from data: Data) -> Data {
		let text = String(decoding: data, as: UTF8.self)
		return Data(text.replacing(/\n  generatedHash: "[^"\n]*"/, with: "", maxReplacements: 1).utf8)
	}
}
