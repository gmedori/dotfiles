import CommandKit
import Foundation

// MARK: - Blog Post

/// A vault note with `type: blog post` in its frontmatter.
///
/// Notes are found by their `type`, not by their folder, so posts can live anywhere under the source
/// directory. A post with no `status` stays in the vault. A post with a status of `draft` or
/// `published` belongs on the site, and a `canceled` post has been taken down.
///
/// Properties that can't be read are left `nil` and recorded in `issues`. Parsing never throws, so
/// one broken note never hides the others.
struct BlogPost: Equatable, Sendable {
	static let type = "blog post"

	enum Status: String, Equatable, Sendable {
		/// On the site only under `hugo server -D`. Production builds leave it out.
		case draft
		/// Public on the site.
		case published
		/// Taken down. Its bundle is deleted from the site repo, and the note stays in the vault.
		case canceled
	}

	/// The note's path relative to the source directory, like `Blog Posts/My Post.md`.
	let relativePath: String
	let status: Status?
	let slug: String?
	/// The publication date, written as YYYY-MM-DD.
	let date: String?
	let description: String?
	let tags: [String]
	/// The note's Markdown after the frontmatter.
	let body: String
	/// The 1-based line number in the note where `body` starts, so issues in the body can point at the
	/// line in the note.
	let bodyStartLine: Int
	let issues: [PostIssue]

	/// Parses a note. Returns `nil` when the note isn't a blog post, because it has no frontmatter or
	/// its `type` isn't `blog post`. A note whose frontmatter can't be read isn't a blog post either,
	/// since its type can't be known, unless the type line itself says it's one.
	static func parse(_ text: String, relativePath: String) -> BlogPost? {
		let frontmatter: Frontmatter?
		do {
			frontmatter = try Frontmatter.parse(text)
		} catch {
			guard declaresBlogPostType(text) else {
				return nil
			}
			return BlogPost(brokenAt: relativePath, reason: error)
		}

		guard let frontmatter, frontmatter.string("type") == type else {
			return nil
		}

		var issues: [PostIssue] = []

		let status: Status?
		if let value = frontmatter.string("status") {
			status = Status(rawValue: value)
			if status == nil {
				issues.append(.invalidStatus(value))
			}
		} else if frontmatter.isNonScalar("status") {
			status = nil
			issues.append(.invalidProperty(name: "status", expected: "draft, published, or canceled"))
		} else {
			status = nil
		}

		let slug = frontmatter.string("slug")
		if let slug, !isValidSlug(slug) {
			issues.append(.invalidSlug(slug))
		} else if frontmatter.isNonScalar("slug") {
			issues.append(.invalidProperty(name: "slug", expected: "a single slug"))
		}

		let date = frontmatter.string("date")
		if let date, !isValidDate(date) {
			issues.append(.invalidDate(date))
		} else if frontmatter.isNonScalar("date") {
			issues.append(.invalidProperty(name: "date", expected: "a single date"))
		}

		let description = frontmatter.string("description")
		if frontmatter.isNonScalar("description") {
			issues.append(.invalidProperty(name: "description", expected: "a single piece of text"))
		}

		let tags = frontmatter.strings("tags")
		if tags == nil {
			issues.append(.invalidProperty(name: "tags", expected: "a list of tags"))
		}

		// A post that stays in the vault isn't checked for what the site needs. A canceled post without
		// a slug was never on the site, so it has nothing to take down.
		if status == .draft || status == .published {
			if slug == nil, !frontmatter.isNonScalar("slug") {
				issues.append(.missingSlug)
			}
			if status == .published, date == nil, !frontmatter.isNonScalar("date") {
				issues.append(.missingDate)
			}
		}

		return BlogPost(
			relativePath: relativePath,
			status: status,
			slug: slug,
			date: date,
			description: description,
			tags: tags ?? [],
			body: frontmatter.body,
			bodyStartLine: frontmatter.bodyStartLine,
			issues: issues,
		)
	}

	/// Finds every blog post under `directory`, sorted by path. Hidden folders, like `.obsidian` and
	/// `.trash`, are skipped.
	static func discover(in directory: URL) throws -> [BlogPost] {
		let base = directory.standardizedFileURL.path(percentEncoded: false)
		guard let enumerator = FileManager.default.enumerator(
			at: directory,
			includingPropertiesForKeys: [.isRegularFileKey],
			options: [.skipsHiddenFiles],
		) else {
			throw RuntimeError("Couldn't read \(base).")
		}

		var posts: [BlogPost] = []
		for case let url as URL in enumerator where url.pathExtension == "md" {
			let path = url.standardizedFileURL.path(percentEncoded: false)
			let relativePath = String(path.dropFirst(base.count)).trimmingPrefix("/")
			let text = try String(contentsOf: url, encoding: .utf8)
			if let post = parse(text, relativePath: String(relativePath)) {
				posts.append(post)
			}
		}
		return posts.sorted { $0.relativePath < $1.relativePath }
	}

	static func isValidSlug(_ slug: String) -> Bool {
		slug.wholeMatch(of: /[a-z0-9]+(-[a-z0-9]+)*/) != nil
	}

	static func isValidDate(_ date: String) -> Bool {
		guard let match = date.wholeMatch(of: /(\d{4})-(\d{2})-(\d{2})/) else {
			return false
		}
		var components = DateComponents()
		components.year = Int(match.1)
		components.month = Int(match.2)
		components.day = Int(match.3)
		return Calendar(identifier: .gregorian).date(from: components).map {
			Calendar(identifier: .gregorian).dateComponents([.year, .month, .day], from: $0) == components
		} ?? false
	}

	/// Whether a note whose frontmatter can't be parsed still has a `type: blog post` line, so a typo
	/// elsewhere in the frontmatter is reported instead of the post silently disappearing.
	private static func declaresBlogPostType(_ text: String) -> Bool {
		text.split(separator: "\n").contains { line in
			line.trimmingTrailingWhitespace().wholeMatch(of: /type:\s*["']?blog post["']?/) != nil
		}
	}

	private init(brokenAt relativePath: String, reason: Frontmatter.ParseError) {
		let message = switch reason {
			case .unterminated: "the block that opens with --- never closes."
			case let .invalidYAML(details): details
		}
		self.relativePath = relativePath
		self.status = nil
		self.slug = nil
		self.date = nil
		self.description = nil
		self.tags = []
		self.body = ""
		self.bodyStartLine = 1
		self.issues = [.invalidFrontmatter(message)]
	}

	private init(
		relativePath: String,
		status: Status?,
		slug: String?,
		date: String?,
		description: String?,
		tags: [String],
		body: String,
		bodyStartLine: Int,
		issues: [PostIssue],
	) {
		self.relativePath = relativePath
		self.status = status
		self.slug = slug
		self.date = date
		self.description = description
		self.tags = tags
		self.body = body
		self.bodyStartLine = bodyStartLine
		self.issues = issues
	}
}
