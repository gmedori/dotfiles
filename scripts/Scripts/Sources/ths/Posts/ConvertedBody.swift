/// A post's body, ready for its bundle's `index.md`, with the images it uses.
struct ConvertedBody: Equatable, Sendable {
	/// The text of the leading H1, or `nil` when the body doesn't open with one.
	var title: String? = nil
	/// The Markdown for the bundle, without the title and ending in one newline.
	var markdown: String
	/// Every image the post uses, in the order they first appear.
	var images: [BundleImage]
	/// Everything in the body the site can't show, each with its line in the note.
	var issues: [PostIssue]
}
