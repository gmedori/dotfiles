import ArgumentParser
import Darwin
import Foundation
import System
import Escape
import Subprocess

struct NukeDerivedData: AsyncParsableCommand {
	static let configuration = CommandConfiguration(
		abstract: "Forcefully deletes the derived data directory where Xcode stores many intermediate products."
	)

	func run() async throws {
		let derivedDataDirectory = await getDerivedDataDirectory()
		print("Are you sure you want to delete the DerivedData directory?\n\(derivedDataDirectory)\n\nAnything except 'yes' will abort.")
		guard let input = readLine() else {
			exit(error: "❌ Failed to read any input")
		}

		if input.trimmingCharacters(in: .whitespacesAndNewlines) == "yes" {
			let loadingTask = echoLoadingText(prefix: "🔥 Nuking ", foregroundColor: .red)
			do {
				try FileManager.default.removeItem(atPath: derivedDataDirectory.string)
				loadingTask.cancel()
				print("\n✅ Successfully nuked \(derivedDataDirectory.string, foreground: .green)")
			} catch {
                loadingTask.cancel()
				exit(error: "❌ Failed to nuke derived data: \(error.localizedDescription)")
			}
		} else {
			exit(error: "❌ Aborting...")
		}
	}

	private func getDerivedDataDirectory() async -> FilePath {
		let homeDir = FileManager.default.homeDirectoryForCurrentUser.path()
		let defaultPath = FilePath(homeDir)
			.appending("Library")
			.appending("Developer")
			.appending("Xcode")
			.appending("DerivedData")
		return await customDerivedDataDirectory() ?? defaultPath
	}

	private func customDerivedDataDirectory() async -> FilePath? {
		do {
			let result = try await Subprocess.run(
				.name("defaults"),
				arguments: ["read", "com.apple.dt.Xcode", "IDECustomDerivedDataLocation"],
				output: .string(limit: 4_096)
			)
			guard
				result.terminationStatus.isSuccess,
				let output = result.standardOutput?.trimmingCharacters(in: .whitespacesAndNewlines),
				!output.isEmpty
			else {
				return nil
			}
			return FilePath(output)
		} catch {
			return nil
		}
	}

	private func exit(error string: String) -> Never {
		print(string.colorized(foreground: .red))
		Self.exit(withError: ExitCode.failure)
	}
}
