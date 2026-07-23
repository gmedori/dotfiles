import ArgumentParser
import CommandKit
import Foundation

struct ResetEnrollment: AsyncParsableCommand {
	static let configuration = CommandConfiguration(
		commandName: "reset-enrollment",
		abstract: "Remove pending mobile-device enrollment pairings from a local Teleport cluster",
	)

	@OptionGroup var globalOptions: GlobalOptions

	private static let databasePath = "backend/sqlite.db"
	private static let deletePairingsSQL = """
		BEGIN IMMEDIATE;
		DELETE FROM kv
		WHERE key GLOB '/devices/enroll_pairing/*'
		   OR key GLOB '/devices/enroll_pairing_by_token/*';
		SELECT changes();
		COMMIT;
		"""

	func run() async throws {
		let databasePath = try resolveDatabasePath()

		let result = try await Subprocess.run(
			.name("sqlite3"),
			arguments: [
				"-batch",
				"-bail",
				"-cmd", ".timeout 5000",
				databasePath,
				Self.deletePairingsSQL,
			],
			output: .string(limit: 4096),
			error: .string(limit: 4096),
		)

		guard result.terminationStatus.isSuccess else {
			let error = result.standardError?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
			throw RuntimeError(error.isEmpty ? "Failed to update the Teleport database." : error)
		}

		let deletedCount = Int(
			result.standardOutput?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
		)

		guard let deletedCount else {
			throw RuntimeError("SQLite did not report how many enrollment records were removed.")
		}

		if deletedCount == 0 {
			print("No pending mobile-device enrollment pairings found.")
		} else {
			print("Removed \(deletedCount) pending mobile-device enrollment record\(deletedCount == 1 ? "" : "s").")
		}
	}

	private func resolveDatabasePath() throws -> String {
		let fileManager = FileManager.default
		let workingDirectory = URL(fileURLWithPath: fileManager.currentDirectoryPath, isDirectory: true)
		let dataDirectory = URL(
			fileURLWithPath: globalOptions.dataDirectory,
			relativeTo: workingDirectory,
		).standardizedFileURL
		let database = dataDirectory.appendingPathComponent(Self.databasePath)

		guard fileExists(at: database.path, using: fileManager) else {
			throw ValidationError(
				"No Teleport SQLite backend found at \(database.path).",
			)
		}

		return database.path
	}

	private func fileExists(at path: String, using fileManager: FileManager) -> Bool {
		var isDirectory: ObjCBool = false
		return fileManager.fileExists(atPath: path, isDirectory: &isDirectory) && !isDirectory.boolValue
	}
}
