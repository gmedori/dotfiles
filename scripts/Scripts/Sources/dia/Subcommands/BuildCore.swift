import Command
import Escape
import Foundation

enum BuildCore {
	/// Runs the build and returns true on success, false on failure
	/// Also emits notifications on completion
	static func build(projectRoot: URL) async throws -> Bool {
		let dirName = projectRoot.lastPathComponent

		print("Building Dia...".colorized(foreground: .cyan))

		let command = Command(
			executable: "cmake",
			arguments: ["--build", "--preset", "dia-debug", "--target", "Dia"]
		)

		try await command.run(interactive: false, passthroughOutput: true)

		if let exitStatus = await command.exitStatus, exitStatus == 0 {
			print("\n\("Build completed successfully", foreground: .green)")
			try await notify(title: "Build Succeeded in \(dirName)", message: "Dia", sound: "glass")
			return true
		} else {
			print("\n\("Build failed", foreground: .red)")
			try await notify(title: "Build Failed in \(dirName)", message: "Dia", sound: "sosumi")
			return false
		}
	}

	private static func notify(title: String, message: String, sound: String) async throws {
		let notify = Command(
			executable: "notify",
			arguments: [message, "--title", title, "--sound", sound]
		)
		try await notify.run()
	}
}
