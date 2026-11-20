import ArgumentParser
import Foundation

@main
struct IsWorkMac: AsyncParsableCommand {
	static let configuration = CommandConfiguration(
		commandName: "is-work-mac",
		abstract: "Exit 0 on the work Mac and 1 on any other Mac",
		discussion: """
			The work Mac is enrolled in MDM by IT, and personal Macs aren't, so this \
			reads the enrollment that `profiles status -type enrollment` reports. It \
			prints nothing when it can tell. When it can't, it prints why and exits 2, \
			so a caller that treats only exit 1 as a personal Mac stays safe when \
			enrollment is unknown.
			""",
	)

	func run() async throws {
		let isEnrolled: Bool
		do {
			isEnrolled = try await MDMEnrollment.isEnrolled()
		} catch {
			FileHandle.standardError.write(Data("is-work-mac: \(error)\n".utf8))
			throw ExitCode(2)
		}

		guard isEnrolled else {
			throw ExitCode.failure
		}
	}
}
