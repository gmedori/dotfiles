import Foundation

// MARK: - Catalog Entry

/// One post or bundle and its state. An entry has a post, a bundle on disk, or both: an orphaned
/// bundle has no post, and a new post has no bundle yet.
struct CatalogEntry: Sendable {
	let state: PostState
	/// The slug, or `nil` for a post that hasn't got one.
	let slug: String?
	let post: BlogPost?
	let existing: ExistingBundle?
	/// The bundle `ths` would write now. Present for every state `sync` writes: `new`, `stale`, and
	/// `upToDate`.
	let generated: PageBundle?
	/// Issues that block the post. Only `invalid` entries have any.
	let issues: [PostIssue]
	/// Issues that don't block the post because it's a draft.
	let warnings: [PostIssue]

	/// Whether an `upToDate` bundle stores a hash other than its contents' hash, which happens when
	/// a hand edit was copied into the vault. `sync` rewrites the bundle so the hash matches again.
	var needsHashRefresh: Bool {
		guard state == .upToDate, let existing, let generated else {
			return false
		}
		return existing.storedHash != PageBundle.contentHash(of: generated.files)
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
	let entries: [CatalogEntry]

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
				entries.append(CatalogEntry(
					state: .vaultOnly,
					slug: post.slug,
					post: post,
					existing: nil,
					generated: nil,
					issues: [],
					warnings: [],
				))
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
			entries.append(CatalogEntry(
				state: bundle.isDraft ? .orphanedDraft : .orphanedPublished,
				slug: bundle.slug,
				post: nil,
				existing: bundle,
				generated: nil,
				issues: [],
				warnings: [],
			))
		}

		return Catalog(entries: entries)
	}

	private static func classify(
		_ post: BlogPost,
		issues: [PostIssue],
		bundles: [String: ExistingBundle],
		source: URL,
	) throws -> CatalogEntry {
		let noteDirectory = source.appending(path: post.relativePath).deletingLastPathComponent()
		let body = BodyConverter(noteDirectory: noteDirectory).convert(post.body, startLine: post.bodyStartLine)
		let readable = !issues.contains { if case .invalidFrontmatter = $0 { true } else { false } }
		let allIssues = issues + (readable ? body.issues : [])

		// A post whose status can't be read is held to everything a published post is.
		let blocking = allIssues.filter { post.status != .draft || $0.blocksDrafts }
		let warnings = allIssues.filter { post.status == .draft && !$0.blocksDrafts }
		let existing = post.slug.flatMap { bundles[$0] }

		func entry(_ state: PostState, generated: PageBundle? = nil) -> CatalogEntry {
			CatalogEntry(
				state: state,
				slug: post.slug,
				post: post,
				existing: existing,
				generated: generated,
				issues: state == .invalid ? blocking : [],
				warnings: warnings,
			)
		}

		guard blocking.isEmpty else {
			return entry(.invalid)
		}

		let generated = try PageBundle.generate(for: post, body: body)
		guard let existing else {
			return entry(.new, generated: generated)
		}
		guard existing.isManaged else {
			return entry(.conflict)
		}
		if post.status == .draft, !existing.isDraft {
			return entry(.retracted)
		}
		if existing.bundle.filesWithoutHash == generated.filesWithoutHash {
			return entry(.upToDate, generated: generated)
		}
		if existing.matchesStoredHash {
			return entry(.stale, generated: generated)
		}
		return entry(.edited)
	}
}
