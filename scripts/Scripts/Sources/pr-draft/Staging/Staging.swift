import CommandKit
import Foundation

/// Stages a draft's attachments and body for `create`, in a folder of their own.
enum Staging {
	/// GitHub's size limit for an image, in bytes.
	static let imageSizeLimit = 10 * 1024 * 1024
	/// GitHub's size limit for a video, in bytes.
	static let videoSizeLimit = 100 * 1024 * 1024
	/// The bytes in a megabyte, for the warnings about size limits.
	static let bytesPerMegabyte = 1_048_576
	/// The staged body's file name.
	static let bodyFileName = "body.md"
	/// The file name `prepare` saves what it found as, which `create` reads.
	static let manifestFileName = "manifest.json"

	/// The default staging folder for a draft, under the system temp folder.
	static func directory(for draft: URL) -> URL {
		let name = BodyRewriter.slug(draft.deletingPathExtension().lastPathComponent, limit: 80)
		return FileManager.default
			.temporaryDirectory
			.appending(path: "pr-draft", directoryHint: .isDirectory)
			.appending(path: name, directoryHint: .isDirectory)
	}

	/// Reads the draft, replaces the staging folder with a fresh one, and copies the attachments,
	/// `body.md`, and nothing else into it. It doesn't save the manifest, since `prepare` adds
	/// whether `gh` can attach files first.
	static func prepare(
		draft draftFile: URL,
		altOverrides: [Int: String],
		stageDirectory: URL,
	) throws -> PreparedDraft {
		guard let vault = VaultFiles.containing(draftFile) else {
			throw RuntimeError("\(draftFile.path(percentEncoded: false)) isn't in an Obsidian vault.")
		}

		let draft = try Draft.parse(String(contentsOf: draftFile, encoding: .utf8))

		var errors: [String] = []
		let missing = draft.missingProperties
		if !missing.isEmpty {
			errors.append("The frontmatter is missing \(list(missing.map { "`\($0)`" })).")
		}
		if draft.title == nil {
			errors.append("The draft has no title line starting with `# `.")
		}

		let rewriter = BodyRewriter(
			noteDirectory: draftFile.resolvingSymlinksInPath().deletingLastPathComponent(),
			vault: vault,
			altOverrides: altOverrides,
		)
		let result = rewriter.rewrite(draft.bodyLines, startLine: draft.bodyStartLine)
		errors += result.errors
		let unknown = Set(altOverrides.keys).subtracting(result.attachments.map(\.number)).sorted()
		if !unknown.isEmpty {
			let numbers = list(unknown.map { "\($0)" })
			errors.append("`--alt` gives alt text for \(numbers), but the body has no attachment with that number.")
		}

		let fileManager = FileManager.default
		if fileManager.fileExists(atPath: stageDirectory.path(percentEncoded: false)) {
			try fileManager.removeItem(at: stageDirectory)
		}
		try fileManager.createDirectory(at: stageDirectory, withIntermediateDirectories: true)

		var warnings: [String] = []
		for (attachment, source) in zip(result.attachments, result.sources) {
			try fileManager.copyItem(
				at: source,
				to: stageDirectory.appending(path: String(attachment.staged.dropFirst(2))),
			)
			let attributes = try fileManager.attributesOfItem(atPath: source.path(percentEncoded: false))
			let size = attributes[.size] as? Int ?? 0
			let limit = attachment.kind == .video ? videoSizeLimit : imageSizeLimit
			if size > limit {
				let megabytes = String(format: "%.1f", Double(size) / Double(bytesPerMegabyte))
				let limitInMegabytes = limit / bytesPerMegabyte
				let kind = attachment.kind == .video ? "a video" : "an image"
				warnings.append(
					"`\(attachment.source)` is \(megabytes) MB, over GitHub's \(limitInMegabytes) MB limit for \(kind)."
				)
			}
		}

		let bodyFile = stageDirectory.appending(path: bodyFileName)
		try result.body.write(to: bodyFile, atomically: true, encoding: .utf8)

		return PreparedDraft(
			ok: errors.isEmpty,
			errors: errors,
			warnings: warnings,
			placeholders: result.placeholders,
			needsAlt: result.attachments.filter { $0.kind == .image && $0.alt == nil }.map(\.number),
			repo: draft.repo,
			base: draft.base,
			branch: draft.branch,
			title: draft.title,
			attachments: result.attachments,
			stageDir: stageDirectory.path(percentEncoded: false),
			bodyFile: bodyFile.path(percentEncoded: false),
		)
	}

	/// Saves `prepared` as the manifest in its staging folder.
	static func saveManifest(_ prepared: PreparedDraft) throws {
		let file = URL(filePath: prepared.stageDir, directoryHint: .isDirectory).appending(path: manifestFileName)
		try JSON.encode(prepared).write(to: file, atomically: true, encoding: .utf8)
	}

	/// Reads the manifest that `prepare` saved in `stageDirectory`.
	static func loadManifest(from stageDirectory: URL) throws -> PreparedDraft {
		let file = stageDirectory.appending(path: manifestFileName)
		guard let data = FileManager.default.contents(atPath: file.path(percentEncoded: false)) else {
			throw RuntimeError(
				"There's no \(manifestFileName) in \(stageDirectory.path(percentEncoded: false)). Run `pr-draft prepare` first."
			)
		}

		return try JSON.decoder().decode(PreparedDraft.self, from: data)
	}

	/// The items as an English list, like "`repo`, `branch`, and `base`".
	static func list(_ items: [String]) -> String {
		switch items.count {
			case 0: ""
			case 1: items[0]
			case 2: "\(items[0]) and \(items[1])"
			default: items.dropLast().joined(separator: ", ") + ", and " + items[items.count - 1]
		}
	}
}
