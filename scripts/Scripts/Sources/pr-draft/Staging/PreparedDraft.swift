/// What `prepare` found in a draft. `prepare` prints it as JSON and saves it in the staging folder
/// as `manifest.json`, which `create` reads.
struct PreparedDraft: Codable, Equatable, Sendable {
	/// Whether `errors` is empty.
	var ok: Bool
	/// Missing frontmatter, a missing title, and every embed that can't be staged, as sentences.
	var errors: [String]
	/// Files over GitHub's size limits, as sentences.
	var warnings: [String]
	/// The label of each `<!-- TODO: … -->` placeholder in the body.
	var placeholders: [String]
	/// The numbers of the images that have no alt text.
	var needsAlt: [Int]
	/// The draft's `repo`, as `owner/name`.
	var repo: String? = nil
	/// The draft's `base`, the branch the pull request merges into.
	var base: String? = nil
	/// The draft's `branch`, which has the changes.
	var branch: String? = nil
	/// The draft's title.
	var title: String? = nil
	/// Every image and video the body embeds, in the order they first appear.
	var attachments: [Attachment]
	/// The staging folder, which holds the copies, `body.md`, and `manifest.json`.
	var stageDir: String
	/// The staged body, which is the draft's body with each embed pointing at its copy.
	var bodyFile: String
	/// Whether the installed `gh` has `--attach`. It's `nil` when there are no attachments, since
	/// it's only checked then, and the JSON leaves it out.
	// swiftlint:disable:next discouraged_optional_boolean
	var ghSupportsAttach: Bool? = nil
}
