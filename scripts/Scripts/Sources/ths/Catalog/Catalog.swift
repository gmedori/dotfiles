import Foundation

// MARK: - Catalog Entry

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

// MARK: - Catalog

/// Every blog post in the source directory and every bundle in the site repo, each given a
/// `PostState`. See `PostState` for what each state means.
struct Catalog: Sendable {
	/// The posts in path order, followed by the bundles no post claims in slug order.
	let entries: [CatalogEntry]

	/// Whether any entry is in a state that's a problem.
	var hasProblems: Bool {
		entries.contains { $0.state.isProblem }
	}

	/// Reads the vault and the site repo and classifies everything in them.
	static func load(source: URL, site: URL) throws -> Catalog {
		let posts = try BlogPost.discover(in: source)
		let bundles = try ExistingBundle.readAll(in: site)
		return try classify(posts: posts, bundles: bundles, source: source)
	}

	/// Gives every post and every managed bundle a state.
	///
	/// A post with a status claims its slug, even when it's invalid, so its bundle isn't treated as
	/// orphaned while the note is being fixed. A managed bundle no post claims is orphaned. Bundles
	/// `ths` doesn't manage only appear when a post claims their slug, as a conflict.
	static func classify(posts: [BlogPost], bundles: [String: ExistingBundle], source: URL) throws -> Catalog {
		let claiming = posts.filter { $0.status != nil || !$0.issues.isEmpty }
		var pathsBySlug: [String: [String]] = [:]
		for post in claiming {
			if let slug = post.slug {
				pathsBySlug[slug, default: []].append(post.relativePath)
			}
		}

		var entries: [CatalogEntry] = []
		for post in posts {
			if post.status == nil, post.issues.isEmpty {
				entries.append(.vaultOnly(post))
				continue
			}

			var issues = post.issues
			if let slug = post.slug {
				for otherPath in pathsBySlug[slug, default: []] where otherPath != post.relativePath {
					issues.append(.duplicateSlug(otherPath: otherPath))
				}
			}
			entries.append(try classify(post, issues: issues, bundles: bundles, source: source))
		}

		let claimedSlugs = Set(pathsBySlug.keys)
		for bundle in bundles.values.sorted(by: { $0.slug < $1.slug }) where bundle.isManaged {
			guard !claimedSlugs.contains(bundle.slug) else {
				continue
			}
			entries.append(bundle.isDraft ? .orphanedDraft(bundle) : .orphanedPublished(bundle))
		}

		return Catalog(entries: entries)
	}

	private static func classify(
		_ post: BlogPost,
		issues: [PostIssue],
		bundles: [String: ExistingBundle],
		source: URL,
	) throws -> CatalogEntry {
		let existing = post.slug.flatMap { bundles[$0] }

		// The slug of a canceled post only finds its bundle. Without one, there's nothing to take down.
		// Its body isn't checked or converted, since nothing from it will be written.
		if post.status == .canceled {
			guard issues.isEmpty else {
				return .invalid(post, issues: issues, warnings: [])
			}
			guard let existing else {
				return .vaultOnly(post)
			}
			return existing.isManaged ? .canceled(post, bundle: existing) : .conflict(post, bundle: existing, warnings: [])
		}

		let noteDirectory = source.appending(path: post.relativePath).deletingLastPathComponent()
		let body = BodyConverter(noteDirectory: noteDirectory).convert(post.body, startLine: post.bodyStartLine)
		let readable = !issues.contains { if case .invalidFrontmatter = $0 { true } else { false } }
		let allIssues = issues + (readable ? body.issues : [])

		// A post whose status can't be read is held to everything a published post is.
		let blocking = allIssues.filter { post.status != .draft || $0.blocksDrafts }
		let warnings = allIssues.filter { post.status == .draft && !$0.blocksDrafts }

		guard blocking.isEmpty else {
			return .invalid(post, issues: blocking, warnings: warnings)
		}
		// A missing slug always blocks a post, so a post that gets this far has one.
		guard let slug = post.slug else {
			return .invalid(post, issues: [.missingSlug], warnings: warnings)
		}

		let generated = try PageBundle.generate(for: post, body: body)
		guard let existing else {
			return .new(post, slug: slug, generated: generated, warnings: warnings)
		}
		guard existing.isManaged else {
			return .conflict(post, bundle: existing, warnings: warnings)
		}
		if post.status == .draft, !existing.isDraft {
			return .retracted(post, bundle: existing, warnings: warnings)
		}
		if existing.bundle.filesWithoutHash == generated.filesWithoutHash {
			return .upToDate(post, bundle: existing, generated: generated, warnings: warnings)
		}
		if existing.matchesStoredHash {
			return .stale(post, bundle: existing, generated: generated, warnings: warnings)
		}
		return .edited(post, bundle: existing, warnings: warnings)
	}
}
