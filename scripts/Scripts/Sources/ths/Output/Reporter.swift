import Darwin
import Escape
import Foundation

/// Formats what `status` and `sync` print.
///
/// Output is colored only when stdout is a terminal and `NO_COLOR` isn't set, so piped output stays
/// plain text.
struct Reporter: Sendable {
	/// The website repo, which the fix for an edited bundle names.
	let siteDirectory: URL
	/// Whether output is colored.
	var usesColor = isatty(STDOUT_FILENO) != 0 && ProcessInfo.processInfo.environment["NO_COLOR"] == nil

	/// `text` in `color`, or as it is when output isn't colored.
	func paint(_ text: String, _ color: Color) -> String {
		usesColor ? text.colorized(foreground: color) : text
	}

	/// A line in the list of posts, with a colored word, the slug, and a detail like where the post is.
	func line(_ word: String, color: Color, wordWidth: Int, slug: String?, detail: String, slugWidth: Int) -> String {
		let paddedWord = word.padding(toLength: wordWidth, withPad: " ", startingAt: 0)
		let slug = (slug ?? "(no slug)").padding(toLength: slugWidth, withPad: " ", startingAt: 0)
		return "\(paint(paddedWord, color))  \(slug)  \(detail)".trimmingTrailingWhitespace()
	}

	/// Where an entry is. That's its note, or its bundle when it has no note.
	func location(of entry: CatalogEntry) -> String {
		entry.post?.relativePath ?? entry.bundlePath ?? ""
	}

	/// The width of the longest slug in `entries`, so the list lines up.
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
		switch entry {
			case .vaultOnly, .new, .upToDate, .stale, .orphanedDraft:
				break
			case let .canceled(_, bundle):
				if !bundle.isDraft {
					messages.append(Message(
						kind: .warning,
						headline: "\(bundlePath) is published, so deleting it takes /blog/\(slug)/ off the site",
						details: [
							"Add a redirect from /blog/\(slug)/ before deploying, so links to the post still lead somewhere."
						],
					))
				}
			case let .invalid(_, issues, _):
				messages += issues.map { issueMessage($0, kind: .error, notePath: notePath) }
			case .edited:
				messages.append(Message(
					kind: .error,
					headline: "\(bundlePath) was changed outside `ths` since the last sync",
					details: [
						"Move the changes into \(notePath), or delete the bundle so the next sync regenerates it.",
						"To discard uncommitted changes instead, run `git -C \(displayPath(siteDirectory)) restore \(bundlePath)`.",
					],
				))
			case .conflict:
				messages.append(Message(
					kind: .error,
					headline: "\(bundlePath) already exists and isn't managed by `ths`",
					details: [
						"If it's an older copy of \(notePath), delete it and sync again. Otherwise change the slug of the post."
					],
				))
			case .orphanedPublished:
				messages.append(Message(
					kind: .error,
					headline: "\(bundlePath) is published, but no post in the vault has the slug \(slug)",
					details: [
						"Restore the slug, status, or note of the post.",
						"If the post should come down, restore it and set its status to canceled.",
					],
				))
			case .retracted:
				messages.append(Message(
					kind: .error,
					headline: "\(notePath) is a draft, but \(bundlePath) is published",
					details: [
						"Set its status back to published.",
						"To take the post down, set its status to canceled instead.",
					],
				))
		}
		return messages
	}

	/// The message as it's printed, with its label and its details indented under it.
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

// MARK: - Static Members

extension Reporter {
	/// The length of the longest state label, so the list lines up.
	static let labelWidth = PostState.allCases.map(\.label.count).max() ?? 0
}

// MARK: - Private Helpers

extension Reporter {
	private func issueMessage(_ issue: PostIssue, kind: Message.Kind, notePath: String) -> Message {
		let location = issue.line.map { "\(notePath):\($0)" } ?? notePath
		return Message(kind: kind, headline: "\(location): \(issue.message)", details: [issue.fix])
	}
}
