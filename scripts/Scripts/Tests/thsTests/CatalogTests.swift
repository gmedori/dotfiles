import Foundation
import Testing
@testable import ths

@Suite("post states")
struct CatalogTests {
	let source = URL(filePath: "/vault", directoryHint: .isDirectory)

	func post(
		_ slug: String?,
		status: String? = "published",
		path: String? = nil,
		body: String = "# Title\n\nBody.",
	) throws -> BlogPost {
		var properties = ["type: blog post", "date: 2025-03-31"]
		if let status {
			properties.append("status: \(status)")
		}
		if let slug {
			properties.append("slug: \(slug)")
		}
		return try #require(BlogPost.parse(
			"---\n\(properties.joined(separator: "\n"))\n---\n\(body)",
			relativePath: path ?? "Blog Posts/\(slug ?? "untitled").md",
		))
	}

	/// The bundle `ths` would write for the post, as if it were on disk.
	func bundle(for post: BlogPost, editing edit: ((inout [String: Data]) -> Void)? = nil) throws -> ExistingBundle {
		let body = BodyConverter(noteDirectory: source).convert(post.body, startLine: post.bodyStartLine)
		var files = try PageBundle.generate(for: post, body: body).files
		edit?(&files)
		return bundle(post.slug!, files: files, vaultSource: PageBundle.vaultSource(for: post), isDraft: post.status == .draft)
	}

	func bundle(_ slug: String, files: [String: Data], vaultSource: String?, isDraft: Bool) -> ExistingBundle {
		let hash = files["index.md"].flatMap { data in
			String(decoding: data, as: UTF8.self).firstMatch(of: /generatedHash: "([^"]*)"/).map { String($0.1) }
		}
		return ExistingBundle(
			slug: slug,
			directory: URL(filePath: "/site/content/blog/\(slug)"),
			bundle: PageBundle(files: files),
			vaultSource: vaultSource,
			storedHash: hash,
			isDraft: isDraft,
		)
	}

	/// Each entry's state, keyed by its note's path, or by `bundle <slug>` for a bundle with no note.
	func states(posts: [BlogPost], bundles: [ExistingBundle] = []) throws -> [String: PostState] {
		let catalog = try Catalog.classify(
			posts: posts,
			bundles: Dictionary(uniqueKeysWithValues: bundles.map { ($0.slug, $0) }),
			source: source,
		)
		return Dictionary(uniqueKeysWithValues: catalog.entries.map { entry in
			(entry.post?.relativePath ?? "bundle \(entry.slug!)", entry.state)
		})
	}

	@Test("A post without a status stays in the vault")
	func vaultOnly() throws {
		#expect(try states(posts: [post(nil, status: nil)]) == ["Blog Posts/untitled.md": .vaultOnly])
	}

	@Test("A valid post without a bundle is new")
	func new() throws {
		#expect(try states(posts: [post("a")]) == ["Blog Posts/a.md": .new])
	}

	@Test("A bundle that matches the vault is up to date")
	func upToDate() throws {
		let post = try post("a")
		#expect(try states(posts: [post], bundles: [bundle(for: post)]) == ["Blog Posts/a.md": .upToDate])
	}

	@Test("A bundle from an older version of the note is stale")
	func stale() throws {
		let old = try post("a", body: "# Title\n\nOld body.")
		let new = try post("a", body: "# Title\n\nNew body.")
		#expect(try states(posts: [new], bundles: [bundle(for: old)]) == ["Blog Posts/a.md": .stale])
	}

	@Test("A bundle changed after the last sync is edited")
	func edited() throws {
		let old = try post("a", body: "# Title\n\nOld body.")
		let new = try post("a", body: "# Title\n\nNew body.")
		let handEdited = try bundle(for: old) { $0["icon.png"] = Data([1]) }
		#expect(try states(posts: [new], bundles: [handEdited]) == ["Blog Posts/a.md": .edited])
	}

	@Test("A hand edit later copied into the vault is up to date, with a hash to refresh")
	func editCopiedIntoVault() throws {
		let old = try post("a", body: "# Title\n\nOld body.")
		let new = try post("a", body: "# Title\n\nNew body.")
		let generatedNew = try bundle(for: new)
		let handEdited = try bundle(for: old) { files in
			files["index.md"] = generatedNew.bundle.files["index.md"]!
			let text = String(decoding: files["index.md"]!, as: UTF8.self)
			files["index.md"] = Data(text.replacing(/generatedHash: "[^"]*"/, with: #"generatedHash: "sha256:old""#).utf8)
		}

		let catalog = try Catalog.classify(posts: [new], bundles: ["a": handEdited], source: source)
		#expect(catalog.entries.map(\.state) == [.upToDate])
		#expect(catalog.entries[0].needsHashRefresh)
	}

	@Test("A bundle ths didn't make is a conflict")
	func conflict() throws {
		let post = try post("a")
		let handMade = bundle("a", files: ["index.md": Data("---\ntitle: A\n---\n".utf8)], vaultSource: nil, isDraft: false)
		#expect(try states(posts: [post], bundles: [handMade]) == ["Blog Posts/a.md": .conflict])
	}

	@Test("Bundles no post claims are orphaned, and unmanaged ones are ignored")
	func orphans() throws {
		let draft = try bundle(for: post("old-draft", status: "draft"))
		let published = try bundle(for: post("old-post"))
		let handMade = bundle("hand-made", files: ["index.md": Data()], vaultSource: nil, isDraft: false)

		#expect(try states(posts: [], bundles: [draft, published, handMade]) == [
			"bundle old-draft": .orphanedDraft,
			"bundle old-post": .orphanedPublished,
		])
	}

	@Test("A post moved back to the vault orphans its bundle")
	func backToVault() throws {
		let published = try post("a")
		let vaultOnly = try post("a", status: nil)
		#expect(try states(posts: [vaultOnly], bundles: [bundle(for: published)]) == [
			"Blog Posts/a.md": .vaultOnly,
			"bundle a": .orphanedPublished,
		])
	}

	@Test("A published post set back to draft is retracted")
	func retracted() throws {
		let published = try post("a")
		let draft = try post("a", status: "draft")
		#expect(try states(posts: [draft], bundles: [bundle(for: published)]) == ["Blog Posts/a.md": .retracted])
	}

	@Test("An invalid post still claims its slug, so its bundle isn't orphaned")
	func invalidClaimsSlug() throws {
		let valid = try post("a")
		let broken = try post("a", body: "No title.")
		#expect(try states(posts: [broken], bundles: [bundle(for: valid)]) == ["Blog Posts/a.md": .invalid])
	}

	@Test("Two posts with the same slug are both invalid")
	func duplicateSlugs() throws {
		let first = try post("a", path: "Blog Posts/First.md")
		let second = try post("a", path: "Blog Posts/Second.md")
		let catalog = try Catalog.classify(posts: [first, second], bundles: [:], source: source)

		#expect(catalog.entries.map(\.state) == [.invalid, .invalid])
		#expect(catalog.entries[0].issues == [.duplicateSlug(otherPath: "Blog Posts/Second.md")])
	}

	@Test("A draft's TODO is a warning, and a published post's is a problem")
	func todoWarnings() throws {
		let draft = try post("a", status: "draft", body: "# T\n\nTODO: finish")
		let published = try post("b", body: "# T\n\nTODO: finish")
		let catalog = try Catalog.classify(posts: [draft, published], bundles: [:], source: source)

		#expect(catalog.entries.map(\.state) == [.new, .invalid])
		#expect(catalog.entries[0].warnings == [.todo(line: 9)])
		#expect(catalog.entries[1].issues == [.todo(line: 9)])
	}
}
