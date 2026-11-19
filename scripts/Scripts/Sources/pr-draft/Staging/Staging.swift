import CommandKit
import Foundation

// MARK: - Prepared Draft

/// What `prepare` found in a draft. `prepare` prints it as JSON and saves it in the staging folder
/// as `manifest.json`.
struct PreparedDraft: Codable, Equatable, Sendable {
	/// Whether `errors` is empty.
	let ok: Bool
	/// Missing frontmatter, a missing title, and every embed that can't be staged, as sentences.
	let errors: [String]
	/// Files over GitHub's size limits, as sentences.
	let warnings: [String]
	/// The label of each `<!-- TODO: … -->` placeholder in the body.
	let placeholders: [String]
	/// The numbers of the images that have no alt text.
	let needsAlt: [Int]
	let repo: String?
	let base: String?
	let branch: String?
	let title: String?
	let attachments: [Attachment]
	/// The staging folder, which holds the copies, `body.md`, and `manifest.json`.
	let stageDir: String
	/// The staged body, which is the draft's body with each embed pointing at its copy.
	let bodyFile: String
	/// Whether the installed `gh` has `--attach`. It's only checked when there are attachments.
	var ghSupportsAttach: Bool?
}

// MARK: - Staging

enum Staging {
	static let imageSizeLimit = 10 * 1024 * 1024
	static let videoSizeLimit = 100 * 1024 * 1024
	static let bodyFileName = "body.md"
	static let manifestFileName = "manifest.json"

	/// The default staging folder for a draft, under the system temp folder.
	static func directory(for draft: URL) -> URL {
		let name = BodyRewriter.slug(draft.deletingPathExtension().lastPathComponent, limit: 80)
		return FileManager.default.temporaryDirectory
			.appending(path: "pr-draft", directoryHint: .isDirectory)
			.appending(path: name, directoryHint: .isDirectory)
	}

	/// Reads the draft, replaces the staging folder with a fresh one, and copies the attachments,
	/// `body.md`, and nothing else into it. It doesn't save the manifest, since `prepare` adds
	/// whether `gh` can attach files first.
	static func prepare(draft draftFile: URL, altOverrides: [Int: String], stageDirectory: URL) throws -> PreparedDraft {
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
			errors.append("`--alt` gives alt text for \(list(unknown.map { "\($0)" })), but the body has no attachment with that number.")
		}

		let fileManager = FileManager.default
		if fileManager.fileExists(atPath: stageDirectory.path(percentEncoded: false)) {
			try fileManager.removeItem(at: stageDirectory)
		}
		try fileManager.createDirectory(at: stageDirectory, withIntermediateDirectories: true)

		var warnings: [String] = []
		for (attachment, source) in zip(result.attachments, result.sources) {
			try fileManager.copyItem(at: source, to: stageDirectory.appending(path: String(attachment.staged.dropFirst(2))))
			let size = (try fileManager.attributesOfItem(atPath: source.path(percentEncoded: false))[.size] as? Int) ?? 0
			let limit = attachment.kind == .video ? videoSizeLimit : imageSizeLimit
			if size > limit {
				let megabytes = String(format: "%.1f", Double(size) / 1_048_576)
				let kind = attachment.kind == .video ? "a video" : "an image"
				warnings.append("`\(attachment.source)` is \(megabytes) MB, over GitHub's \(limit / 1_048_576) MB limit for \(kind).")
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

	static func saveManifest(_ prepared: PreparedDraft) throws {
		let file = URL(filePath: prepared.stageDir, directoryHint: .isDirectory).appending(path: manifestFileName)
		try JSON.encode(prepared).write(to: file, atomically: true, encoding: .utf8)
	}

	static func loadManifest(from stageDirectory: URL) throws -> PreparedDraft {
		let file = stageDirectory.appending(path: manifestFileName)
		guard let data = FileManager.default.contents(atPath: file.path(percentEncoded: false)) else {
			throw RuntimeError("There's no \(manifestFileName) in \(stageDirectory.path(percentEncoded: false)). Run `pr-draft prepare` first.")
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

// MARK: - JSON

/// The JSON that `prepare` prints, with snake_case keys.
enum JSON {
	static func encode(_ value: some Encodable) throws -> String {
		let encoder = JSONEncoder()
		encoder.keyEncodingStrategy = .convertToSnakeCase
		encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
		return String(decoding: try encoder.encode(value), as: UTF8.self)
	}

	static func decoder() -> JSONDecoder {
		let decoder = JSONDecoder()
		decoder.keyDecodingStrategy = .convertFromSnakeCase
		return decoder
	}
}
