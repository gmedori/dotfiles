import Foundation

// MARK: - Attachment

/// An image or video that a draft's body embeds, staged for `gh pr create --attach`.
struct Attachment: Codable, Equatable, Sendable {
	enum Kind: String, Codable, Sendable {
		case image
		case video
	}

	/// Where an image's alt text came from.
	enum AltSource: String, Codable, Sendable {
		/// The `--alt` option of `prepare`.
		case option = "--alt"
		/// The embed, after the `|` in `![[shot.png|Alt text]]` or in the brackets of a Markdown image.
		case embed
		/// The bold label line directly above the embed.
		case label
	}

	/// The attachment's number, counting from 1 in the order the files first appear in the body.
	let number: Int
	let kind: Kind
	/// The file's path from the vault root.
	let source: String
	/// The staged copy's path from the staging folder, like `./01-share-sheet.png`. The body refers
	/// to the file by this path, and `gh` replaces it with the upload's URL.
	let staged: String
	/// The image's alt text. Videos have none.
	var alt: String?
	/// Where `alt` came from.
	var altFrom: AltSource?

	/// The value for `gh --attach`, which is the staged path with the alt text after a `#`.
	var attachArgument: String {
		alt.map { "\(staged)#\($0)" } ?? staged
	}
}

// MARK: - Body Rewriter

/// Rewrites the images and videos a draft's body embeds as Markdown images that point at staged
/// copies.
///
/// An embed is an Obsidian embed, like `![[shot.png]]` or `![[shot.png|Alt text]]`, or a Markdown
/// image, like `![Alt text](assets/shot%201.png)`. Each becomes `![Alt text](./01-shot.png)`, the
/// form that `gh pr create --attach ./01-shot.png` rewrites to the uploaded file. Embeds in fenced
/// code, inline code, and HTML comments, and images that point at a URL, stay as written.
///
/// An image's alt text comes from the `--alt` option, then the embed, then a bold label line directly
/// above it, like `**Share sheet, dark mode**`, which is how the pr-description skill labels
/// attachments. An image embedded more than once reuses the alt text it was first given when none
/// of those apply.
///
/// GitHub shows a video as a player only when its link is a paragraph of its own. Under a label
/// line, it's a plain link. So when a video's embed is alone on its line, the rewriter puts blank
/// lines around it. Images show either way.
struct BodyRewriter {
	static let imageExtensions: Set = ["png", "jpg", "jpeg", "gif", "svg"]
	static let videoExtensions: Set = ["mp4", "mov", "webm"]

	/// The folder the draft is in.
	let noteDirectory: URL
	let vault: VaultFiles
	/// Alt text from the `--alt` option, by attachment number.
	var altOverrides: [Int: String] = [:]

	struct Result {
		/// The body without leading or trailing blank lines, ending in one newline.
		let body: String
		/// Every file the body embeds, in the order they first appear.
		let attachments: [Attachment]
		/// The vault file behind each attachment, in the same order.
		let sources: [URL]
		/// A sentence for each embed that can't be staged. Those embeds stay in the body as written.
		let errors: [String]
		/// The label of each `<!-- TODO: … -->` placeholder, from the bold line above it or else from
		/// the comment.
		let placeholders: [String]
	}

	private struct State {
		var attachments: [Attachment] = []
		var sources: [URL] = []
		var errors: [String] = []
		var placeholders: [String] = []
	}

	/// Rewrites `lines`, the first of which is line `startLine` of the draft. Error messages use
	/// line numbers in the draft.
	func rewrite(_ lines: [String], startLine: Int) -> Result {
		var state = State()
		var output: [String] = []
		var fence: Substring?
		var needsBlankLine = false

		for (offset, line) in lines.enumerated() {
			if needsBlankLine, !Self.isBlank(line) {
				output.append("")
			}
			needsBlankLine = false

			if let open = fence {
				if let close = line.wholeMatch(of: /[ ]{0,3}(`{3,}|~{3,})\s*/),
					close.1.first == open.first, close.1.count >= open.count
				{
					fence = nil
				}
				output.append(line)
				continue
			}
			if let match = line.prefixMatch(of: /[ ]{0,3}(`{3,}|~{3,})/) {
				fence = match.1
				output.append(line)
				continue
			}

			let label = Self.label(above: offset, in: lines)
			for match in line.matches(of: /<!--\s*TODO:(.*?)-->/) {
				state.placeholders.append(label ?? match.1.trimmingCharacters(in: .whitespaces))
			}
			let rewritten = rewriteLine(line, number: startLine + offset, label: label, state: &state)
			let isVideo = state.attachments.contains {
				$0.kind == .video && rewritten.trimmingCharacters(in: .whitespaces) == "![](\($0.staged))"
			}
			if isVideo, let previous = output.last, !Self.isBlank(previous) {
				output.append("")
			}
			output.append(rewritten)
			needsBlankLine = isVideo
		}

		let body = output.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines) + "\n"
		return Result(
			body: body,
			attachments: state.attachments,
			sources: state.sources,
			errors: state.errors,
			placeholders: state.placeholders,
		)
	}

	// MARK: Lines

	private func rewriteLine(_ line: String, number: Int, label: String?, state: inout State) -> String {
		// Inline code and HTML comments are matched so they're skipped whole, and an embed inside one
		// is never matched on its own.
		line.replacing(
			/(?<code>`+).*?\k<code>|<!--.*?-->|!\[\[(?<wiki>[^\]|]+)(?:\|(?<alias>[^\]]*))?\]\]|!\[(?<alt>[^\]]*)\]\((?<dest><[^>]+>|[^)\s]+)(?:\s+(?:"[^"]*"|'[^']*'))?\)/
		) { match -> String in
			let original = String(match.output.0)
			let target: String
			let embedAlt: String?
			if let wiki = match.output.wiki {
				target = String(wiki.prefix { $0 != "#" }).trimmingCharacters(in: .whitespaces)
				// After the pipe, Obsidian reads a number or WIDTHxHEIGHT as a display size, not alt text.
				let alias = match.output.alias.map { $0.trimmingCharacters(in: .whitespaces) } ?? ""
				embedAlt = alias.wholeMatch(of: /\d+(x\d+)?/) == nil ? alias : nil
			} else if var destination = match.output.dest.map(String.init) {
				if destination.hasPrefix("<") {
					destination = String(destination.dropFirst().dropLast())
				}
				if destination.prefixMatch(of: /[A-Za-z][A-Za-z0-9+.\-]*:/) != nil {
					return original
				}
				target = destination.removingPercentEncoding ?? destination
				embedAlt = match.output.alt.map(String.init)
			} else {
				return original
			}

			guard let index = attachmentIndex(for: target, original: original, line: number, state: &state) else {
				return original
			}
			if state.attachments[index].kind == .video {
				return "![](\(state.attachments[index].staged))"
			}

			let attachment = state.attachments[index]
			let choices: [(String?, Attachment.AltSource?)] = [
				(altOverrides[attachment.number], .option),
				(embedAlt.flatMap(Self.cleanAlt), .embed),
				(label.flatMap(Self.cleanAlt), .label),
				(attachment.alt, attachment.altFrom),
			]
			let choice = choices.first { $0.0 != nil }
			if attachment.alt == nil, let choice {
				state.attachments[index].alt = choice.0
				state.attachments[index].altFrom = choice.1
			}
			return "![\(choice?.0 ?? "")](\(attachment.staged))"
		}
	}

	/// Finds the file an embed points at and returns its index in `state.attachments`, adding it the
	/// first time it's embedded. Returns `nil` and records an error when it can't be staged.
	private func attachmentIndex(for target: String, original: String, line: Int, state: inout State) -> Int? {
		let fileExtension = (target as NSString).pathExtension.lowercased()
		let isVideo = Self.videoExtensions.contains(fileExtension)
		guard isVideo || Self.imageExtensions.contains(fileExtension) else {
			state.errors.append(
				"Line \(line) embeds `\(original)`, which isn't an image or video GitHub accepts. "
					+ "GitHub accepts .png, .jpg, .jpeg, .gif, and .svg images and .mp4, .mov, and .webm videos."
			)
			return nil
		}

		let source: URL
		switch vault.resolve(target, from: noteDirectory) {
			case let .found(url):
				source = url
			case .missing:
				state.errors.append("Line \(line) embeds `\(original)`, but no file in the vault matches it.")
				return nil
			case let .ambiguous(urls):
				let paths = urls.map { "`\(vault.relativePath(of: $0))`" }.joined(separator: ", ")
				state.errors.append(
					"Line \(line) embeds `\(original)`, but more than one file matches it (\(paths)). "
						+ "Link it by its path from the vault root."
				)
				return nil
		}

		if let index = state.sources.firstIndex(of: source) {
			return index
		}
		let number = state.attachments.count + 1
		let prefix = number < 10 ? "0\(number)" : "\(number)"
		let stem = Self.slug(source.deletingPathExtension().lastPathComponent)
		state.attachments.append(Attachment(
			number: number,
			kind: isVideo ? .video : .image,
			source: vault.relativePath(of: source),
			staged: "./\(prefix)-\(stem).\(fileExtension)",
		))
		state.sources.append(source)
		return state.attachments.count - 1
	}

	// MARK: Text

	private static func isBlank(_ line: String) -> Bool {
		line.allSatisfy(\.isWhitespace)
	}

	/// The text of the bold line above `index`, skipping blank lines, or `nil` when the first line
	/// with text above it isn't entirely bold.
	static func label(above index: Int, in lines: [String]) -> String? {
		guard let line = lines[..<index].last(where: { !$0.allSatisfy(\.isWhitespace) }) else {
			return nil
		}
		let trimmed = line.trimmingCharacters(in: .whitespaces)
		return trimmed.wholeMatch(of: /(\*\*|__)(.+?)\1/).map { String($0.2).trimmingCharacters(in: .whitespaces) }
	}

	/// The text with its brackets removed, which would end a Markdown image's alt text early, and its
	/// whitespace collapsed. Returns `nil` when nothing is left.
	static func cleanAlt(_ text: String) -> String? {
		let cleaned = text
			.replacing(/[\[\]]/, with: "")
			.replacing(/\s+/, with: " ")
			.trimmingCharacters(in: .whitespaces)
		return cleaned.isEmpty ? nil : cleaned
	}

	/// The name in lowercase, with every run of other characters than letters and digits turned into
	/// a hyphen, so `Pasted image 20261118.png` gives `pasted-image-20261118`. It's cut to `limit`
	/// characters, and it's `file` when nothing is left.
	static func slug(_ name: String, limit: Int = 40) -> String {
		let hyphens: Set<Character> = ["-"]
		let slug = name.lowercased().replacing(/[^a-z0-9]+/, with: "-")
		let trimmed = String(slug.drop { hyphens.contains($0) }.prefix(limit))
		let result = String(trimmed.reversed().drop { hyphens.contains($0) }.reversed())
		return result.isEmpty ? "file" : result
	}
}
