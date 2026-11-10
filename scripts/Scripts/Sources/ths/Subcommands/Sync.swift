import ArgumentParser
import Escape

// MARK: - Sync

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

	@OptionGroup var paths: SitePaths

	@Flag(help: "Apply the changes. Without it, `sync` only shows what it would do.")
	var write = false

	@Argument(help: "Only sync posts and bundles with these slugs. The build still covers the whole site.")
	var slugs: [String] = []

	func run() async throws {
		let catalog = try Catalog.load(source: paths.sourceDirectory, site: paths.siteDirectory)
		let reporter = Reporter(siteDirectory: paths.siteDirectory)
		let writer = BundleWriter(siteDirectory: paths.siteDirectory)
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

	private func summary(_ counts: [SyncAction.Kind: Int]) -> String {
		let parts: [(SyncAction.Kind, String, String)] = [
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

// MARK: - Sync Action

/// What `sync` does with an entry, decided by its state. A case that writes or deletes a bundle
/// carries the bundle and slug it needs.
enum SyncAction: Sendable {
	/// Writes the bundle for a `new` post.
	case create(PageBundle, slug: String)
	/// Rewrites a `stale` bundle, or an `upToDate` one whose stored hash needs refreshing.
	case update(PageBundle, slug: String)
	/// Deletes the bundle of a `canceled` post, or an `orphanedDraft` bundle.
	case delete(slug: String)
	/// Leaves an `upToDate` bundle as it is.
	case keep
	/// Leaves a problem alone. It's reported after the list.
	case skip

	init(_ entry: CatalogEntry) {
		switch entry {
			case let .new(_, slug, generated, _):
				self = .create(generated, slug: slug)
			case let .stale(_, bundle, generated, _):
				self = .update(generated, slug: bundle.slug)
			case let .upToDate(_, bundle, generated, _):
				self = entry.needsHashRefresh ? .update(generated, slug: bundle.slug) : .keep
			case let .canceled(_, bundle), let .orphanedDraft(bundle):
				self = .delete(slug: bundle.slug)
			case .vaultOnly:
				self = .keep
			case .edited, .conflict, .invalid, .orphanedPublished, .retracted:
				self = .skip
		}
	}

	/// The action without its bundle and slug, for printing and counting.
	var kind: Kind {
		switch self {
			case .create: .create
			case .update: .update
			case .delete: .delete
			case .keep: .keep
			case .skip: .skip
		}
	}

	/// Writes or deletes the bundle. `keep` and `skip` do nothing.
	func apply(with writer: BundleWriter) throws {
		switch self {
			case let .create(bundle, slug), let .update(bundle, slug):
				try writer.write(bundle, slug: slug)
			case let .delete(slug):
				try writer.delete(slug: slug)
			case .keep, .skip:
				break
		}
	}

	// MARK: Kind

	/// A `SyncAction` without its bundle and slug.
	enum Kind: CaseIterable, Hashable, Sendable {
		case create
		case update
		case delete
		case keep
		case skip

		/// The length of the longest word, so the list lines up.
		static let wordWidth = allCases.map(\.word.count).max()!

		/// The word `sync` prints for the action.
		var word: String {
			switch self {
				case .create: "create"
				case .update: "update"
				case .delete: "delete"
				case .keep: "ok"
				case .skip: "skip"
			}
		}

		/// The color the word is printed in.
		var color: Color {
			switch self {
				case .create: .green
				case .update: .cyan
				case .delete: .magenta
				case .keep: .brightBlack
				case .skip: .red
			}
		}
	}
}
