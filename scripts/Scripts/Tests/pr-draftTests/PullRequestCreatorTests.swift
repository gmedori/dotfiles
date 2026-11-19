import CommandKit
import Foundation
import Testing
@testable import pr_draft

@Suite("opening the pull request")
struct PullRequestCreatorTests {
	static let draft = """
	---
	repo: gmedori/example
	branch: db+/share-sheet
	base: main
	---

	# DB+: Share sheet

	Adds a share sheet.

	**Share sheet**
	![[Pasted image 1.png]]

	![[Screen Recording.mov]]
	"""

	let vault: TemporaryVault
	let gh: FakeGitHubCLI
	let stage: URL
	let prepared: PreparedDraft

	init() throws {
		vault = try TemporaryVault()
		gh = try FakeGitHubCLI()
		try vault.write("The Honking Smith/PR Drafts/assets/Pasted image 1.png")
		try vault.write("The Honking Smith/PR Drafts/assets/Screen Recording.mov")
		let draftFile = try vault.write("The Honking Smith/PR Drafts/2026-11-18 db+-share-sheet.md", Self.draft)
		stage = vault.root.appending(path: "stage", directoryHint: .isDirectory)
		prepared = try Staging.prepare(draft: draftFile, altOverrides: [:], stageDirectory: stage)
	}

	func create(asDraft: Bool = false) async throws -> CreatedPullRequest {
		try await PullRequestCreator(gh: gh.cli).create(prepared, in: stage, asDraft: asDraft)
	}

	var stageExists: Bool {
		FileManager.default.fileExists(atPath: stage.path(percentEncoded: false))
	}

	@Test("Opens the pull request from the staging folder with every attachment")
	func opensPullRequest() async throws {
		let created = try await create(asDraft: true)

		#expect(created == CreatedPullRequest(url: FakeGitHubCLI.url, uploaded: 2, failed: [], error: nil))
		let calls = try gh.calls()
		#expect(calls.count == 2)
		#expect(calls[0] == [
			"pr", "create", "-R", "gmedori/example", "--base", "main", "--head", "db+/share-sheet",
			"--title", "DB+: Share sheet", "--body-file", "body.md", "--draft",
			"--attach", "./01-pasted-image-1.png#Share sheet",
			"--attach", "./02-screen-recording.mov",
		])
		#expect(calls[1] == ["pr", "view", FakeGitHubCLI.url, "--json", "body", "-q", ".body"])
		let directory = try #require(gh.workingDirectories().first)
		#expect(URL(filePath: directory).normalizedPath == stage.normalizedPath)
		#expect(try gh.pullRequestBody() == """
		Adds a share sheet.

		**Share sheet**
		![Share sheet](https://github.com/user-attachments/assets/01-pasted-image-1.png)

		![](https://github.com/user-attachments/assets/02-screen-recording.mov)

		""")
		#expect(!stageExists)
	}

	@Test("Uploads failed attachments again against the pull request's current body")
	func retriesFailedUploads() async throws {
		try gh.fail(["./02-screen-recording.mov"], in: "create")

		let created = try await create()

		#expect(created == CreatedPullRequest(url: FakeGitHubCLI.url, uploaded: 2, failed: [], error: nil))
		let calls = try gh.calls()
		#expect(calls.map { $0.prefix(2).joined(separator: " ") } == ["pr create", "pr view", "pr view", "pr edit", "pr view"])
		#expect(calls[3] == [
			"pr", "edit", FakeGitHubCLI.url, "--body-file", "body-retry.md",
			"--attach", "./02-screen-recording.mov",
		])
		#expect(try gh.pullRequestBody().contains("![Share sheet](https://github.com/user-attachments/assets/01-pasted-image-1.png)"))
		#expect(try gh.pullRequestBody().contains("![](https://github.com/user-attachments/assets/02-screen-recording.mov)"))
		#expect(!stageExists)
	}

	@Test("Reports uploads that fail twice and keeps the staging folder")
	func reportsPersistentFailures() async throws {
		try gh.fail(["./01-pasted-image-1.png"], in: "create")
		try gh.fail(["./01-pasted-image-1.png"], in: "edit")

		let created = try await create()

		#expect(created == CreatedPullRequest(
			url: FakeGitHubCLI.url,
			uploaded: 1,
			failed: ["The Honking Smith/PR Drafts/assets/Pasted image 1.png"],
			error: nil,
		))
		#expect(stageExists)
	}

	@Test("Reports what gh printed when it doesn't open a pull request")
	func reportsCreateFailure() async throws {
		try gh.failToOpen()

		let created = try await create()

		#expect(created.url == nil)
		#expect(created.error == "a pull request for branch already exists")
		#expect(try gh.calls().count == 1)
		#expect(stageExists)
	}

	@Test("Knows whether gh can attach files")
	func checksAttachSupport() async {
		#expect(await gh.cli.supportsAttach())
		#expect(await !GitHubCLI(executable: .path("/nonexistent/gh")).supportsAttach())
	}

	@Test("Finds the pull request URL in gh output")
	func findsURL() {
		let output = "Creating pull request for db+/x into main\n\nhttps://github.com/gmedori/example/pull/12\n"
		#expect(PullRequestCreator.pullRequestURL(in: output) == "https://github.com/gmedori/example/pull/12")
		#expect(PullRequestCreator.pullRequestURL(in: "nothing here") == nil)
	}
}
