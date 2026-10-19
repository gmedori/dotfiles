import ArgumentParser

// MARK: - Root Command

@main
struct THS: AsyncParsableCommand {
	static let configuration = CommandConfiguration(
		commandName: "ths",
		abstract: "Publishes The Honking Smith blog posts from the vault to the website repo.",
		discussion: """
		Posts are vault notes with `type: blog post` in their frontmatter, anywhere
		under the source directory. Each one with a `status` of `draft` or
		`published` becomes a page bundle at content/blog/<slug>/ in the site repo.

		ENVIRONMENT
		  THS_SOURCE_DIR  The Honking Smith folder in the vault, used when --source
		                  isn't given.
		  THS_SITE_DIR    The website repo, used when --site isn't given.

		  To set both for every fish session:

		    \(SitePaths.sourceSetCommand)
		    \(SitePaths.siteSetCommand)
		""",
		subcommands: [Status.self, Sync.self, Deploy.self],
	)
}
