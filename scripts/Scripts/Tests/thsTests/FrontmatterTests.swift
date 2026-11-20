import Testing
@testable import ths

struct `frontmatter values` {
	func frontmatter(_ yaml: String) throws -> Frontmatter {
		try #require(try Frontmatter.parse("---\n\(yaml)\n---\nBody"))
	}

	@Test(
		arguments: [
			("true", true),
			("True", true),
			("TRUE", true),
			("false", false),
			("False", false),
			("FALSE", false),
		]
	)
	func `Reads true and false as booleans in lowercase, capitalized, or all caps`(
		value: String,
		expected: Bool,
	) throws {
		#expect(try frontmatter("draft: \(value)").bool("draft") == expected)
	}

	@Test(
		arguments: ["yes", "on", "tRuE", "1", "t", #""true""#, "'true'"]
	)
	func `Reads other spellings Hugo or YAML 1.1 might take as true as something other than a boolean`(
		value: String
	) throws {
		#expect(try frontmatter("draft: \(value)").bool("draft") == nil)
	}

	@Test(arguments: ["", " ~", " null", " Null", " NULL"])
	func `Reads an empty value, ~, or null without quotes as missing`(value: String) throws {
		let frontmatter = try frontmatter("slug:\(value)\ntags:\(value)")
		#expect(frontmatter.string("slug") == nil)
		#expect(frontmatter.strings("tags") == [])
	}

	@Test
	func `Keeps quoted null spellings as text`() throws {
		let frontmatter = try frontmatter(#"slug: "null""# + "\ndescription: ''")
		#expect(frontmatter.string("slug") == "null")
		#expect(frontmatter.string("description") == "")
	}
}
