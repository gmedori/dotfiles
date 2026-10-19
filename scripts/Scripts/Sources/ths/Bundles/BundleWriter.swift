import Foundation

// MARK: - Bundle Writer

/// Writes and deletes bundles in the site repo's `content/blog/`. Nothing outside a bundle's own
/// folder is ever touched.
struct BundleWriter {
	let siteDirectory: URL

	private var blogDirectory: URL {
		siteDirectory.appending(path: "content/blog", directoryHint: .isDirectory)
	}

	/// Makes the bundle's folder hold exactly `bundle`'s files: writes the ones that are missing or
	/// different, and removes the ones `bundle` doesn't have. Files the operating system adds, like
	/// `.DS_Store`, are left alone.
	func write(_ bundle: PageBundle, slug: String) throws {
		let directory = blogDirectory.appending(path: slug, directoryHint: .isDirectory)
		let fileManager = FileManager.default
		try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)

		let existing = try ExistingBundle.read(from: directory).bundle.files
		for (path, data) in bundle.files where existing[path] != data {
			let url = directory.appending(path: path)
			try fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
			try data.write(to: url, options: .atomic)
		}
		for path in existing.keys where bundle.files[path] == nil {
			try fileManager.removeItem(at: directory.appending(path: path))
		}
	}

	/// Deletes a bundle's folder.
	func delete(slug: String) throws {
		try FileManager.default.removeItem(at: blogDirectory.appending(path: slug, directoryHint: .isDirectory))
	}
}
