import ArgumentParser
import Command
import Escape
import Foundation

struct Workspace: AsyncParsableCommand {
	static let configuration = CommandConfiguration(
		commandName: "workspace",
		abstract: "Open the current Dia project in a new Ghostty workspace",
		aliases: ["ws"]
	)

	func run() async throws {
		let projectRoot = try await ProjectRoot.find()

		// Check if workspace already exists for this directory
		if let existingPID = await findExistingWorkspace(for: projectRoot) {
			print("Activating existing workspace...".colorized(foreground: .cyan))
			try await activateProcess(pid: existingPID)
			return
		}

		// Create .goose-dia-user-dir if it doesn't exist
		let userDirURL = projectRoot.appendingPathComponent(".goose-dia-user-dir")
		if !FileManager.default.fileExists(atPath: userDirURL.path) {
			print("Creating workspace user directory...".colorized(foreground: .cyan))
			try FileManager.default.createDirectory(
				at: userDirURL,
				withIntermediateDirectories: true
			)
		}

		// Select available Ghostty profile
		let profile = try await selectGhosttyProfile()
		print("Opening workspace with profile: \(profile)".colorized(foreground: .cyan))

		// Launch Ghostty with working directory (don't wait for exit)
		let configPath = FileManager.default.homeDirectoryForCurrentUser
			.appendingPathComponent(".config/ghostty/profiles/\(profile).config")
			.path
		let process = Process()
		process.executableURL = URL(filePath: "/usr/bin/env")
		process.arguments = ["ghostty", "--config-file=\(configPath)", "--window-inherit-working-directory=false", "--working-directory=\(projectRoot.path)"]
		try process.run()
	}
}

// MARK: - Private Helpers

private func findExistingWorkspace(for projectRoot: URL) async -> Int? {
	// Use [g]hostty trick so pgrep doesn't match itself
	let pattern = "[g]hostty.*--working-directory=\(projectRoot.path)"
	let command = Command(executable: "pgrep", arguments: ["-fl", pattern])
	try? await command.run(interactive: false, passthroughOutput: false)

	guard await command.exitStatus == 0,
		  let output = await command.standardOutput,
		  let pidString = output.split(separator: " ").first,
		  let pid = Int(pidString) else {
		return nil
	}
	return pid
}

private func activateProcess(pid: Int) async throws {
	let script = """
	tell application "System Events" to set frontmost of (first process whose unix id is \(pid)) to true
	"""
	let command = Command(executable: "osascript", arguments: ["-e", script])
	try await command.run(interactive: false, passthroughOutput: false)
}

private func selectGhosttyProfile() async throws -> String {
	let profiles = ["blade", "pro", "van-helsing", "morbius", "buffy", "lincoln"]

	for profile in profiles {
		// Use [g]hostty trick so pgrep doesn't match itself
		let pattern = "[g]hostty.*--config-file=.*\(profile)\\.config"
		let command = Command(executable: "pgrep", arguments: ["-fl", pattern])
		try? await command.run(interactive: false, passthroughOutput: false)

		// Exit status 0 means match found - profile is in use
		if await command.exitStatus != 0 {
			return profile
		}
	}

	throw WorkspaceError.allProfilesInUse
}

// MARK: - Errors

enum WorkspaceError: Error, CustomStringConvertible {
	case allProfilesInUse

	var description: String {
		switch self {
		case .allProfilesInUse:
			return "All Ghostty profiles are currently in use. Close some workspace windows and try again."
		}
	}
}
