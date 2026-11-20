/// One post or bundle in its state. Each case carries what that state has and nothing more, so an
/// orphaned bundle never has a post, and only an `invalid` post has issues that block it. See
/// `PostState` for what each state means.
///
/// A post whose body was checked also carries its warnings, which are the issues that don't block it
/// because it's a draft. The bodies of `vaultOnly` and `canceled` posts aren't checked, so those
/// cases have no warnings.
enum CatalogEntry: Sendable {
	/// A post with no status, or a canceled post whose bundle is gone.
	case vaultOnly(BlogPost)

	/// A post that passes every check but has no bundle yet, with the bundle `sync` writes for it.
	case new(BlogPost, slug: String, generated: PageBundle, warnings: [PostIssue])

	/// A post whose bundle on disk is exactly what `ths` would generate now.
	case upToDate(BlogPost, bundle: ExistingBundle, generated: PageBundle, warnings: [PostIssue])

	/// A post that changed after the last sync, with the bundle `sync` rewrites for it.
	case stale(BlogPost, bundle: ExistingBundle, generated: PageBundle, warnings: [PostIssue])

	/// A canceled post whose bundle is still in the site repo.
	case canceled(BlogPost, bundle: ExistingBundle)

	/// A draft bundle that `ths` manages and no post claims.
	case orphanedDraft(ExistingBundle)

	/// A post whose bundle was changed outside `ths` after the last sync.
	case edited(BlogPost, bundle: ExistingBundle, warnings: [PostIssue])

	/// A post whose slug belongs to a bundle `ths` doesn't manage.
	case conflict(BlogPost, bundle: ExistingBundle, warnings: [PostIssue])

	/// A post with issues that block it.
	case invalid(BlogPost, issues: [PostIssue], warnings: [PostIssue])

	/// A published bundle that `ths` manages and no post claims.
	case orphanedPublished(ExistingBundle)

	/// A draft post whose bundle is published.
	case retracted(BlogPost, bundle: ExistingBundle, warnings: [PostIssue])

	/// The state the entry is in, without the post and bundle it carries.
	var state: PostState {
		switch self {
			case .vaultOnly: .vaultOnly
			case .new: .new
			case .upToDate: .upToDate
			case .stale: .stale
			case .canceled: .canceled
			case .orphanedDraft: .orphanedDraft
			case .edited: .edited
			case .conflict: .conflict
			case .invalid: .invalid
			case .orphanedPublished: .orphanedPublished
			case .retracted: .retracted
		}
	}

	/// The post, or `nil` for a bundle no post claims.
	var post: BlogPost? {
		switch self {
			case let .vaultOnly(post), let .new(post, _, _, _), let .upToDate(post, _, _, _), let .stale(post, _, _, _),
			     let .canceled(post, _), let .edited(post, _, _), let .conflict(post, _, _), let .invalid(post, _, _),
			     let .retracted(post, _, _):
				post
			case .orphanedDraft, .orphanedPublished:
				nil
		}
	}

	/// The slug, or `nil` for a post that hasn't got one. Only `vaultOnly` and `invalid` posts can be
	/// missing one.
	var slug: String? {
		switch self {
			case let .vaultOnly(post), let .invalid(post, _, _):
				post.slug
			case let .new(_, slug, _, _):
				slug
			case let .upToDate(_, bundle, _, _), let .stale(_, bundle, _, _), let .canceled(_, bundle),
			     let .edited(_, bundle, _), let .conflict(_, bundle, _), let .retracted(_, bundle, _),
			     let .orphanedDraft(bundle), let .orphanedPublished(bundle):
				bundle.slug
		}
	}

	/// The issues that don't block the post because it's a draft.
	var warnings: [PostIssue] {
		switch self {
			case let .new(_, _, _, warnings), let .upToDate(_, _, _, warnings), let .stale(_, _, _, warnings),
			     let .edited(_, _, warnings), let .conflict(_, _, warnings), let .invalid(_, _, warnings),
			     let .retracted(_, _, warnings):
				warnings
			case .vaultOnly, .canceled, .orphanedDraft, .orphanedPublished:
				[]
		}
	}

	/// Whether an `upToDate` bundle stores a hash other than the hash of its files. That happens when
	/// a hand edit was copied into the vault. `sync` rewrites the bundle so the hash matches again.
	var needsHashRefresh: Bool {
		guard case let .upToDate(_, bundle, generated, _) = self else {
			return false
		}

		return bundle.storedHash != PageBundle.contentHash(of: generated.files)
	}

	/// The bundle's folder in the site repo, like `content/blog/a-post/`.
	var bundlePath: String? {
		slug.map { "content/blog/\($0)/" }
	}
}
