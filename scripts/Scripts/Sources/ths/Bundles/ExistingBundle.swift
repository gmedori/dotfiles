import CommandKit
import Foundation
import Yams

/// A bundle already in the site repo.
struct ExistingBundle: Equatable, Sendable {
	/// The slug, which is the name of the bundle's folder.
	var slug: String
	/// The bundle's folder in the site repo.
	var directory: URL
	/// The files in the folder, as they are on disk.
	var bundle: PageBundle
	/// `params.vaultSource`, or `nil` when `ths` didn't generate the bundle.
	var vaultSource: String? = nil
	/// `params.generatedHash`, as stored in the front matter.
	var storedHash: String? = nil
	/// Whether the front matter sets `draft` to `true`, `True`, or `TRUE`, the only spellings that YAML
	/// 1.2 and Hugo both read as true. Any other value counts as published, since `sync` never deletes
	/// a published bundle. A bundle without the field is published, which matches Hugo.
	var isDraft: Bool

	/// Whether `ths` generated the bundle, which it knows from `vaultSource`. `ths` never changes or
	/// deletes a bundle it doesn't manage.
	var isManaged: Bool {
		vaultSource != nil
	}

	/// Whether the files on disk are still the ones `ths` wrote.
	var matchesStoredHash: Bool {
		storedHash == PageBundle.contentHash(of: bundle.files)
	}
}

// MARK: - Static Members

extension ExistingBundle {
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
		// Ignoring the error here means an entry whose type can't be read isn't treated as a bundle.
		for entry in entries where (try? entry.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true {
			let bundle = try read(from: entry)
			bundles[bundle.slug] = bundle
		}
		return bundles
	}

	/// Reads the bundle in `directory`, skipping files like `.DS_Store` that aren't part of it.
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
				try (url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true
			else {
				continue
			}

			let path = url.standardizedFileURL.path(percentEncoded: false)
			files[String(path.dropFirst(base.count).trimmingPrefix("/"))] = try Data(contentsOf: url)
		}

		// Ignoring the error here means a bundle whose front matter can't be read counts as a published
		// bundle that `ths` doesn't manage, which it never changes or deletes.
		let frontmatter = files[PageBundle.indexName].flatMap { data in
			try? Frontmatter.parse(String(bytes: data, encoding: .utf8) ?? "")
		}
		let params = frontmatter?.properties["params"]?.mapping
		return ExistingBundle(
			slug: directory.lastPathComponent,
			directory: directory,
			bundle: PageBundle(files: files),
			vaultSource: params?["vaultSource"]?.string,
			storedHash: params?["generatedHash"]?.string,
			isDraft: frontmatter?.bool("draft") == true,
		)
	}
}
