import Foundation

/// Formats paths to `tsh` binaries for display.
enum TshPathFormatter {
	/// The URL's path, with `homeDirectory` shortened to `~`.
	static func display(
		_ url: URL,
		homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser,
	) -> String {
		let path = url.standardizedFileURL.path
		let homePath = homeDirectory.standardizedFileURL.path
		if path == homePath {
			return "~"
		}
		if path.hasPrefix(homePath + "/") {
			return "~" + path.dropFirst(homePath.count)
		}
		return path
	}
}
