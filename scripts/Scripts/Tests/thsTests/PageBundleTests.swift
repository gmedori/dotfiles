import Foundation
import Testing
@testable import ths

@Suite("page bundles")
struct PageBundleTests {
	func post(status: String = "published") throws -> BlogPost {
		try #require(BlogPost.parse(
			"""
			---
			type: blog post
			status: \(status)
			slug: a-post
			date: 2025-03-31
			description: "Quotes \\" and colons: fine."
			tags:
			  - App Development
			---
			# A "Quoted" Title

			Body.
			""",
			relativePath: "Blog Posts/A Post.md",
		))
	}

	func generate(status: String = "published") throws -> PageBundle {
		let post = try post(status: status)
		let body = BodyConverter(noteDirectory: URL(filePath: "/vault")).convert(post.body, startLine: post.bodyStartLine)
		return try PageBundle.generate(for: post, body: body)
	}

	func index(of bundle: PageBundle) throws -> String {
		String(decoding: try #require(bundle.files["index.md"]), as: UTF8.self)
	}

	@Test("Writes Hugo front matter with the vault source and hash under params")
	func writesFrontMatter() throws {
		let bundle = try generate()
		let hash = PageBundle.contentHash(of: bundle.files)

		#expect(try index(of: bundle) == """
		---
		title: "A \\"Quoted\\" Title"
		slug: "a-post"
		date: 2025-03-31
		draft: false
		description: "Quotes \\" and colons: fine."
		tags:
		  - "App Development"
		params:
		  vaultSource: "$THS_SOURCE_DIR/Blog Posts/A Post.md"
		  generatedHash: "\(hash)"
		---

		Body.

		""")
	}

	@Test("Marks drafts as drafts")
	func marksDrafts() throws {
		#expect(try index(of: generate(status: "draft")).contains("\ndraft: true\n"))
	}

	@Test("Hashes the same whatever hash the index stores")
	func hashIgnoresStoredHash() throws {
		let bundle = try generate()
		var files = bundle.files
		let index = try index(of: bundle).replacing(/generatedHash: "[^"]*"/, with: #"generatedHash: "sha256:stale""#)
		files["index.md"] = Data(index.utf8)

		#expect(PageBundle.contentHash(of: files) == PageBundle.contentHash(of: bundle.files))
	}

	@Test("Hashes differently when any file changes or is added")
	func hashCoversEveryFile() throws {
		let bundle = try generate()
		var edited = bundle.files
		edited["index.md"] = Data((try index(of: bundle) + "An edit.\n").utf8)
		var added = bundle.files
		added["icon.png"] = Data([1, 2, 3])

		let original = PageBundle.contentHash(of: bundle.files)
		#expect(PageBundle.contentHash(of: edited) != original)
		#expect(PageBundle.contentHash(of: added) != original)
	}

	@Test("Reads a generated bundle back as managed and unchanged")
	func readsGeneratedBundle() throws {
		let bundle = try generate()
		let directory = FileManager.default.temporaryDirectory.appending(path: "ths-tests-\(UUID().uuidString)/a-post")
		try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
		defer { try? FileManager.default.removeItem(at: directory.deletingLastPathComponent()) }
		for (name, data) in bundle.files {
			try data.write(to: directory.appending(path: name))
		}
		try Data().write(to: directory.appending(path: ".DS_Store"))

		let existing = try ExistingBundle.read(from: directory)

		#expect(existing.slug == "a-post")
		#expect(existing.isManaged)
		#expect(!existing.isDraft)
		#expect(existing.vaultSource == "$THS_SOURCE_DIR/Blog Posts/A Post.md")
		#expect(existing.matchesStoredHash)
		#expect(existing.bundle == bundle)
	}
}
