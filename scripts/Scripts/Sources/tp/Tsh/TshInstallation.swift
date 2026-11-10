import ArgumentParser
import Foundation

// MARK: - Installation Source

enum TshSource: String, CaseIterable, ExpressibleByArgument, Sendable {
	case connect
	case standalone
	case managed
	case homebrew
	case source
	case other
}

// MARK: - Installation

struct TshInstallation: Equatable, Sendable {
	let version: String
	let versionOutput: String
	let url: URL
	let source: TshSource

	var displayPath: String {
		TshPathFormatter.display(url)
	}
}

// MARK: - Version Parsing

enum TshVersionParser {
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

	static func normalize(_ version: String) -> String {
		let trimmed = version.trimmingCharacters(in: .whitespacesAndNewlines)
		if trimmed.first == "v", trimmed.dropFirst().first?.isNumber == true {
			return String(trimmed.dropFirst())
		}
		return trimmed
	}
}

// MARK: - Installation Selection

enum TshSelector {
	static func select(
		version requestedVersion: String,
		source: TshSource?,
		from installations: [TshInstallation]
	) throws -> TshInstallation {
		let requestedVersion = TshVersionParser.normalize(requestedVersion)
		let matches = installations.filter {
			$0.version == requestedVersion && (source == nil || $0.source == source)
		}

		guard !matches.isEmpty else {
			let sourceDescription = source.map { " from \($0.rawValue)" } ?? ""
			throw ValidationError(
				"No discovered tsh installation reports version \(requestedVersion)\(sourceDescription). "
					+ "Run 'tp tsh list' to see available installations."
			)
		}

		guard matches.count == 1 else {
			let choices = matches
				.map { "  \($0.source.rawValue): \($0.displayPath)" }
				.joined(separator: "\n")
			throw ValidationError(
				"Multiple installations provide tsh \(requestedVersion):\n\(choices)\n"
					+ "Use --source or --path to select one."
			)
		}

		return matches[0]
	}
}

// MARK: - Path Formatting

enum TshPathFormatter {
	static func display(
		_ url: URL,
		homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser
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
