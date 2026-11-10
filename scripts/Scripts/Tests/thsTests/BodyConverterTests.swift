import Foundation
import Testing
@testable import ths

@Suite("body conversion")
struct BodyConverterTests {
	let noteDirectory = URL(filePath: "/vault/Blog Posts", directoryHint: .isDirectory)

	/// A converter that sees only the given files in the note's assets folder.
	func converter(assets: Set<String> = []) -> BodyConverter {
		let assetsPath = noteDirectory.appending(path: "assets").path(percentEncoded: false)
		var converter = BodyConverter(noteDirectory: noteDirectory)
		converter.fileExists = { url in
			let path = url.standardizedFileURL.path(percentEncoded: false)
			return assets.contains { path == "\(assetsPath)/\($0)" }
		}
		return converter
	}

	@Test("Lifts the H1 into the title and passes the rest through")
	func liftsTitle() {
		let result = converter().convert(
			"# Introducing: The Goose Tracker\n\nA made-up post about geese.\n\n## Why?\n\n1. Honking\n",
			startLine: 5,
		)

		#expect(result.title == "Introducing: The Goose Tracker")
		#expect(result.markdown == "A made-up post about geese.\n\n## Why?\n\n1. Honking\n")
		#expect(result.issues.isEmpty)
	}

	@Test("Requires the title to come first")
	func requiresLeadingTitle() {
		let result = converter().convert("> A quote first.\n\n# Section\n", startLine: 1)

		#expect(result.title == nil)
		#expect(result.issues == [.missingTitle, .extraTitle(line: 3)])
	}

	@Test("Converts an embed and folds the italic line under it into a caption")
	func convertsEmbedWithCaption() {
		let result = converter(assets: ["3-Goose Pond Map.png"]).convert(
			"""
			# Title

			Intro.

			![[3-Goose Pond Map.png|A map of the pond]]

			_The pond where the geese gather in spring._

			## Next
			""",
			startLine: 1,
		)

		#expect(result.markdown == """
		Intro.

		![A map of the pond](3-goose-pond-map.png "The pond where the geese gather in spring.")

		## Next

		""")
		#expect(result.images == [BundleImage(
			source: noteDirectory.appending(path: "assets/3-Goose Pond Map.png"),
			name: "3-goose-pond-map.png",
		)])
		#expect(result.issues.isEmpty)
	}

	@Test("Reports an embed without alt text, and ignores a display size")
	func reportsMissingAltText() {
		let result = converter(assets: ["shot.png"]).convert("# T\n\n![[shot.png|300]]\n", startLine: 1)

		#expect(result.markdown == "![](shot.png)\n")
		#expect(result.issues == [.missingAltText(name: "shot.png", line: 3)])
	}

	@Test("Converts a linked HTML image into a linked Markdown image")
	func convertsLinkedImage() {
		let result = converter(assets: ["Download Badge.png"]).convert(
			"""
			# Download

			<a href="https://example.com/goose-tracker"><img src="assets/Download%20Badge.png" alt="Download the Goose Tracker"></a>

			A made-up closing line.
			""",
			startLine: 1,
		)

		#expect(result.markdown == """
		[![Download the Goose Tracker](download-badge.png)](https://example.com/goose-tracker)

		A made-up closing line.

		""")
		#expect(result.issues.isEmpty)
	}

	@Test("Points a Markdown image at the bundle copy and keeps its title")
	func convertsMarkdownImage() {
		let result = converter(assets: ["icon.png"]).convert(
			"# T\n\n![The app icon](assets/icon.png \"The default icon.\")\n\n_Not a caption, the image has a title._\n",
			startLine: 1,
		)

		#expect(result.markdown == "![The app icon](icon.png \"The default icon.\")\n\n_Not a caption, the image has a title._\n")
	}

	@Test("Removes comments, including whole-line and multiline ones")
	func removesComments() {
		let result = converter().convert(
			"# T\n\nKeep %%drop%% this.\n%%whole line%%\n%%\nspans\nlines\n%%\nEnd.\n",
			startLine: 1,
		)

		#expect(result.markdown == "Keep  this.\nEnd.\n")
	}

	@Test("Leaves code alone")
	func leavesCodeAlone() {
		let result = converter().convert(
			"""
			# T

			Use `[[wiki]]` and `<div>` freely in code.

			```swift
			// TODO: not a real TODO
			let html = "<div>"
			```
			""",
			startLine: 1,
		)

		#expect(result.issues.isEmpty)
		#expect(result.markdown.contains("// TODO: not a real TODO"))
	}

	@Test("Keeps autolinks, which look like HTML but aren't")
	func keepsAutolinks() {
		let result = converter().convert(
			"# T\n\nJoin at <https://example.com/join> or email <someone@example.com>.\n",
			startLine: 1,
		)

		#expect(result.issues.isEmpty)
	}

	@Test("Reports what the site can't show, with note line numbers")
	func reportsUnsupportedSyntax() {
		let result = converter().convert(
			"""
			# T

			See [[Another Note]].
			> [!note] A callout
			This is ==highlighted==.
			<span>raw</span>
			// TODO: finish
			![[missing.png|Alt]]
			![Remote](https://example.com/a.png)
			![[Some Note]]
			""",
			startLine: 10,
		)

		#expect(result.issues == [
			.wikiLink("Another Note", line: 12),
			.callout(line: 13),
			.highlight(line: 14),
			.html(tag: "span", line: 15),
			.html(tag: "span", line: 15),
			.todo(line: 16),
			.missingImage(name: "missing.png", line: 17),
			.remoteImage(url: "https://example.com/a.png", line: 18),
			.wikiLink("Some Note", line: 19),
		])
	}

	@Test("Reports two images that would share a bundle name")
	func reportsDuplicateImageNames() {
		var converter = BodyConverter(noteDirectory: noteDirectory)
		converter.fileExists = { _ in true }
		let result = converter.convert("# T\n\n![A](one/Photo.png)\n![B](two/photo.png)\n", startLine: 1)

		#expect(result.issues == [.duplicateImageName(name: "photo.png", line: 4)])
	}

	@Test("Only TODOs, extra H1s, alt text, and remote images are warnings on drafts")
	func draftWarnings() {
		#expect(!PostIssue.todo(line: 1).blocksDrafts)
		#expect(!PostIssue.extraTitle(line: 1).blocksDrafts)
		#expect(!PostIssue.missingAltText(name: "a", line: 1).blocksDrafts)
		#expect(!PostIssue.remoteImage(url: "a", line: 1).blocksDrafts)
		#expect(PostIssue.wikiLink("a", line: 1).blocksDrafts)
		#expect(PostIssue.missingTitle.blocksDrafts)
	}
}
