import Testing
@testable import ths

@Suite("frontmatter values")
struct FrontmatterTests {
	func frontmatter(_ yaml: String) throws -> Frontmatter {
		try #require(try Frontmatter.parse("---\n\(yaml)\n---\nBody"))
	}

	@Test(
		"Reads `true` and `false` as booleans in lowercase, capitalized, or all caps",
		arguments: [("true", true), ("True", true), ("TRUE", true), ("false", false), ("False", false), ("FALSE", false)],
	)
	func readsBooleans(value: String, expected: Bool) throws {
		#expect(try frontmatter("draft: \(value)").bool("draft") == expected)
	}

	@Test(
		"Reads other spellings Hugo or YAML 1.1 might take as true as something other than a boolean",
		arguments: ["yes", "on", "tRuE", "1", "t", #""true""#, "'true'"],
	)
	func rejectsOtherBooleans(value: String) throws {
		#expect(try frontmatter("draft: \(value)").bool("draft") == nil)
	}

	@Test("Reads an empty value, `~`, or `null` without quotes as missing", arguments: ["", " ~", " null", " Null", " NULL"])
	func readsNull(value: String) throws {
		let frontmatter = try frontmatter("slug:\(value)\ntags:\(value)")
		#expect(frontmatter.string("slug") == nil)
		#expect(frontmatter.strings("tags") == [])
	}

	@Test("Keeps quoted null spellings as text")
	func keepsQuotedNull() throws {
		let frontmatter = try frontmatter(#"slug: "null""# + "\ndescription: ''")
		#expect(frontmatter.string("slug") == "null")
		#expect(frontmatter.string("description") == "")
	}
}
