// MARK: - Post Issue

/// Something wrong with a blog post note that keeps `ths` from converting it as it is.
///
/// Every case has a `message`, which says what's wrong, and a `fix`, which says what to change in
/// the note. Issues found in the body carry the line number in the note. Most issues block a post
/// whatever its status. A few only matter once a post is public: they block published posts and are
/// only warnings on drafts, so a draft can still be previewed with `hugo server -D`. `blocksDrafts`
/// says which kind a case is.
enum PostIssue: Equatable, Sendable {
	// MARK: Frontmatter

	/// The frontmatter can't be read, so none of the post's properties are known. This usually comes
	/// from editing the frontmatter in source mode, like a value with an unquoted `: ` in it or a
	/// missing closing `---`. Obsidian's property editor doesn't produce it.
	case invalidFrontmatter(String)

	/// `status` has a value other than `draft`, `published`, or `canceled`. Usually a typo, like
	/// `cancelled`, or a status copied from another kind of note, like a quest's `active`.
	case invalidStatus(String)

	/// A property has the wrong kind of value, like a list where one piece of text belongs.
	case invalidProperty(name: String, expected: String)

	/// The post is a draft or published but has no `slug`. Every post on the site needs one, because
	/// the slug is its URL and the name of its bundle.
	case missingSlug

	/// The slug has characters other than lowercase letters, digits, and single hyphens between them.
	/// The slug becomes the URL, so it's kept to characters that never need escaping.
	case invalidSlug(String)

	/// Another post with a status uses the same slug. Usually a note duplicated to start a new post
	/// without changing its slug. Both posts are blocked, since either could own the bundle.
	case duplicateSlug(otherPath: String)

	/// The post is published but has no `date`. The date is the publication date shown on the post
	/// and used to order the blog, so a public post needs one. Drafts can leave it empty.
	case missingDate

	/// `date` isn't a calendar date written as YYYY-MM-DD. Often a date with a time attached, which
	/// Obsidian writes when the property's type is Date & time instead of Date.
	case invalidDate(String)

	// MARK: Body

	/// The body doesn't open with an H1. The H1 is the post's title on the site, so it has to be the
	/// first thing in the note. A post that starts with a blockquote or a section heading, or has its
	/// title only in the filename, hits this.
	case missingTitle

	/// An H1 after the title. The site's template renders the title as the page's only H1, so section
	/// headings start at H2. Drafts written with `#` sections hit this. A warning on drafts.
	case extraTitle(line: Int)

	/// An image the note refers to isn't in the note's folder or its `assets/` folder. Usually the
	/// image was renamed or moved after it was embedded, or it lives in another note's folder.
	case missingImage(name: String, line: Int)

	/// Two images in the post would get the same file name in the bundle, which lowercases names and
	/// turns spaces into hyphens. Happens with images of the same name in different folders, or names
	/// that differ only in case or spacing.
	case duplicateImageName(name: String, line: Int)

	/// An image loads from another site. The site never makes requests to third parties at runtime,
	/// so every image is self-hosted. Usually an image pasted from the web. A warning on drafts.
	case remoteImage(url: String, line: Int)

	/// An image has no alt text. The site requires alt text on every image for accessibility. Obsidian
	/// embeds have none until it's added after a `|`. A warning on drafts.
	case missingAltText(name: String, line: Int)

	/// A wiki link, like `[[Another Note]]`, or an embed of something that isn't an image. Notes
	/// aren't published with the post, so the link would have nowhere to go.
	case wikiLink(String, line: Int)

	/// An Obsidian callout, like `> [!note]`. Hugo renders it as a plain blockquote with the marker
	/// left in the text.
	case callout(line: Int)

	/// An Obsidian highlight, like `==text==`. Hugo renders the equals signs as text.
	case highlight(line: Int)

	/// HTML other than a linked image on its own line. The site's Markdown setup drops raw HTML from
	/// the page, so it would silently disappear.
	case html(tag: String, line: Int)

	/// A line with TODO in it. A draft can carry notes to self, but a published post can't. A warning
	/// on drafts.
	case todo(line: Int)

	/// Whether the issue keeps a draft from being synced. Issues that return `false` are warnings on
	/// drafts and only block published posts.
	var blocksDrafts: Bool {
		switch self {
			case .invalidFrontmatter, .invalidStatus, .invalidProperty, .missingSlug, .invalidSlug,
			     .duplicateSlug, .missingDate, .invalidDate, .missingTitle, .missingImage, .duplicateImageName,
			     .wikiLink, .callout, .highlight, .html:
				true
			case .extraTitle, .remoteImage, .missingAltText, .todo:
				false
		}
	}

	/// The line in the note the issue is on, when it's in the body.
	var line: Int? {
		switch self {
			case .invalidFrontmatter, .invalidStatus, .invalidProperty, .missingSlug, .invalidSlug,
			     .duplicateSlug, .missingDate, .invalidDate, .missingTitle:
				nil
			case let .extraTitle(line), let .missingImage(_, line), let .duplicateImageName(_, line),
			     let .remoteImage(_, line), let .missingAltText(_, line), let .wikiLink(_, line),
			     let .callout(line), let .highlight(line), let .html(_, line), let .todo(line):
				line
		}
	}

	/// What's wrong, in a sentence that fits after the note's path.
	var message: String {
		switch self {
			case let .invalidFrontmatter(reason):
				"The frontmatter can't be read: \(reason)"
			case let .invalidStatus(value):
				"`status` is \"\(value)\", which isn't draft, published, or canceled."
			case let .invalidProperty(name, expected):
				"`\(name)` should be \(expected)."
			case .missingSlug:
				"There's no `slug`."
			case let .invalidSlug(value):
				"The slug \"\(value)\" has characters a URL slug can't use."
			case let .duplicateSlug(otherPath):
				"\(otherPath) has the same slug."
			case .missingDate:
				"The post is published but has no `date`."
			case let .invalidDate(value):
				"`date` is \"\(value)\", which isn't a date written as YYYY-MM-DD."
			case .missingTitle:
				"The body doesn't start with an H1 to use as the title."
			case .extraTitle:
				"There's a second H1 after the title."
			case let .missingImage(name, _):
				"The image \(name) isn't in the note's folder or its assets folder."
			case let .duplicateImageName(name, _):
				"Another image in the post would also be saved as \(name)."
			case let .remoteImage(url, _):
				"The image \(url) loads from another site."
			case let .missingAltText(name, _):
				"The image \(name) has no alt text."
			case let .wikiLink(target, _):
				"[[\(target)]] links to a note that isn't published."
			case .callout:
				"Callouts aren't supported on the site."
			case .highlight:
				"Highlights aren't supported on the site."
			case let .html(tag, _):
				"The HTML tag <\(tag)> would be dropped from the page."
			case .todo:
				"There's a TODO."
		}
	}

	/// What to change in the note to clear the issue.
	var fix: String {
		switch self {
			case .invalidFrontmatter:
				"Open the note's properties in source mode and fix the YAML."
			case .invalidStatus:
				"Set `status` to draft, published, or canceled, or remove it to keep the post in the vault."
			case .invalidProperty:
				"Change the property's value in the note."
			case .missingSlug:
				"Add a `slug`, like the title in lowercase with hyphens between words."
			case .invalidSlug:
				"Use only lowercase letters, digits, and hyphens, like `my-first-post`."
			case .duplicateSlug:
				"Give one of the posts a different slug."
			case .missingDate:
				"Add the publication date as `date`, written as YYYY-MM-DD."
			case .invalidDate:
				"Write the date as YYYY-MM-DD, and set the property's type to Date."
			case .missingTitle:
				"Start the note with the title as an H1, like `# My First Post`."
			case .extraTitle:
				"Make it an H2 or lower."
			case .missingImage:
				"Put the image in the note's assets folder, or fix its name in the note."
			case .duplicateImageName:
				"Rename one of the images."
			case .remoteImage:
				"Download the image into the note's assets folder and embed that copy."
			case .missingAltText:
				"Describe the image in its alt text. In an embed it goes after a pipe: `![[photo.png|A goose on a pond]]`."
			case .wikiLink:
				"Replace it with a Markdown link to a public URL, or with plain text."
			case .callout:
				"Rewrite it as a plain blockquote or a paragraph."
			case .highlight:
				"Use _italics_ or **bold** instead."
			case .html:
				"Rewrite it in Markdown. A linked image can stay as <a href=\"…\"><img src=\"…\" alt=\"…\"></a> on its own line."
			case .todo:
				"Finish or remove it before publishing."
		}
	}
}
