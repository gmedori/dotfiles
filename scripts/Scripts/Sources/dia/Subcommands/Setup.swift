import ArgumentParser
import Command
import Escape
import Foundation

struct Setup: AsyncParsableCommand {
	static let configuration = CommandConfiguration(
		abstract: "Configure the Dia project with cmake"
	)

	@Flag(name: [.customShort("f"), .long], help: "Force a fresh setup by passing --fresh to cmake")
	var force: Bool = false

	func run() async throws {
		let projectRoot = try await ProjectRoot.find()
		FileManager.default.changeCurrentDirectoryPath(projectRoot.path)

		print("Setting up Dia project...".colorized(foreground: .cyan))

		var arguments = ["--preset", "dia-debug"]
		if force {
			arguments.append("--fresh")
		}

		let command = Command(
			executable: "cmake",
			arguments: arguments
		)

		try await command.run(interactive: false, passthroughOutput: true)

		if let exitStatus = await command.exitStatus, exitStatus == 0 {
			print("\n\("Setup completed successfully", foreground: .green)")
		} else {
			print("\n\("Setup failed", foreground: .red)")
			throw ExitCode.failure
		}
	}
}
