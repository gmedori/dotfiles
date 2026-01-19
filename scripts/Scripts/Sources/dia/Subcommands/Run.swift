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

		print("Running Dia...".colorized(foreground: .cyan))
		let runCommand = Command(
			executable: "./build/dia-debug/bin/Dia.app/Contents/MacOS/Dia",
			arguments: []
		)
		try await runCommand.run(interactive: true, passthroughOutput: true)
	}
}
