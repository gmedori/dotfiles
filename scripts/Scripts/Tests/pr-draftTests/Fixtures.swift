import Foundation

/// A throwaway vault in the temp folder, deleted when the fixture goes away.
final class TemporaryVault {
	let root: URL

	init() throws {
		root = FileManager.default.temporaryDirectory
			.appending(path: "pr-draft-tests-\(UUID().uuidString)", directoryHint: .isDirectory)
			.resolvingSymlinksInPath()
		try FileManager.default.createDirectory(at: root.appending(path: ".obsidian"), withIntermediateDirectories: true)
	}

	deinit {
		try? FileManager.default.removeItem(at: root)
	}

	/// Writes a file at `path` from the vault root, creating its folders. A file's contents default to
	/// its path, so copies can be told apart.
	@discardableResult
	func write(_ path: String, _ contents: String? = nil) throws -> URL {
		let url = root.appending(path: path)
		try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
		try (contents ?? path).write(to: url, atomically: true, encoding: .utf8)
		return url
	}

	func read(_ url: URL) throws -> String {
		try String(contentsOf: url, encoding: .utf8)
	}
}

extension URL {
	/// The path without a trailing slash or the `/private` that `pwd -P` puts in front of temp
	/// folders. It works on folders that no longer exist, which `resolvingSymlinksInPath()` leaves
	/// alone.
	var normalizedPath: String {
		var path = standardizedFileURL.path(percentEncoded: false)
		if path.hasPrefix("/private/") {
			path.removeFirst("/private".count)
		}
		return path.count > 1 && path.hasSuffix("/") ? String(path.dropLast()) : path
	}
}
