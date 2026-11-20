import Foundation

// MARK: - Vault Files

/// Finds the files that a note's links point at, the way Obsidian resolves them.
///
/// A link that starts with `./` or `../` is a path from the note's folder, and one that starts with
/// `/` is a path from the vault root. Any other link is tried as a path from the note's folder and
/// then from the vault root. When neither exists, it's matched against every file in the vault by
/// file name, or by the end of its path when it has folders. Obsidian writes a bare file name when
/// no other file in the vault has that name, and attachments in this vault are saved to an
/// `assets/` folder beside the note, so a copy there wins when the name is shared.
///
/// Every URL is resolved through symlinks, so paths compare equal however they were reached.
final class VaultFiles {
	/// What a link points at.
	enum Resolution: Equatable {
		case found(URL)
		/// No file matches the link.
		case missing
		/// More than one file in the vault matches the link, sorted by path.
		case ambiguous([URL])
	}

	/// The vault's root, the folder that holds `.obsidian`.
	let root: URL

	/// Every file in the vault by file name, built the first time a link needs it.
	private var filesByName: [String: [URL]]? = nil

	init(root: URL) {
		self.root = root.resolvingSymlinksInPath()
	}

	/// The vault that holds `file`, or `nil` when no folder above it has an `.obsidian` folder.
	static func containing(_ file: URL) -> VaultFiles? {
		var directory = file.resolvingSymlinksInPath().deletingLastPathComponent().path(percentEncoded: false)
		while true {
			var isDirectory: ObjCBool = false
			let marker = (directory as NSString).appendingPathComponent(".obsidian")
			if FileManager.default.fileExists(atPath: marker, isDirectory: &isDirectory), isDirectory.boolValue {
				return VaultFiles(root: URL(filePath: directory, directoryHint: .isDirectory))
			}
			let parent = (directory as NSString).deletingLastPathComponent
			if parent == directory || parent.isEmpty {
				return nil
			}
			directory = parent
		}
	}

	private static func isFile(_ url: URL) -> Bool {
		var isDirectory: ObjCBool = false
		return FileManager.default.fileExists(atPath: url.path(percentEncoded: false), isDirectory: &isDirectory)
			&& !isDirectory.boolValue
	}

	func resolve(_ link: String, from noteDirectory: URL) -> Resolution {
		let noteDirectory = noteDirectory.resolvingSymlinksInPath()
		let isPath = link.hasPrefix("./") || link.hasPrefix("../") || link.hasPrefix("/")
		let candidates: [URL] = if link.hasPrefix("/") {
			[root.appending(path: String(link.dropFirst()))]
		} else if isPath {
			[noteDirectory.appending(path: link)]
		} else {
			[noteDirectory.appending(path: link), root.appending(path: link)]
		}
		if let match = candidates.map(\.standardizedFileURL).first(where: Self.isFile) {
			return .found(match.resolvingSymlinksInPath())
		}
		guard !isPath else {
			return .missing
		}

		let name = (link as NSString).lastPathComponent
		var matches = files(named: name)
		if link.contains("/") {
			matches = matches.filter { $0.path(percentEncoded: false).hasSuffix("/" + link) }
		}
		switch matches.count {
			case 0:
				return .missing
			case 1:
				return .found(matches[0])
			default:
				let besideNote = noteDirectory.appending(path: "assets").appending(path: name).standardizedFileURL
				if
					let match = matches
						.first(where: { $0.path(percentEncoded: false) == besideNote.path(percentEncoded: false) })
				{
					return .found(match)
				}
				return .ambiguous(matches.sorted { $0.path(percentEncoded: false) < $1.path(percentEncoded: false) })
		}
	}

	/// The file's path from the vault root, or its full path when it's outside the vault.
	func relativePath(of file: URL) -> String {
		let path = file.resolvingSymlinksInPath().path(percentEncoded: false)
		var rootPath = root.path(percentEncoded: false)
		if !rootPath.hasSuffix("/") {
			rootPath += "/"
		}
		return path.hasPrefix(rootPath) ? String(path.dropFirst(rootPath.count)) : path
	}

	private func files(named name: String) -> [URL] {
		if filesByName == nil {
			var index: [String: [URL]] = [:]
			let enumerator = FileManager.default.enumerator(
				at: root,
				includingPropertiesForKeys: [.isRegularFileKey],
				options: [.skipsHiddenFiles],
			)
			while let url = enumerator?.nextObject() as? URL {
				guard (try? url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true else {
					continue
				}

				index[url.lastPathComponent, default: []].append(url.resolvingSymlinksInPath())
			}
			filesByName = index
		}
		return filesByName?[name] ?? []
	}
}
