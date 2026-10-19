import Testing
@testable import ths

@Suite("blog post frontmatter")
struct BlogPostTests {
	@Test("Reads a published post's properties")
	func readsPublishedPost() throws {
		let post = try #require(BlogPost.parse(
			"""
			---
			type: blog post
			status: published
			slug: one-is-not-none-preorder-is-live
			date: 2025-03-31
			description: "Preorders are live: the app ships April 7."
			tags:
			  - App Development
			  - One Is Not None
			---
			# One Is Not None Preorder Is Live!

			The title says it all.
			""",
			relativePath: "Blog Posts/Preorder.md",
		))

		#expect(post.status == .published)
		#expect(post.slug == "one-is-not-none-preorder-is-live")
		#expect(post.date == "2025-03-31")
		#expect(post.description == "Preorders are live: the app ships April 7.")
		#expect(post.tags == ["App Development", "One Is Not None"])
		#expect(post.body == "# One Is Not None Preorder Is Live!\n\nThe title says it all.")
		#expect(post.bodyStartLine == 11)
		#expect(post.issues.isEmpty)
	}

	@Test("Skips notes that aren't blog posts")
	func skipsOtherNotes() {
		#expect(BlogPost.parse("# Just a note", relativePath: "Note.md") == nil)
		#expect(BlogPost.parse("---\ntype: quest\n---\nBody", relativePath: "Quest.md") == nil)
		#expect(BlogPost.parse("---\nstatus: published\n---\nBody", relativePath: "Untyped.md") == nil)
	}

	@Test("Keeps a post without a status in the vault, unchecked")
	func vaultOnlyPostIsUnchecked() throws {
		let post = try #require(BlogPost.parse("---\ntype: blog post\nstatus:\n---\nIdea", relativePath: "Idea.md"))

		#expect(post.status == nil)
		#expect(post.issues.isEmpty)
	}

	@Test("Requires a slug on drafts and a date on published posts")
	func requiresSlugAndDate() throws {
		let draft = try #require(BlogPost.parse("---\ntype: blog post\nstatus: draft\n---\n", relativePath: "D.md"))
		let published = try #require(BlogPost.parse(
			"---\ntype: blog post\nstatus: published\nslug: a-post\n---\n",
			relativePath: "P.md",
		))

		#expect(draft.issues == [.missingSlug])
		#expect(published.issues == [.missingDate])
	}

	@Test("Reads canceled, which doesn't need a slug")
	func readsCanceled() throws {
		let post = try #require(BlogPost.parse("---\ntype: blog post\nstatus: canceled\n---\n", relativePath: "C.md"))

		#expect(post.status == .canceled)
		#expect(post.issues.isEmpty)
	}

	@Test("Rejects bad values")
	func rejectsBadValues() throws {
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

	@Test("Reports unreadable frontmatter on a note that says it's a blog post")
	func reportsUnreadableFrontmatter() throws {
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

	@Test("Keeps a quoted date as text")
	func keepsQuotedDate() throws {
		let post = try #require(BlogPost.parse(
			"---\ntype: blog post\nstatus: draft\nslug: a\ndate: '2025-03-03'\n---\n",
			relativePath: "Q.md",
		))

		#expect(post.date == "2025-03-03")
		#expect(post.issues.isEmpty)
	}
}
