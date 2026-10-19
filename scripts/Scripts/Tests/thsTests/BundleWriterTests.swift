import Foundation
import Testing
@testable import ths

@Suite("bundle writer")
struct BundleWriterTests {
	@Test("Makes the folder hold exactly the bundle's files, keeping .DS_Store")
	func replacesFiles() throws {
		let site = FileManager.default.temporaryDirectory.appending(path: "ths-tests-\(UUID().uuidString)")
		let directory = site.appending(path: "content/blog/a-post")
		try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
		defer { try? FileManager.default.removeItem(at: site) }
		try Data("old".utf8).write(to: directory.appending(path: "index.md"))
		try Data("stray".utf8).write(to: directory.appending(path: "icon.png"))
		try Data().write(to: directory.appending(path: ".DS_Store"))

		let writer = BundleWriter(siteDirectory: site)
		try writer.write(PageBundle(files: ["index.md": Data("new".utf8), "photo.png": Data([1])]), slug: "a-post")

		let names = try FileManager.default.contentsOfDirectory(atPath: directory.path(percentEncoded: false)).sorted()
		#expect(names == [".DS_Store", "index.md", "photo.png"])
		#expect(try Data(contentsOf: directory.appending(path: "index.md")) == Data("new".utf8))

		try writer.delete(slug: "a-post")
		#expect(!FileManager.default.fileExists(atPath: directory.path(percentEncoded: false)))
	}
}
