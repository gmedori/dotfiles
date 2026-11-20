import Foundation

/// Reads Teleport versions from what `tsh version` prints and from what people type.
enum TshVersionParser {
	/// The version on the first line that starts with `Teleport`, without its leading `v`, or `nil`
	/// when no line has one.
	static func version(from output: String) -> String? {
		for line in output.split(whereSeparator: \.isNewline) {
			let fields = line.split(whereSeparator: \.isWhitespace)
			guard fields.first == "Teleport" else {
				continue
			}

			for field in fields.dropFirst() {
				guard field.first == "v" else {
					continue
				}

				let version = field.dropFirst()
				if version.first?.isNumber == true {
					return String(version)
				}
			}
		}

		return nil
	}

	/// The version without surrounding whitespace or a leading `v`, so `v18.8.2` matches `18.8.2`.
	static func normalize(_ version: String) -> String {
		let trimmed = version.trimmingCharacters(in: .whitespacesAndNewlines)
		if trimmed.first == "v", trimmed.dropFirst().first?.isNumber == true {
			return String(trimmed.dropFirst())
		}
		return trimmed
	}
}
