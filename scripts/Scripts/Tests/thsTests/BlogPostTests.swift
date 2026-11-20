import Testing
@testable import ths

struct `blog post frontmatter` {
	@Test
	func `Reads a published post's properties`() throws {
		let post = try #require(BlogPost.parse(
			"""
			---
			type: blog post
			status: published
			slug: a-field-guide-to-geese
			date: 2026-01-15
			description: "Geese: a field guide in one post."
			tags:
			  - Birds
			  - Field Notes
			---
			# A Field Guide to Geese

			Honk.
			""",
			relativePath: "Blog Posts/Geese.md",
		))

		#expect(post.status == .published)
		#expect(post.slug == "a-field-guide-to-geese")
		#expect(post.date == "2026-01-15")
		#expect(post.description == "Geese: a field guide in one post.")
		#expect(post.tags == ["Birds", "Field Notes"])
		#expect(post.body == "# A Field Guide to Geese\n\nHonk.")
		#expect(post.bodyStartLine == 11)
		#expect(post.issues.isEmpty)
	}

	@Test
	func `Skips notes that aren't blog posts`() {
		#expect(BlogPost.parse("# Just a note", relativePath: "Note.md") == nil)
		#expect(BlogPost.parse("---\ntype: quest\n---\nBody", relativePath: "Quest.md") == nil)
		#expect(BlogPost.parse("---\nstatus: published\n---\nBody", relativePath: "Untyped.md") == nil)
	}

	@Test
	func `Keeps a post without a status in the vault, unchecked`() throws {
		let post = try #require(BlogPost.parse("---\ntype: blog post\nstatus:\n---\nIdea", relativePath: "Idea.md"))

		#expect(post.status == nil)
		#expect(post.issues.isEmpty)
	}

	@Test
	func `Requires a slug on drafts and a date on published posts`() throws {
		let draft = try #require(BlogPost.parse("---\ntype: blog post\nstatus: draft\n---\n", relativePath: "D.md"))
		let published = try #require(BlogPost.parse(
			"---\ntype: blog post\nstatus: published\nslug: a-post\n---\n",
			relativePath: "P.md",
		))

		#expect(draft.issues == [.missingSlug])
		#expect(published.issues == [.missingDate])
	}

	@Test
	func `Reads canceled, which doesn't need a slug`() throws {
		let post = try #require(BlogPost.parse("---\ntype: blog post\nstatus: canceled\n---\n", relativePath: "C.md"))

		#expect(post.status == .canceled)
		#expect(post.issues.isEmpty)
	}

	@Test
	func `Rejects bad values`() throws {
		let post = try #require(BlogPost.parse(
			"""
			---
			type: blog post
			status: active
			slug: My Post
			date: 2025-02-30
			tags:
			  - nested:
			      list: true
			---
			""",
			relativePath: "Bad.md",
		))

		#expect(post.issues == [
			.invalidStatus("active"),
			.invalidSlug("My Post"),
			.invalidDate("2025-02-30"),
			.invalidProperty(name: "tags", expected: "a list of tags"),
		])
	}

	@Test
	func `Reports unreadable frontmatter on a note that says it's a blog post`() throws {
		let post = try #require(BlogPost.parse(
			"---\ntype: blog post\ndescription: [unclosed\n---\nBody",
			relativePath: "Broken.md",
		))

		#expect(post.issues.count == 1)
		guard case .invalidFrontmatter = post.issues.first else {
			Issue.record("Expected invalidFrontmatter, got \(post.issues)")
			return
		}
	}

	@Test
	func `Keeps a quoted date as text`() throws {
		let post = try #require(BlogPost.parse(
			"---\ntype: blog post\nstatus: draft\nslug: a\ndate: '2025-03-03'\n---\n",
			relativePath: "Q.md",
		))

		#expect(post.date == "2025-03-03")
		#expect(post.issues.isEmpty)
	}
}
