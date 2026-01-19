import ArgumentParser
import Command
import Escape
import Foundation

struct Run: AsyncParsableCommand {
	static let configuration = CommandConfiguration(
		abstract: "Build and run the Dia target"
	)

	func run() async throws {
		let projectRoot = try await ProjectRoot.find()
		FileManager.default.changeCurrentDirectoryPath(projectRoot.path)

		let success = try await BuildCore.build(projectRoot: projectRoot)
		if !success {
			throw ExitCode.failure
		}

		// Check for workspace user data directory
		let userDirURL = projectRoot.appendingPathComponent(".goose-dia-user-dir")
		var arguments = [String]()
		if FileManager.default.fileExists(atPath: userDirURL.path) {
			arguments.append("--user-data-dir=\(userDirURL.path)")
			print("Running Dia with workspace user data...".colorized(foreground: .cyan))
		} else {
			print("Running Dia...".colorized(foreground: .cyan))
		}

		let runCommand = Command(
			executable: "./build/dia-debug/bin/Dia.app/Contents/MacOS/Dia",
			arguments: arguments
		)
		try await runCommand.run(interactive: true, passthroughOutput: true)
	}
}
