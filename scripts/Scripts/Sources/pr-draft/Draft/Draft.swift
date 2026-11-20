import CommandKit
import Foundation
import Yams

// MARK: - Draft

/// A PR draft from the vault, as the pr-description skill writes it.
///
/// The frontmatter holds `repo`, `branch`, and `base`. The first line that starts with `# ` is the
/// pull request's title, and the lines after it are the body.
struct Draft: Equatable {
	/// The GitHub repository, as `owner/name`.
	let repo: String?
	/// The branch with the changes, slashes included.
	let branch: String?
	/// The branch the pull request merges into.
	let base: String?
	/// The title line's text without the `# `, or `nil` when the draft has no title line.
	let title: String?
	/// The lines after the title line, or every line after the frontmatter when there's no title.
	let bodyLines: [String]
	/// The 1-based line number in the file of the first line in `bodyLines`.
	let bodyStartLine: Int

	/// The frontmatter properties a pull request needs that the draft doesn't have, in the order
	/// they're listed in the draft format.
	var missingProperties: [String] {
		[("repo", repo), ("branch", branch), ("base", base)].filter { $0.1 == nil }.map(\.0)
	}

	static func parse(_ text: String) throws -> Draft {
		var lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
		var properties = Yams.Node.Mapping([])
		var frontmatterLineCount = 0

		if lines.first.map(isDelimiter) == true {
			guard let closing = lines.dropFirst().firstIndex(where: isDelimiter) else {
				throw RuntimeError("The draft's frontmatter never closes with `---`.")
			}

			properties = try parseProperties(lines[1 ..< closing].joined(separator: "\n"))
			frontmatterLineCount = closing + 1
		}
		lines.removeFirst(frontmatterLineCount)

		func value(_ key: String) -> String? {
			guard let text = properties[key]?.scalar?.string.trimmingCharacters(in: .whitespaces) else {
				return nil
			}

			return ["", "~", "null"].contains(text) ? nil : text
		}

		guard let titleIndex = lines.firstIndex(where: { $0.hasPrefix("# ") }) else {
			return Draft(
				repo: value("repo"),
				branch: value("branch"),
				base: value("base"),
				title: nil,
				bodyLines: lines,
				bodyStartLine: frontmatterLineCount + 1,
			)
		}

		return Draft(
			repo: value("repo"),
			branch: value("branch"),
			base: value("base"),
			title: lines[titleIndex].dropFirst(2).trimmingCharacters(in: .whitespaces),
			bodyLines: Array(lines[(titleIndex + 1)...]),
			bodyStartLine: frontmatterLineCount + titleIndex + 2,
		)
	}

	private static func parseProperties(_ yaml: String) throws -> Yams.Node.Mapping {
		let node: Yams.Node?
		do {
			node = try Yams.compose(yaml: yaml)
		} catch {
			throw RuntimeError("The draft's frontmatter isn't valid YAML. \(error)")
		}
		switch node {
			case nil:
				return Yams.Node.Mapping([])
			case let .mapping(mapping)?:
				return mapping
			default:
				throw RuntimeError("The draft's frontmatter isn't a list of properties.")
		}
	}

	private static func isDelimiter(_ line: String) -> Bool {
		line.trimmingCharacters(in: .whitespaces) == "---"
	}
}
