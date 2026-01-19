import Command
import Foundation

enum ProjectRoot {
	/// Finds the Dia project root by searching for a git repository with the arc.git remote.
	/// Starts from the current directory and walks up the directory tree.
	static func find() async throws -> URL {
		let fileManager = FileManager.default
		var currentDirectory = URL(fileURLWithPath: fileManager.currentDirectoryPath)

		while true {
			let gitDir = currentDirectory.appendingPathComponent(".git")

			// .git can be a directory (normal repo) or file (worktree)
			if fileManager.fileExists(atPath: gitDir.path),
			   await isArcRepo(at: currentDirectory) {
				return currentDirectory
			}

			let parent = currentDirectory.deletingLastPathComponent()
			if parent.path == currentDirectory.path {
				throw ProjectRootError.notFound
			}
			currentDirectory = parent
		}
	}

	private static func isArcRepo(at directory: URL) async -> Bool {
		let command = Command(executable: "git", arguments: ["-C", directory.path, "remote", "-v"])
		do {
			try await command.run(interactive: false)
			return await command.standardOutput?.contains("arc.git") ?? false
		} catch {
			return false
		}
	}
}

enum ProjectRootError: Error, CustomStringConvertible {
	case notFound

	var description: String {
		switch self {
		case .notFound:
			return "Could not find Dia project root. Make sure you're inside the arc repository."
		}
	}
}
