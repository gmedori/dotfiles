import ArgumentParser
import CommandKit
import Foundation

/// Opens the pull request for a draft that `prepare` staged.
struct Create: AsyncParsableCommand {
	static let configuration = CommandConfiguration(
		abstract: "Opens the pull request for a draft that `prepare` staged.",
		discussion: """
			`create` runs `gh pr create` from the staging folder with the draft's repo,
			base, branch, title, and staged body, and passes each staged file to
			`--attach`. `gh` uploads the files and points their references in the body
			at the uploads. Then `create` reads the pull request's body back. A
			reference that still points at a staged file means its upload failed, and
			`create` tries those files once more with `gh pr edit`.

			It prints JSON with the pull request's `url`, the number of attachments
			`uploaded`, and the vault paths of the ones that `failed`. When `gh` doesn't
			open a pull request, `url` is missing and `error` has what `gh` printed.
			When every upload worked, `create` deletes the staging folder. It exits 1
			when an upload still failed or no pull request was opened.
			""",
	)

	@Argument(help: "The staging folder, which `prepare` prints as `stage_dir`.")
	var stageDir: String

	@Flag(help: "Open the pull request as a draft.")
	var draft = false

	func run() async throws {
		let stageDirectory = URL(filePath: stageDir, directoryHint: .isDirectory, relativeTo: .currentDirectory())
			.absoluteURL
			.standardizedFileURL
		let prepared = try Staging.loadManifest(from: stageDirectory)
		let created = try await PullRequestCreator(gh: GitHubCLI()).create(
			prepared,
			in: stageDirectory,
			asDraft: draft,
		)
		try print(JSON.encode(created))
		if created.url == nil || !created.failed.isEmpty {
			throw ExitCode.failure
		}
	}
}
