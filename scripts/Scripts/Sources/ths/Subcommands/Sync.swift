import ArgumentParser

/// Brings the site repo in line with the vault. It creates, rewrites, and deletes bundles according
/// to the state of each post. Problems are skipped and reported without stopping the run, so one
/// run surfaces every problem.
struct Sync: AsyncParsableCommand {
	static let configuration = CommandConfiguration(
		abstract: "Writes the vault's blog posts into the site repo.",
		discussion: """
			Without `--write`, `sync` only shows what it would do. With `--write`, it
			creates bundles for new posts, rewrites stale bundles, and deletes orphaned
			drafts along with the bundles of canceled posts. Then it runs the production
			build, which has to finish with no warnings.

			Problems, like a bundle edited by hand, are skipped and listed with what to
			change, and the rest of the posts are still synced. Any problem makes `sync`
			exit 1. Run `ths status --help` for what each state means. `sync` never
			commits.
			""",
	)

	@OptionGroup
	var paths: SitePaths

	@Flag(help: "Apply the changes. Without it, `sync` only shows what it would do.")
	var write = false

	@Argument(help: "Only sync posts and bundles with these slugs. The build still covers the whole site.")
	var slugs: [String] = []

	func run() async throws {
		let sourceDirectory = try paths.sourceDirectory
		let siteDirectory = try paths.siteDirectory
		let catalog = try Catalog.load(source: sourceDirectory, site: siteDirectory)
		let reporter = Reporter(siteDirectory: siteDirectory)
		let writer = BundleWriter(siteDirectory: siteDirectory)
		let selection = SlugSelection(slugs: slugs, catalog: catalog)
		let entries = selection.entries.filter { $0.state != .vaultOnly }

		var counts: [SyncAction.Kind: Int] = [:]
		let width = reporter.slugWidth(for: entries)
		for entry in entries {
			let action = SyncAction(entry)
			counts[action.kind, default: 0] += 1
			if write {
				try action.apply(with: writer)
			}
			print(reporter.line(
				action.kind.word,
				color: action.kind.color,
				wordWidth: SyncAction.Kind.wordWidth,
				slug: entry.slug,
				detail: detail(for: entry),
				slugWidth: width,
			))
		}

		var messages = selection.entries.flatMap(reporter.messages(for:)) + selection.unknownSlugMessages
		var buildFailed = false
		if write, let failure = await HugoBuild.run(in: siteDirectory) {
			messages.append(failure)
			buildFailed = true
		}

		if !messages.isEmpty {
			print("")
			print(messages.map(reporter.format).joined(separator: "\n\n"))
		}
		print("")
		print(summary(counts))

		if entries.contains(where: \.state.isProblem) || !selection.unknownSlugs.isEmpty || buildFailed {
			throw ExitCode.failure
		}
	}
}

// MARK: - Private Helpers

extension Sync {
	/// The line that counts what `sync` did, or would do without `--write`.
	private func summary(_ counts: [SyncAction.Kind: Int]) -> String {
		var phrases = SyncAction.Kind.allCases.compactMap { kind -> String? in
			guard
				let count = counts[kind],
				let phrase = write ? kind.appliedPhrase : kind.plannedPhrase
			else {
				return nil
			}

			return "\(count) \(phrase)"
		}
		if phrases.isEmpty {
			phrases = ["Nothing to change"]
		}
		let changes = phrases.joined(separator: ", ") + "."
		return write ? changes : changes + " Dry run, so nothing was written. Run with `--write` to apply."
	}

	/// The note printed after the slug, like `draft` or `hash only`.
	private func detail(for entry: CatalogEntry) -> String {
		switch entry {
			case .edited, .conflict, .invalid, .orphanedPublished, .retracted:
				entry.state.label
			case .upToDate where entry.needsHashRefresh:
				"hash only"
			case .canceled:
				"canceled"
			case .orphanedDraft:
				"draft"
			case let .vaultOnly(post), let .new(post, _, _, _), let .upToDate(post, _, _, _), let .stale(post, _, _, _):
				post.status == .draft ? "draft" : ""
		}
	}
}
