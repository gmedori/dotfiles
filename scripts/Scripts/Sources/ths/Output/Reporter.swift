import Darwin
import Escape
import Foundation

// MARK: - Message

/// An error or warning printed after the list of posts: a line saying what's wrong, then lines saying
/// how to fix it.
struct Message: Equatable, Sendable {
	enum Kind: Sendable {
		case error
		case warning
	}

	let kind: Kind
	let headline: String
	let details: [String]
}

// MARK: - Reporter

/// Formats what `status` and `sync` print.
///
/// Output is colored only when stdout is a terminal and `NO_COLOR` isn't set, so piped output stays
/// plain text.
struct Reporter: Sendable {
	static let labelWidth = PostState.allCases.map(\.label.count).max()!

	let siteDirectory: URL
	var useColor = isatty(STDOUT_FILENO) != 0 && ProcessInfo.processInfo.environment["NO_COLOR"] == nil

	func paint(_ text: String, _ color: Color) -> String {
		useColor ? text.colorized(foreground: color) : text
	}

	/// A line in the list of posts: a colored word, the slug, and where the post or bundle is.
	func line(_ word: String, color: Color, slug: String?, detail: String, slugWidth: Int) -> String {
		let paddedWord = word.padding(toLength: Self.labelWidth, withPad: " ", startingAt: 0)
		let slug = (slug ?? "(no slug)").padding(toLength: slugWidth, withPad: " ", startingAt: 0)
		return "\(paint(paddedWord, color))  \(slug)  \(detail)".trimmingTrailingWhitespace()
	}

	/// Where an entry is: its note, or its bundle when it has no note.
	func location(of entry: CatalogEntry) -> String {
		entry.post?.relativePath ?? entry.bundlePath ?? ""
	}

	func slugWidth(for entries: [CatalogEntry]) -> Int {
		entries.map { ($0.slug ?? "(no slug)").count }.max() ?? 0
	}

	// MARK: Messages

	/// The errors and warnings for an entry. Problem states get an error saying what's wrong and how
	/// to fix it. An invalid post gets one error per blocking issue. A draft gets one warning per issue
	/// that would block it once published.
	func messages(for entry: CatalogEntry) -> [Message] {
		let notePath = entry.post?.relativePath ?? ""
		let bundlePath = entry.bundlePath ?? ""
		let slug = entry.slug ?? ""

		var messages = entry.warnings.map { issueMessage($0, kind: .warning, notePath: notePath) }
		switch entry.state {
			case .vaultOnly, .new, .upToDate, .stale, .orphanedDraft:
				break
			case .invalid:
				messages += entry.issues.map { issueMessage($0, kind: .error, notePath: notePath) }
			case .edited:
				messages.append(Message(
					kind: .error,
					headline: "\(bundlePath) was changed outside ths since the last sync",
					details: [
						"Move the changes into \(notePath), or delete the bundle so the next sync regenerates it.",
						"To discard uncommitted changes instead: git -C \(displayPath(siteDirectory)) restore \(bundlePath)",
					],
				))
			case .conflict:
				messages.append(Message(
					kind: .error,
					headline: "\(bundlePath) already exists and isn't managed by ths",
					details: [
						"If it's an older copy of \(notePath), delete it and sync again. Otherwise change the post's slug.",
					],
				))
			case .orphanedPublished:
				messages.append(Message(
					kind: .error,
					headline: "\(bundlePath) is published, but no post in the vault has the slug \(slug)",
					details: [
						"Restore the post's slug, status, or note.",
						"If the URL should go, add a redirect from /blog/\(slug)/ and delete the bundle by hand.",
					],
				))
			case .retracted:
				messages.append(Message(
					kind: .error,
					headline: "\(notePath) is a draft, but \(bundlePath) is published",
					details: [
						"Set its status back to published.",
						"To take the post down, add a redirect from /blog/\(slug)/ and delete the bundle by hand. The next sync recreates it as a draft.",
					],
				))
		}
		return messages
	}

	private func issueMessage(_ issue: PostIssue, kind: Message.Kind, notePath: String) -> Message {
		let location = issue.line.map { "\(notePath):\($0)" } ?? notePath
		return Message(kind: kind, headline: "\(location): \(issue.message)", details: [issue.fix])
	}

	func format(_ message: Message) -> String {
		let label = switch message.kind {
			case .error: paint("error:", .red)
			case .warning: paint("warning:", .yellow)
		}
		return (["\(label) \(message.headline)"] + message.details.map { "  \($0)" }).joined(separator: "\n")
	}

	/// The path with the home folder shortened to `~`.
	func displayPath(_ url: URL) -> String {
		let path = url.standardizedFileURL.path(percentEncoded: false).trimmingSuffix("/")
		let home = FileManager.default.homeDirectoryForCurrentUser.path(percentEncoded: false).trimmingSuffix("/")
		return path.hasPrefix(home) ? "~" + path.dropFirst(home.count) : path
	}
}

// MARK: - String + Suffix

extension String {
	func trimmingSuffix(_ suffix: String) -> String {
		hasSuffix(suffix) ? String(dropLast(suffix.count)) : self
	}

	func trimmingTrailingWhitespace() -> String {
		String(Substring(self).trimmingTrailingWhitespace())
	}
}
