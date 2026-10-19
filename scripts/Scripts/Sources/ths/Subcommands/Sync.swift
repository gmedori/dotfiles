import ArgumentParser
import Escape

// MARK: - Sync

/// Brings the site repo in line with the vault: creates, rewrites, and deletes bundles according to
/// each post's state. Problems are skipped and reported without stopping the run, so one run
/// surfaces every problem.
struct Sync: AsyncParsableCommand {
	static let configuration = CommandConfiguration(
		abstract: "Writes the vault's blog posts into the site repo.",
		discussion: """
		Without --write, sync only shows what it would do. With --write, it creates
		new bundles, rewrites stale ones, deletes orphaned drafts, and then runs the
		production build, which has to finish with no warnings. Bundles of canceled
		posts are deleted too.

		Problems, like a bundle edited by hand, are skipped and listed with what to
		change, and the rest of the posts are still synced. Any problem makes sync
		exit 1. Run `ths status --help` for what each state means. sync never
		commits.
		""",
	)

	@OptionGroup var paths: SitePaths

	@Flag(help: "Apply the changes. Without it, sync only shows what it would do.")
	var write = false

	@Argument(help: "Only sync posts and bundles with these slugs. The build still covers the whole site.")
	var slugs: [String] = []

	func run() async throws {
		let catalog = try Catalog.load(source: paths.sourceDirectory, site: paths.siteDirectory)
		let reporter = Reporter(siteDirectory: paths.siteDirectory)
		let writer = BundleWriter(siteDirectory: paths.siteDirectory)
		let selection = SlugSelection(slugs: slugs, catalog: catalog)
		let entries = selection.entries.filter { $0.state != .vaultOnly }

		var counts: [SyncAction: Int] = [:]
		let width = reporter.slugWidth(for: entries)
		for entry in entries {
			let action = SyncAction(entry)
			counts[action, default: 0] += 1
			if write {
				try action.apply(to: entry, with: writer)
			}
			print(reporter.line(
				action.word,
				color: action.color,
				wordWidth: SyncAction.wordWidth,
				slug: entry.slug,
				detail: action.detail(for: entry),
				slugWidth: width,
			))
		}

		var messages = selection.entries.flatMap(reporter.messages(for:)) + selection.unknownSlugMessages
		var buildFailed = false
		if write, let failure = await HugoBuild.run(in: paths.siteDirectory) {
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

	private func summary(_ counts: [SyncAction: Int]) -> String {
		let parts: [(SyncAction, String, String)] = [
			(.create, "to create", "created"),
			(.update, "to update", "updated"),
			(.delete, "to delete", "deleted"),
			(.skip, "skipped", "skipped"),
		]
		var phrases = parts.compactMap { action, planned, done in
			counts[action].map { "\($0) \(write ? done : planned)" }
		}
		if phrases.isEmpty {
			phrases = ["Nothing to change"]
		}
		let changes = phrases.joined(separator: ", ") + "."
		return write ? changes : changes + " Dry run, so nothing was written. Run with --write to apply."
	}
}

// MARK: - Sync Action

/// What `sync` does with an entry, decided by its state.
enum SyncAction: Hashable {
	/// Writes a bundle for a `new` post.
	case create
	/// Rewrites a `stale` bundle, or an `upToDate` one whose stored hash needs refreshing.
	case update
	/// Deletes the bundle of a `canceled` post, or an `orphanedDraft` bundle.
	case delete
	/// Leaves an `upToDate` bundle as it is.
	case keep
	/// Leaves a problem alone. It's reported after the list.
	case skip

	init(_ entry: CatalogEntry) {
		switch entry.state {
			case .new: self = .create
			case .stale: self = .update
			case .upToDate: self = entry.needsHashRefresh ? .update : .keep
			case .canceled, .orphanedDraft: self = .delete
			case .vaultOnly: self = .keep
			case .edited, .conflict, .invalid, .orphanedPublished, .retracted: self = .skip
		}
	}

	static let wordWidth = [create, update, delete, keep, skip].map(\.word.count).max()!

	var word: String {
		switch self {
			case .create: "create"
			case .update: "update"
			case .delete: "delete"
			case .keep: "ok"
			case .skip: "skip"
		}
	}

	var color: Color {
		switch self {
			case .create: .green
			case .update: .cyan
			case .delete: .magenta
			case .keep: .brightBlack
			case .skip: .red
		}
	}

	func detail(for entry: CatalogEntry) -> String {
		switch self {
			case .skip:
				entry.state.label
			case .update where entry.state == .upToDate:
				"hash only"
			case .delete where entry.state == .canceled:
				"canceled"
			case .create, .update, .delete, .keep:
				entry.post?.status == .draft || (entry.post == nil && entry.existing?.isDraft == true) ? "draft" : ""
		}
	}

	func apply(to entry: CatalogEntry, with writer: BundleWriter) throws {
		switch self {
			case .create, .update:
				guard let slug = entry.slug, let generated = entry.generated else {
					return
				}
				try writer.write(generated, slug: slug)
			case .delete:
				guard let slug = entry.slug else {
					return
				}
				try writer.delete(slug: slug)
			case .keep, .skip:
				break
		}
	}
}
