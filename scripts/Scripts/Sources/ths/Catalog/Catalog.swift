import Foundation

/// Every blog post in the source directory and every bundle in the site repo, each given a
/// `PostState`. See `PostState` for what each state means.
struct Catalog: Sendable {
	/// The posts in path order, followed by the bundles no post claims in slug order.
	var entries: [CatalogEntry]

	/// Whether any entry is in a state that's a problem.
	var hasProblems: Bool {
		entries.contains { $0.state.isProblem }
	}
}

// MARK: - Static Members

extension Catalog {
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
			try entries.append(classify(post, issues: issues, bundles: bundles, source: source))
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
}

// MARK: - Private Helpers

extension Catalog {
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

			return existing.isManaged
				? .canceled(post, bundle: existing)
				: .conflict(
					post,
					bundle: existing,
					warnings: [],
				)
		}

		let noteDirectory = source.appending(path: post.relativePath).deletingLastPathComponent()
		let body = BodyConverter(noteDirectory: noteDirectory).convert(post.body, startLine: post.bodyStartLine)
		let readable = !issues.contains { issue in
			if case .invalidFrontmatter = issue {
				true
			} else {
				false
			}
		}
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
