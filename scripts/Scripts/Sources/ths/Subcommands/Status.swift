import ArgumentParser

// MARK: - Status

/// Reports the state of every post without changing anything.
struct Status: AsyncParsableCommand {
	static let configuration = CommandConfiguration(
		abstract: "Shows where each post stands between the vault and the site, without changing anything.",
		discussion: """
		STATES
		\(PostState.allCases.map { state in
			"  " + state.label.padding(toLength: Reporter.labelWidth, withPad: " ", startingAt: 0) + "  " + state.summary
		}.joined(separator: "\n"))

		Problems are listed after the posts with what to change, and make `status`
		exit 1. Pending changes, like new or stale posts, don't.
		""",
	)

	@OptionGroup var paths: SitePaths

	@Argument(help: "Only report on posts and bundles with these slugs.")
	var slugs: [String] = []

	func run() async throws {
		let catalog = try Catalog.load(source: paths.sourceDirectory, site: paths.siteDirectory)
		let reporter = Reporter(siteDirectory: paths.siteDirectory)
		let selection = SlugSelection(slugs: slugs, catalog: catalog)

		if catalog.entries.isEmpty {
			print("No blog posts in \(reporter.displayPath(paths.sourceDirectory)).")
			print("A blog post is a note with `type: blog post` in its frontmatter.")
			return
		}

		let width = reporter.slugWidth(for: selection.entries)
		for entry in selection.entries {
			print(reporter.line(
				entry.state.label,
				color: entry.state.color,
				wordWidth: Reporter.labelWidth,
				slug: entry.slug,
				detail: reporter.location(of: entry),
				slugWidth: width,
			))
		}

		let messages = selection.entries.flatMap(reporter.messages(for:)) + selection.unknownSlugMessages
		if !messages.isEmpty {
			print("")
			print(messages.map(reporter.format).joined(separator: "\n\n"))
		}

		if selection.entries.contains(where: \.state.isProblem) || !selection.unknownSlugs.isEmpty {
			throw ExitCode.failure
		}
	}
}

// MARK: - Slug Selection

/// The catalog entries a command acts on. That's all of them, or only those with the slugs given on
/// the command line. A slug that matches nothing is reported as an error.
struct SlugSelection {
	let entries: [CatalogEntry]
	let unknownSlugs: [String]

	init(slugs: [String], catalog: Catalog) {
		guard !slugs.isEmpty else {
			entries = catalog.entries
			unknownSlugs = []
			return
		}
		let wanted = Set(slugs)
		entries = catalog.entries.filter { $0.slug.map(wanted.contains) == true }
		let found = Set(entries.compactMap(\.slug))
		unknownSlugs = slugs.filter { !found.contains($0) }
	}

	var unknownSlugMessages: [Message] {
		unknownSlugs.map {
			Message(kind: .error, headline: "no post or bundle has the slug \($0)", details: [])
		}
	}
}
