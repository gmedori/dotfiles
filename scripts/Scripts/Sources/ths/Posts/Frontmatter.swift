import Foundation
import Yams

// MARK: - Frontmatter

/// A Markdown file split into its YAML frontmatter and its body.
///
/// The YAML is composed into a `Yams.Node` instead of decoded, so every value stays the text it was
/// written as. Decoding would turn `date: 2025-03-31` into a `Date` at midnight UTC and lose what the
/// author typed.
struct Frontmatter {
	let properties: Yams.Node.Mapping
	let body: String
	/// The 1-based line number in the file where `body` starts.
	let bodyStartLine: Int

	enum ParseError: Error, Equatable {
		/// The file opens with `---` but never closes the block.
		case unterminated
		/// The block isn't YAML, or isn't a mapping of keys to values.
		case invalidYAML(String)
	}

	/// The default resolver from Yams, with booleans read the way YAML 1.2 reads them. Only `true` and
	/// `false` are booleans, in lowercase, capitalized, or all caps. The default follows YAML 1.1,
	/// which also reads `yes`, `on`, and their opposites as booleans. Hugo doesn't.
	///
	/// Yams doesn't mark `Resolver` as `Sendable`, but its rules are constants, so one instance is
	/// safe to share.
	nonisolated(unsafe) private static let resolver = Yams.Resolver.default.replacing(
		try! Yams.Resolver.Rule(.bool, "^(?:true|True|TRUE|false|False|FALSE)$")
	)

	/// Splits `text` into frontmatter and body. Returns `nil` when the file has no frontmatter, which
	/// is any file whose first line isn't `---`.
	static func parse(_ text: String) throws(ParseError) -> Frontmatter? {
		let lines = text.split(separator: "\n", omittingEmptySubsequences: false)
		guard lines.first.map(Self.isDelimiter) == true else {
			return nil
		}
		guard let closingIndex = lines.dropFirst().firstIndex(where: Self.isDelimiter) else {
			throw .unterminated
		}

		let yaml = lines[1 ..< closingIndex].joined(separator: "\n")
		let body = lines[(closingIndex + 1)...].joined(separator: "\n")

		let node: Yams.Node?
		do {
			node = try Yams.compose(yaml: yaml, resolver)
		} catch {
			throw .invalidYAML(String(describing: error))
		}

		let properties: Yams.Node.Mapping
		switch node {
			case nil:
				properties = Yams.Node.Mapping([])
			case let .mapping(mapping)?:
				properties = mapping
			default:
				throw .invalidYAML("The frontmatter isn't a list of properties.")
		}

		return Frontmatter(properties: properties, body: body, bodyStartLine: closingIndex + 2)
	}

	/// The value of `key` as text, or `nil` when it's missing, empty, or `null`.
	func string(_ key: String) -> String? {
		guard let scalar = properties[key]?.scalar, !Self.isNull(scalar) else {
			return nil
		}
		return scalar.string
	}

	/// The value of `key` as a boolean, or `nil` when it's missing or isn't one. `resolver` decides
	/// which spellings are booleans, and a quoted value is always text.
	///
	/// The `bool` property in Yams reads the YAML 1.1 spellings whatever the resolver says, so the
	/// resolved tag is checked first.
	func bool(_ key: String) -> Bool? {
		guard let node = properties[key], node.tag == Yams.Tag(.bool) else {
			return nil
		}
		return node.bool
	}

	/// Whether `key` has a value that isn't a single piece of text, like a list.
	func isNonScalar(_ key: String) -> Bool {
		guard let node = properties[key] else {
			return false
		}
		return node.scalar == nil
	}

	/// The value of `key` as a list of text. A single value counts as a list of one. Returns `nil` when
	/// the value is a list that holds something other than text.
	func strings(_ key: String) -> [String]? {
		switch properties[key] {
			case nil:
				return []
			case let .scalar(scalar)?:
				return Self.isNull(scalar) ? [] : [scalar.string]
			case let .sequence(sequence)?:
				var values: [String] = []
				for node in sequence {
					guard let scalar = node.scalar else {
						return nil
					}
					values.append(scalar.string)
				}
				return values
			default:
				return nil
		}
	}

	private static func isDelimiter(_ line: Substring) -> Bool {
		line.trimmingTrailingWhitespace() == "---"
	}

	/// Whether the value is null as Yams reads it, which is an empty value, `~`, or `null` written
	/// without quotes. Obsidian writes an empty property as `key:` with nothing after it.
	private static func isNull(_ scalar: Yams.Node.Scalar) -> Bool {
		NSNull.construct(from: scalar) != nil
	}
}

// MARK: - Substring + Whitespace

extension Substring {
	func trimmingTrailingWhitespace() -> Substring {
		var result = self
		while let last = result.last, last.isWhitespace {
			result.removeLast()
		}
		return result
	}
}
