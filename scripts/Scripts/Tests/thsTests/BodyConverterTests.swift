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
			"# Announcing: One Is Not None\n\nI'm really excited.\n\n## Why?\n\n1. Reliable\n",
			startLine: 5,
		)

		#expect(result.title == "Announcing: One Is Not None")
		#expect(result.markdown == "I'm really excited.\n\n## Why?\n\n1. Reliable\n")
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
		let result = converter(assets: ["4-Player Layout Horizontal.png"]).convert(
			"""
			# Title

			Intro.

			![[4-Player Layout Horizontal.png|Four life counters]]

			_The standard four-player layout for a game of Commander._

			## Next
			""",
			startLine: 1,
		)

		#expect(result.markdown == """
		Intro.

		![Four life counters](4-player-layout-horizontal.png "The standard four-player layout for a game of Commander.")

		## Next

		""")
		#expect(result.images == [BundleImage(
			source: noteDirectory.appending(path: "assets/4-Player Layout Horizontal.png"),
			name: "4-player-layout-horizontal.png",
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
		let result = converter(assets: ["Pre-order Badge.png"]).convert(
			"""
			# Preorder

			<a href="https://apps.apple.com/us/app/one-is-not-none/id6742521253"><img src="assets/Pre-order%20Badge.png" alt="Pre-order on the App Store"></a>

			The title says it all.
			""",
			startLine: 1,
		)

		#expect(result.markdown == """
		[![Pre-order on the App Store](pre-order-badge.png)](https://apps.apple.com/us/app/one-is-not-none/id6742521253)

		The title says it all.

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
			"# T\n\nJoin at <https://testflight.apple.com/join/bRxMengR> or email <feedback@thehonkingsmith.com>.\n",
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
