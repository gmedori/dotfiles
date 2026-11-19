import ArgumentParser

// MARK: - Root Command

@main
struct PRDraft: AsyncParsableCommand {
	static let configuration = CommandConfiguration(
		commandName: "pr-draft",
		abstract: "Stages a PR draft from the vault, with its images and videos, for `gh pr create`.",
		discussion: """
		A draft is a Markdown note with `repo`, `branch`, and `base` in its
		frontmatter. Its first `# ` line is the pull request's title, and everything
		after that line is the body. `prepare` stages the draft and the images and
		videos it embeds for `gh pr create --attach`, which uploads them.

		SKILLS
		  submit-pr  `Skills/submit-pr/SKILL.md` in the vault runs `prepare` and
		             reads the JSON it prints, so update it along with any change
		             to its options or output.
		""",
		subcommands: [Prepare.self],
	)
}
