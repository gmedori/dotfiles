import ArgumentParser

// MARK: - Root Command

@main
struct PRDraft: AsyncParsableCommand {
	static let configuration = CommandConfiguration(
		commandName: "pr-draft",
		abstract: "Opens a pull request from a PR draft in the vault, with its images and videos.",
		discussion: """
		A draft is a Markdown note with `repo`, `branch`, and `base` in its
		frontmatter. Its first `# ` line is the pull request's title, and everything
		after that line is the body. `prepare` stages the draft and the images and
		videos it embeds, and `create` opens the pull request with
		`gh pr create --attach`, which uploads them.

		SKILLS
		  submit-pr  `Skills/submit-pr/SKILL.md` in the vault runs `prepare`, shows
		             the result for approval, and then runs `create`. It reads the
		             JSON both print, so update it along with any change to their
		             options or output.
		""",
		subcommands: [Prepare.self, Create.self],
	)
}
