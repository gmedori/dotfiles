import ArgumentParser
import CommandKit
import Foundation

// MARK: - Prepare

/// Stages a draft for `create` and prints what it found.
struct Prepare: AsyncParsableCommand {
	static let configuration = CommandConfiguration(
		abstract: "Stages a draft's images and videos and prints what it found as JSON.",
		discussion: """
		`prepare` copies each image and video the draft's body embeds into a
		staging folder under the system temp folder, with names that have no
		spaces. It writes the body there as `body.md`, with each embed rewritten as
		a Markdown image that points at its copy, like `![Alt text](./01-shot.png)`.
		It saves what it found as `manifest.json` for `create`. Running it again
		replaces the folder.

		An embed is an Obsidian embed, like `![[shot.png]]` or
		`![[shot.png|Alt text]]`, or a Markdown image, like
		`![Alt text](assets/shot.png)`. Links resolve the way Obsidian resolves them.
		Embeds in code and HTML comments, and images that point at a URL, stay as
		written. An image's alt text comes from `--alt`, then the embed, then a bold
		label line directly above it.

		JSON
		  errors              Missing frontmatter and the embeds that can't be
		                      staged. Those embeds stay in the body as written.
		  warnings            Files over GitHub's size limits.
		  placeholders        The labels of `<!-- TODO: … -->` lines.
		  attachments         Each file's number, kind, vault path, staged path,
		                      and alt text.
		  needs_alt           The numbers of images without alt text.
		  gh_supports_attach  Whether `gh` has `--attach`, when there are
		                      attachments.
		  stage_dir           The staging folder, which `create` takes.
		  body_file           The staged body.
		""",
	)

	@Argument(help: "The draft's Markdown file.")
	var draft: String

	@Option(
		name: .customLong("alt"),
		help: ArgumentHelp(
			"Alt text for attachment N, used over any the draft gives it. Repeat it for more attachments.",
			valueName: "N=TEXT",
		),
	)
	var alt: [String] = []

	func validate() throws {
		_ = try altOverrides()
	}

	func run() async throws {
		let draftFile = URL(filePath: draft, relativeTo: .currentDirectory()).absoluteURL.standardizedFileURL
		guard FileManager.default.fileExists(atPath: draftFile.path(percentEncoded: false)) else {
			throw RuntimeError("There's no draft at \(draftFile.path(percentEncoded: false)).")
		}

		var prepared = try Staging.prepare(
			draft: draftFile,
			altOverrides: altOverrides(),
			stageDirectory: Staging.directory(for: draftFile),
		)
		if !prepared.attachments.isEmpty {
			prepared.ghSupportsAttach = await GitHubCLI().supportsAttach()
		}
		try Staging.saveManifest(prepared)
		print(try JSON.encode(prepared))
	}

	/// The `--alt` values by attachment number, with their text cleaned the way alt text from the
	/// draft is.
	private func altOverrides() throws -> [Int: String] {
		var overrides: [Int: String] = [:]
		for value in alt {
			let parts = value.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
			guard
				parts.count == 2,
				let number = Int(parts[0].trimmingCharacters(in: .whitespaces)),
				let text = BodyRewriter.cleanAlt(String(parts[1]))
			else {
				throw ValidationError("`--alt` takes N=TEXT, like `--alt '2=Share sheet in dark mode'`, not `\(value)`.")
			}
			overrides[number] = text
		}
		return overrides
	}
}
