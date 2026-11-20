import Foundation

/// The pull request that `gh pr view` finds for the argument, which `pr-watch` then polls by its ID.
struct PullRequestReference: Decodable, Sendable {
	/// The pull request's GraphQL node ID.
	var id: String
	/// The pull request's web URL.
	var url: String

	/// The GitHub host the pull request is on, from its URL.
	var host: String {
		URL(string: url)?.host ?? "github.com"
	}
}
