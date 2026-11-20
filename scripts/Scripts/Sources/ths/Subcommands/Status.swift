import ArgumentParser
import Foundation

/// Reports the state of every post without changing anything.
struct Status: AsyncParsableCommand {
	static let configuration = CommandConfiguration(
		abstract: "Shows where each post stands between the vault and the site, without changing anything.",
		discussion: """
			STATES
			\(stateTable)

			Problems are listed after the posts with what to change, and make `status`
			exit 1. Pending changes, like new or stale posts, don't.
			""",
	)

	@OptionGroup
	var paths: SitePaths

	@Argument(help: "Only report on posts and bundles with these slugs.")
	var slugs: [String] = []

	func run() throws {
		let sourceDirectory = try paths.sourceDirectory
		let siteDirectory = try paths.siteDirectory
		let catalog = try Catalog.load(source: sourceDirectory, site: siteDirectory)
		let reporter = Reporter(siteDirectory: siteDirectory)
		let selection = SlugSelection(slugs: slugs, catalog: catalog)

		if catalog.entries.isEmpty {
			print("No blog posts in \(reporter.displayPath(sourceDirectory)).")
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

// MARK: - Private Helpers

extension Status {
	/// Each state's label and summary, one state to a line, for the help.
	private static var stateTable: String {
		PostState.allCases
			.map { state in
				let label = state.label.padding(toLength: Reporter.labelWidth, withPad: " ", startingAt: 0)
				return "  \(label)  \(state.summary)"
			}
			.joined(separator: "\n")
	}
}
