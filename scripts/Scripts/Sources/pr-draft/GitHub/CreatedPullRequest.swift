/// What `create` did, printed as JSON.
struct CreatedPullRequest: Codable, Equatable, Sendable {
	/// The pull request's URL, or `nil` when `gh` didn't open one.
	var url: String? = nil
	/// How many attachments uploaded.
	var uploaded: Int
	/// The vault paths of the attachments that didn't upload.
	var failed: [String]
	/// What `gh` printed to standard error when it didn't open a pull request.
	var error: String? = nil
}
