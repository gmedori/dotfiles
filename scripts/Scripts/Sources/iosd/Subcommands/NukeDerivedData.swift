import ArgumentParser
import Command
import Darwin
import Foundation
import System
import Escape

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
//				try FileManager.default.removeItem(atPath: derivedDataDirectory.string)
				try await Task.sleep(for: .seconds(2))
				loadingTask.cancel()
//				try await Task.sleep(for: .seconds(1))
				print("✅ Successfully nuked \(derivedDataDirectory.string)".colorized(foreground: .green))
			} catch {
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
		let command = Command("defaults read com.apple.dt.Xcode IDECustomDerivedDataLocation")

		do {
			guard let output = try await command.output() else {
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
