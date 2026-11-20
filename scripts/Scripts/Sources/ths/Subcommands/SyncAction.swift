import Escape

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
}

// MARK: - Supporting Types

extension SyncAction {
	/// A `SyncAction` without its bundle and slug.
	enum Kind: CaseIterable, Hashable, Sendable {
		case create
		case update
		case delete
		case keep
		case skip

		/// The length of the longest word, so the list lines up.
		static let wordWidth = allCases.map(\.word.count).max() ?? 0

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

		/// How the summary counts the action without `--write`, or `nil` for `keep`, which it leaves out.
		var plannedPhrase: String? {
			switch self {
				case .create: "to create"
				case .update: "to update"
				case .delete: "to delete"
				case .keep: nil
				case .skip: "skipped"
			}
		}

		/// How the summary counts the action with `--write`, or `nil` for `keep`, which it leaves out.
		var appliedPhrase: String? {
			switch self {
				case .create: "created"
				case .update: "updated"
				case .delete: "deleted"
				case .keep: nil
				case .skip: "skipped"
			}
		}
	}
}
