import Foundation
import Testing
@testable import pr_draft

struct `vault link resolution` {
	let vault: TemporaryVault
	let files: VaultFiles
	let drafts: URL

	init() throws {
		self.vault = try TemporaryVault()
		try vault.write("Teleport/PR Drafts/assets/Pasted image 1.png")
		try vault.write("Teleport/PR Drafts/assets/shared.png")
		try vault.write("Teleport/Images/pathy.png")
		try vault.write("Other/shared.png")
		try vault.write("Other/dup.png")
		try vault.write("More/dup.png")
		try vault.write(".trash/hidden.png")
		try vault.write("Teleport/PR Drafts/draft.md")
		self.files = try #require(VaultFiles.containing(vault.root.appending(path: "Teleport/PR Drafts/draft.md")))
		self.drafts = vault.root.appending(path: "Teleport/PR Drafts", directoryHint: .isDirectory)
	}

	func resolved(_ link: String) -> String? {
		guard case let .found(url) = files.resolve(link, from: drafts) else {
			return nil
		}

		return files.relativePath(of: url)
	}

	@Test
	func `Finds the vault from a note inside it`() {
		#expect(files.root.normalizedPath == vault.root.normalizedPath)
		#expect(VaultFiles.containing(URL(filePath: "/tmp/not-a-vault/note.md")) == nil)
	}

	@Test
	func `Resolves paths from the note's folder and the vault root`() {
		#expect(resolved("./assets/Pasted image 1.png") == "Teleport/PR Drafts/assets/Pasted image 1.png")
		#expect(resolved("assets/Pasted image 1.png") == "Teleport/PR Drafts/assets/Pasted image 1.png")
		#expect(resolved("../Images/pathy.png") == "Teleport/Images/pathy.png")
		#expect(resolved("Teleport/Images/pathy.png") == "Teleport/Images/pathy.png")
		#expect(resolved("/Other/dup.png") == "Other/dup.png")
	}

	@Test
	func `Resolves a file name or the end of a path anywhere in the vault`() {
		#expect(resolved("Pasted image 1.png") == "Teleport/PR Drafts/assets/Pasted image 1.png")
		#expect(resolved("pathy.png") == "Teleport/Images/pathy.png")
		#expect(resolved("Images/pathy.png") == "Teleport/Images/pathy.png")
		#expect(resolved("More/dup.png") == "More/dup.png")
	}

	@Test
	func `Prefers the note's assets folder when a name is shared`() {
		#expect(resolved("shared.png") == "Teleport/PR Drafts/assets/shared.png")
	}

	@Test
	func `Reports names that more than one file has`() {
		guard case let .ambiguous(urls) = files.resolve("dup.png", from: drafts) else {
			Issue.record("dup.png should be ambiguous")
			return
		}

		#expect(urls.map(files.relativePath) == ["More/dup.png", "Other/dup.png"])
	}

	@Test
	func `Reports missing files, including ones in hidden folders`() {
		#expect(files.resolve("missing.png", from: drafts) == .missing)
		#expect(files.resolve("./pathy.png", from: drafts) == .missing)
		#expect(files.resolve("hidden.png", from: drafts) == .missing)
	}
}
