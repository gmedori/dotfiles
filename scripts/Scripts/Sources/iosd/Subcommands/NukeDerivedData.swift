import ArgumentParser
import CommandKit
import Darwin
import Foundation
import System

struct NukeDerivedData: AsyncParsableCommand {
	static let configuration = CommandConfiguration(
		abstract: "Forcefully deletes the derived data directory where Xcode stores many intermediate products."
	)

	func run() async throws {
		let directory = await derivedDataDirectory()
		print(
			"Are you sure you want to delete the DerivedData directory?\n\(directory)\n\nAnything except 'yes' will abort."
		)
		guard let input = readLine() else {
			throw RuntimeError("❌ Failed to read any input")
		}
		guard input.trimmingCharacters(in: .whitespacesAndNewlines) == "yes" else {
			throw RuntimeError("❌ Aborting...")
		}

		let loadingTask = Terminal.echoLoadingText(prefix: "🔥 Nuking ", foreground: .red)
		do {
			try FileManager.default.removeItem(atPath: directory.string)
			loadingTask.cancel()
			print("\n✅ Successfully nuked \(directory.string, foreground: .green)")
		} catch {
			loadingTask.cancel()
			throw RuntimeError("❌ Failed to nuke derived data: \(error.localizedDescription)")
		}
	}
}

// MARK: - Private Helpers

extension NukeDerivedData {
	private func derivedDataDirectory() async -> FilePath {
		let homeDirectory = FileManager.default.homeDirectoryForCurrentUser.path()
		let defaultPath = FilePath(homeDirectory)
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
				output: .string(limit: 4096),
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
			// Ignoring the error here means that when `defaults` can't run, Xcode's default location is used.
			return nil
		}
	}
}
