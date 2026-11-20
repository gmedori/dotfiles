import Foundation

extension String {
	/// The path with a leading `~` replaced by `homeDirectory`, the way a shell expands `~` and
	/// `~/path`.
	func expandingTilde(homeDirectory: URL) -> String {
		guard self == "~" || hasPrefix("~/") else {
			return self
		}

		let home = homeDirectory.path(percentEncoded: false)
		return (home.hasSuffix("/") ? String(home.dropLast()) : home) + dropFirst()
	}
}
