import ArgumentParser
import Escape
import Foundation

struct Clean: AsyncParsableCommand {
	static let configuration = CommandConfiguration(
		abstract: "Remove the dia-debug build directory"
	)

	func run() async throws {
		let projectRoot = try await ProjectRoot.find()
		let buildDirectory = projectRoot.appendingPathComponent("build/dia-debug")

		print("Cleaning Dia build artifacts...".colorized(foreground: .cyan))

		let fileManager = FileManager.default

		guard fileManager.fileExists(atPath: buildDirectory.path) else {
			print("Build directory does not exist, nothing to clean.".colorized(foreground: .yellow))
			return
		}

		do {
			try fileManager.removeItem(at: buildDirectory)
			print("\("Successfully removed", foreground: .green) \(buildDirectory.path)")
		} catch {
			print("\("Failed to remove build directory:", foreground: .red) \(error.localizedDescription)")
			throw ExitCode.failure
		}
	}
}
