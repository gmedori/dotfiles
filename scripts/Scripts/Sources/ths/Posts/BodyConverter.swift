import Foundation

// MARK: - Converted Body

/// A post's body, ready for its bundle's `index.md`, with the images it uses.
struct ConvertedBody: Equatable, Sendable {
	/// The text of the leading H1, or `nil` when the body doesn't open with one.
	let title: String?
	/// The Markdown for the bundle, without the title and ending in one newline.
	let markdown: String
	/// Every image the post uses, in the order they first appear.
	let images: [BundleImage]
	/// Everything in the body the site can't show, each with its line in the note.
	let issues: [PostIssue]
}

/// An image copied from the vault into a post's bundle.
struct BundleImage: Equatable, Sendable {
	/// The image file in the vault.
	let source: URL
	/// The file name in the bundle, which the Markdown refers to.
	let name: String
}

// MARK: - Body Converter

/// Converts an Obsidian note's body into the Markdown a Hugo page bundle uses.
///
/// The conversion works on lines and rewrites only the constructs below, so the author's text
/// passes through byte for byte. Re-rendering the Markdown from a parsed tree would reformat it.
///
/// - The leading H1 is removed, since it becomes the `title` and the site's template renders the
///   title as the page's H1.
/// - `![[photo.png]]` and `![[photo.png|Alt text]]` become `![Alt text](photo.png)`, and
///   `![Alt text](assets/photo.png)` points at the bundle's copy instead. Bundle copies are renamed
///   to lowercase with hyphens for spaces, since a Markdown link can't hold a bare space.
/// - `<a href="URL"><img src="assets/badge.png" alt="Alt text"></a>`, alone on its line, becomes
///   `[![Alt text](badge.png)](URL)`. Markdown has no clickable embed, so the vault uses HTML for it,
///   but the site drops raw HTML. As Markdown, the image also goes through the image render hook.
/// - An italic line under a standalone image, with at most one blank line between, becomes the
///   image's Markdown title. The render hook turns that title into the image's caption.
/// - `%% comments %%` are removed. A line that held only a comment is removed with it.
///
/// Fenced code blocks and inline code pass through untouched and aren't checked. Everything else is
/// checked for what the site can't show, like wiki links and raw HTML, and reported as issues.
struct BodyConverter {
	static let imageExtensions: Set = ["png", "jpg", "jpeg", "gif", "webp", "avif", "svg"]

	/// The folder the note is in. Images are looked up here and in its `assets/` folder, which is
	/// where Obsidian saves attachments in this vault.
	let noteDirectory: URL
	/// Whether a file exists. Tests swap it out.
	var fileExists: (URL) -> Bool = { FileManager.default.fileExists(atPath: $0.path(percentEncoded: false)) }

	func convert(_ body: String, startLine: Int) -> ConvertedBody {
		var state = ConversionState()
		var lines = Self.removingComments(from: body, startLine: startLine)

		state.title = Self.removeTitle(from: &lines)
		if state.title == nil {
			state.issues.append(.missingTitle)
		}

		for index in lines.indices where !lines[index].isCode {
			lines[index].text = convertLine(lines[index].text, line: lines[index].number, state: &state)
		}
		Self.foldCaptions(into: &lines)

		var markdown = lines.map(\.text).joined(separator: "\n")
		while markdown.last?.isWhitespace == true {
			markdown.removeLast()
		}
		markdown += "\n"

		return ConvertedBody(title: state.title, markdown: markdown, images: state.images, issues: state.issues)
	}

	// MARK: Lines

	/// A line of the body, with its line number in the note.
	struct Line: Equatable {
		/// The text of the line, without its newline.
		var text: String
		/// The line's number in the note, counting from 1.
		let number: Int
		/// Whether the line is part of a fenced code block, fences included.
		let isCode: Bool
	}

	/// Splits the body into lines, marks fenced code, and removes `%% comments %%`, which can span
	/// lines.
	static func removingComments(from body: String, startLine: Int) -> [Line] {
		var lines: [Line] = []
		var fence: Substring?
		var inComment = false

		for (offset, rawLine) in body.split(separator: "\n", omittingEmptySubsequences: false).enumerated() {
			let number = startLine + offset
			let raw = String(rawLine)

			if let openFence = fence {
				lines.append(Line(text: raw, number: number, isCode: true))
				if raw.trimmingCharacters(in: .whitespaces).hasPrefix(openFence) {
					fence = nil
				}
				continue
			}
			if !inComment, let match = raw.wholeMatch(of: /\s{0,3}(`{3,}|~{3,}).*/) {
				fence = match.1
				lines.append(Line(text: raw, number: number, isCode: true))
				continue
			}

			var text = ""
			var hadComment = inComment
			var rest = Substring(raw)
			while true {
				guard let marker = rest.range(of: "%%") else {
					if !inComment {
						text += rest
					}
					break
				}
				hadComment = true
				if !inComment {
					text += rest[..<marker.lowerBound]
				}
				inComment.toggle()
				rest = rest[marker.upperBound...]
			}

			if hadComment, text.allSatisfy(\.isWhitespace) {
				continue
			}
			lines.append(Line(text: text, number: number, isCode: false))
		}
		return lines
	}

	/// Removes the leading H1 and the blank lines after it, and returns its text. Returns `nil` and
	/// leaves the lines alone when the first line with text isn't an H1.
	static func removeTitle(from lines: inout [Line]) -> String? {
		guard
			let first = lines.firstIndex(where: { !$0.text.allSatisfy(\.isWhitespace) }),
			!lines[first].isCode,
			let match = lines[first].text.wholeMatch(of: /#[ \t]+(.+?)[ \t]*#*[ \t]*/)
		else {
			return nil
		}

		var end = first + 1
		while end < lines.endIndex, lines[end].text.allSatisfy(\.isWhitespace) {
			end += 1
		}
		lines.removeSubrange(lines.startIndex ..< end)
		return String(match.1)
	}

	// MARK: Line Conversion

	/// What a conversion has found so far.
	private struct ConversionState {
		/// The text of the leading H1, once it's found.
		var title: String?
		/// The images found so far, in the order they first appear.
		var images: [BundleImage] = []
		/// The issues found so far.
		var issues: [PostIssue] = []
	}

	private func convertLine(_ text: String, line: Int, state: inout ConversionState) -> String {
		if let linked = convertLinkedImage(text, line: line, state: &state) {
			return linked
		}

		let prose = Self.blankingInlineCode(in: text)
		check(prose, line: line, state: &state)

		// Markdown images go first. Their pattern never matches an embed, while an embed's output is a
		// Markdown image that mustn't be converted twice.
		return Self.replacingOutsideInlineCode(in: text) { segment in
			var segment = segment
			segment = segment.replacing(
				/!\[([^\]]*)\]\(\s*(?:<([^>]+)>|([^\s)]+))(?:\s+"((?:[^"\\]|\\.)*)")?\s*\)/
			) { match in
				let destination = String(match.2 ?? match.3 ?? "")
				return convertImage(
					alt: String(match.1),
					destination: destination,
					title: match.4.map(String.init),
					line: line,
					state: &state,
				)
			}
			segment = segment.replacing(/!\[\[([^\]|]+)(?:\|([^\]]*))?\]\]/) { match in
				convertEmbed(target: String(match.1), alias: match.2.map(String.init), line: line, state: &state)
			}
			return segment
		}
	}

	/// Checks a line, with its inline code blanked out, for what the site can't show.
	private func check(_ prose: String, line: Int, state: inout ConversionState) {
		if prose.wholeMatch(of: /#[ \t]+.*/) != nil {
			state.issues.append(.extraTitle(line: line))
		}
		for match in prose.matches(of: /(?:^|[^!])\[\[([^\]]+)\]\]/) {
			state.issues.append(.wikiLink(String(match.1), line: line))
		}
		if prose.wholeMatch(of: /\s*(?:>\s*)+\[![^\]]+\].*/) != nil {
			state.issues.append(.callout(line: line))
		}
		if prose.contains(/==[^=\s](?:[^=]*[^=\s])?==/) {
			state.issues.append(.highlight(line: line))
		}
		for match in prose.matches(of: /<\/?([A-Za-z][A-Za-z0-9-]*)(?:\s[^>]*)?\/?>/) {
			state.issues.append(.html(tag: String(match.1).lowercased(), line: line))
		}
		if prose.contains(/\bTODO\b/) {
			state.issues.append(.todo(line: line))
		}
	}

	private func convertEmbed(target: String, alias: String?, line: Int, state: inout ConversionState) -> String {
		let target = target.trimmingCharacters(in: .whitespaces)
		guard Self.imageExtensions.contains((target as NSString).pathExtension.lowercased()) else {
			state.issues.append(.wikiLink(target, line: line))
			return "![[\(target)]]"
		}

		// After the pipe, Obsidian reads a number or WIDTHxHEIGHT as a display size, not alt text.
		var alt = alias?.trimmingCharacters(in: .whitespaces) ?? ""
		if alt.wholeMatch(of: /\d+(x\d+)?/) != nil {
			alt = ""
		}
		guard let name = addImage(target, line: line, state: &state) else {
			return "![[\(target)]]"
		}
		if alt.isEmpty {
			state.issues.append(.missingAltText(name: target, line: line))
		}
		return "![\(alt)](\(name))"
	}

	private func convertImage(
		alt: String,
		destination: String,
		title: String?,
		line: Int,
		state: inout ConversionState,
	) -> String {
		let original = "![\(alt)](\(destination)\(title.map { " \"\($0)\"" } ?? ""))"
		if destination.contains("://") {
			state.issues.append(.remoteImage(url: destination, line: line))
			return original
		}

		let path = destination.removingPercentEncoding ?? destination
		guard let name = addImage(path, line: line, state: &state) else {
			return original
		}
		if alt.trimmingCharacters(in: .whitespaces).isEmpty {
			state.issues.append(.missingAltText(name: path, line: line))
		}
		return "![\(alt)](\(name)\(title.map { " \"\($0)\"" } ?? ""))"
	}

	/// Converts `<a href="URL"><img src="…" alt="…"></a>` when it's the whole line. Returns `nil` for
	/// any other line.
	private func convertLinkedImage(_ text: String, line: Int, state: inout ConversionState) -> String? {
		guard let match = text.wholeMatch(of: /\s*<a\s+href="([^"]*)"\s*>\s*<img\s+([^>]*?)\s*\/?>\s*<\/a>\s*/) else {
			return nil
		}

		var attributes: [String: String] = [:]
		for attribute in match.2.matches(of: /([A-Za-z-]+)\s*=\s*"([^"]*)"/) {
			attributes[String(attribute.1).lowercased()] = String(attribute.2)
		}
		guard let source = attributes["src"] else {
			return nil
		}

		let image = convertImage(alt: attributes["alt"] ?? "", destination: source, title: nil, line: line, state: &state)
		return "[\(image)](\(match.1))"
	}

	/// Finds an image in the vault, records it, and returns its name in the bundle. Returns `nil` and
	/// records an issue when it can't be found or its name is taken.
	private func addImage(_ path: String, line: Int, state: inout ConversionState) -> String? {
		let fileName = (path as NSString).lastPathComponent
		let candidates = [
			noteDirectory.appending(path: path),
			noteDirectory.appending(path: "assets").appending(path: fileName),
		]
		guard let source = candidates.first(where: fileExists)?.standardizedFileURL else {
			state.issues.append(.missingImage(name: path, line: line))
			return nil
		}

		let name = Self.bundleName(for: fileName)
		if let existing = state.images.first(where: { $0.name == name }) {
			if existing.source != source {
				state.issues.append(.duplicateImageName(name: name, line: line))
				return nil
			}
			return name
		}
		state.images.append(BundleImage(source: source, name: name))
		return name
	}

	/// The image's file name in the bundle. It's lowercase, with runs of spaces and underscores turned
	/// into hyphens, so `Pre-order Badge.png` becomes `pre-order-badge.png`.
	static func bundleName(for fileName: String) -> String {
		fileName.lowercased().replacing(/[\s_]+/, with: "-")
	}

	// MARK: Captions

	/// Moves an italic line under a standalone image into the image's title, which the render hook
	/// shows as the caption. Images that already have a title keep it.
	static func foldCaptions(into lines: inout [Line]) {
		var index = lines.startIndex
		while index < lines.endIndex {
			defer { index += 1 }
			guard
				!lines[index].isCode,
				let image = lines[index].text.wholeMatch(of: /\s*(!\[[^\]]*\]\([^\s)"]+)\)\s*/)
			else {
				continue
			}

			var captionIndex = index + 1
			if captionIndex < lines.endIndex, lines[captionIndex].text.allSatisfy(\.isWhitespace) {
				captionIndex += 1
			}
			guard
				captionIndex < lines.endIndex,
				!lines[captionIndex].isCode,
				let caption = lines[captionIndex].text.wholeMatch(of: /\s*(?:_([^_].*?)_|\*([^*].*?)\*)\s*/)
			else {
				continue
			}

			let text = String(caption.1 ?? caption.2 ?? "")
				.replacing("\\", with: "\\\\")
				.replacing("\"", with: "\\\"")
			lines[index].text = "\(image.1) \"\(text)\")"
			lines.removeSubrange((index + 1) ... captionIndex)
		}
	}

	// MARK: Inline Code

	/// The line with the contents of every inline code span replaced by spaces, so checks don't
	/// match code.
	static func blankingInlineCode(in text: String) -> String {
		text.replacing(/`[^`]*`/) { match in
			String(repeating: " ", count: match.output.count)
		}
	}

	/// Applies `transform` to the parts of the line outside inline code spans.
	static func replacingOutsideInlineCode(in text: String, _ transform: (String) -> String) -> String {
		var result = ""
		var rest = Substring(text)
		while let code = rest.firstMatch(of: /`[^`]*`/) {
			result += transform(String(rest[..<code.range.lowerBound]))
			result += code.output
			rest = rest[code.range.upperBound...]
		}
		return result + transform(String(rest))
	}
}
