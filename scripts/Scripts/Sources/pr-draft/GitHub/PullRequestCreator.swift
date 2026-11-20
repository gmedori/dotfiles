import CommandKit
import Foundation

// MARK: - Created Pull Request

/// What `create` did, printed as JSON.
struct CreatedPullRequest: Codable, Equatable, Sendable {
	/// The pull request's URL, or `nil` when `gh` didn't open one.
	let url: String?
	/// How many attachments uploaded.
	let uploaded: Int
	/// The vault paths of the attachments that didn't upload.
	let failed: [String]
	/// What `gh` printed to standard error when it didn't open a pull request.
	let error: String?
}

// MARK: - Pull Request Creator

/// Opens a staged draft's pull request and checks that its attachments uploaded.
///
/// `gh pr create --attach` keeps going when an upload fails, so the pull request opens with that
/// file's reference still pointing at its staged copy. After opening it, the creator reads the body
/// back, and any staged path still in it means that upload failed. Those files get one more try with
/// `gh pr edit`, against the body as it is then, so the uploads that worked keep their URLs.
struct PullRequestCreator {
	static let retryBodyFileName = "body-retry.md"

	let gh: GitHubCLI

	/// The last pull request URL in `gh` output.
	static func pullRequestURL(in output: String) -> String? {
		output.matches(of: #/https://github\.com/[^\s]+/pull/\d+/#).last.map { String($0.output) }
	}

	/// The attachments whose staged path is still in `body`, which means they didn't upload.
	static func stillStaged(_ attachments: [Attachment], in body: String) -> [Attachment] {
		attachments.filter { body.contains($0.staged) }
	}

	func create(_ prepared: PreparedDraft, in stageDirectory: URL, asDraft: Bool) async throws -> CreatedPullRequest {
		guard
			let repo = prepared.repo, let base = prepared.base, let branch = prepared.branch,
			let title = prepared.title
		else {
			throw RuntimeError(
				"The draft has no title or is missing frontmatter, so there's no pull request to open. Fix the draft and run `pr-draft prepare` again."
			)
		}

		var arguments = [
			"pr", "create", "-R", repo, "--base", base, "--head", branch,
			"--title", title, "--body-file", Staging.bodyFileName,
		]
		if asDraft {
			arguments.append("--draft")
		}
		arguments += prepared.attachments.flatMap { ["--attach", $0.attachArgument] }

		let output = try await gh.run(arguments, in: stageDirectory)
		guard let url = Self.pullRequestURL(in: output.standardOutput) else {
			let error = output.standardError.trimmingCharacters(in: .whitespacesAndNewlines)
			return CreatedPullRequest(
				url: nil,
				uploaded: 0,
				failed: prepared.attachments.map(\.source),
				error: error.isEmpty ? "gh pr create failed without printing a pull request URL." : error,
			)
		}

		var failed = try await Self.stillStaged(prepared.attachments, in: bodyIfNeeded(prepared, url: url))
		if !failed.isEmpty {
			let body = try await gh.pullRequestBody(url)
			try body.write(
				to: stageDirectory.appending(path: Self.retryBodyFileName),
				atomically: true,
				encoding: .utf8,
			)
			_ = try await gh.run(
				["pr", "edit", url, "--body-file", Self.retryBodyFileName]
					+ failed.flatMap { ["--attach", $0.attachArgument] },
				in: stageDirectory,
			)
			failed = try await Self.stillStaged(failed, in: gh.pullRequestBody(url))
		}

		if failed.isEmpty {
			try? FileManager.default.removeItem(at: stageDirectory)
		}
		return CreatedPullRequest(
			url: url,
			uploaded: prepared.attachments.count - failed.count,
			failed: failed.map(\.source),
			error: nil,
		)
	}

	/// The pull request's body, or an empty one when there are no attachments to check.
	private func bodyIfNeeded(_ prepared: PreparedDraft, url: String) async throws -> String {
		prepared.attachments.isEmpty ? "" : try await gh.pullRequestBody(url)
	}
}
