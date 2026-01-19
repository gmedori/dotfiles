import ArgumentParser
import Foundation

struct Build: AsyncParsableCommand {
	static let configuration = CommandConfiguration(
		abstract: "Build the Dia target"
	)

	func run() async throws {
		let projectRoot = try await ProjectRoot.find()
		FileManager.default.changeCurrentDirectoryPath(projectRoot.path)

		let success = try await BuildCore.build(projectRoot: projectRoot)
		if !success {
			throw ExitCode.failure
		}
	}
}
