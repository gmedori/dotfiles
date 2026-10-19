// MARK: - Post Issue

/// Something wrong with a blog post note that keeps `ths` from converting it as it is.
///
/// Every case has a `message`, which says what's wrong, and a `fix`, which says what to change in
/// the note. Most issues block a post whatever its status. A few only matter once a post is public:
/// they block published posts and are only warnings on drafts, so a draft can still be previewed
/// with `hugo server -D`. `blocksDrafts` says which kind a case is.
enum PostIssue: Equatable, Sendable {
	/// The frontmatter can't be read, so none of the post's properties are known. This usually comes
	/// from editing the frontmatter in source mode, like a value with an unquoted `: ` in it or a
	/// missing closing `---`. Obsidian's property editor doesn't produce it.
	case invalidFrontmatter(String)

	/// `status` has a value other than `draft` or `published`. Usually a typo, or a status copied from
	/// another kind of note, like a quest's `active`.
	case invalidStatus(String)

	/// A property has the wrong kind of value, like a list where one piece of text belongs.
	case invalidProperty(name: String, expected: String)

	/// The post has a status but no `slug`. Every post on the site needs one, because the slug is its
	/// URL and the name of its bundle.
	case missingSlug

	/// The slug has characters other than lowercase letters, digits, and single hyphens between them.
	/// The slug becomes the URL, so it's kept to characters that never need escaping.
	case invalidSlug(String)

	/// The post is published but has no `date`. The date is the publication date shown on the post
	/// and used to order the blog, so a public post needs one. Drafts can leave it empty.
	case missingDate

	/// `date` isn't a calendar date written as YYYY-MM-DD. Often a date with a time attached, which
	/// Obsidian writes when the property's type is Date & time instead of Date.
	case invalidDate(String)

	/// Whether the issue keeps a draft from being synced. Issues that return `false` are warnings on
	/// drafts and only block published posts.
	var blocksDrafts: Bool {
		switch self {
			case .invalidFrontmatter, .invalidStatus, .invalidProperty, .missingSlug, .invalidSlug,
			     .missingDate, .invalidDate:
				true
		}
	}

	/// What's wrong, in a sentence that fits after the note's path.
	var message: String {
		switch self {
			case let .invalidFrontmatter(reason):
				"The frontmatter can't be read: \(reason)"
			case let .invalidStatus(value):
				"`status` is \"\(value)\", which isn't draft or published."
			case let .invalidProperty(name, expected):
				"`\(name)` should be \(expected)."
			case .missingSlug:
				"There's no `slug`."
			case let .invalidSlug(value):
				"The slug \"\(value)\" has characters a URL slug can't use."
			case .missingDate:
				"The post is published but has no `date`."
			case let .invalidDate(value):
				"`date` is \"\(value)\", which isn't a date written as YYYY-MM-DD."
		}
	}

	/// What to change in the note to clear the issue.
	var fix: String {
		switch self {
			case .invalidFrontmatter:
				"Open the note's properties in source mode and fix the YAML."
			case .invalidStatus:
				"Set `status` to draft or published, or remove it to keep the post in the vault."
			case .invalidProperty:
				"Change the property's value in the note."
			case .missingSlug:
				"Add a `slug`, like the title in lowercase with hyphens between words."
			case .invalidSlug:
				"Use only lowercase letters, digits, and hyphens, like `my-first-post`."
			case .missingDate:
				"Add the publication date as `date`, written as YYYY-MM-DD."
			case .invalidDate:
				"Write the date as YYYY-MM-DD, and set the property's type to Date."
		}
	}
}
