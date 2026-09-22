import CommandKit
import Foundation

// MARK: - Managed Update Environment

enum TshEnvironment {
	// MARK: - Configuration

	static let managedUpdatesVariable = "TELEPORT_TOOLS_VERSION"
	static let managedUpdatesDisabledValue = "off"
	static let fishConfigurationCommand =
		"echo 'set -gx TELEPORT_TOOLS_VERSION off' >> ~/.config/fish/config.fish"

	static var managedUpdatesDisabled: Bool {
		managedUpdatesDisabled(in: ProcessInfo.processInfo.environment)
	}

	static func managedUpdatesDisabled(in environment: [String: String]) -> Bool {
		environment[managedUpdatesVariable] == managedUpdatesDisabledValue
	}

	// MARK: - Validation

	static func requireManagedUpdatesDisabled() throws {
		guard managedUpdatesDisabled else {
			throw RuntimeError(
				"TELEPORT_TOOLS_VERSION must be set to 'off' before switching tsh versions.\n"
					+ "Append it to your fish config:\n  \(fishConfigurationCommand)\n"
					+ "Then start a new fish session."
			)
		}
	}

	static func printWarningIfNeeded() {
		guard !managedUpdatesDisabled else {
			return
		}

		writeToStandardError(
			"Warning: TELEPORT_TOOLS_VERSION is not set to 'off'.\n"
				+ "Append it to your fish config:\n  \(fishConfigurationCommand)\n"
		)
	}

	// MARK: - Output

	private static func writeToStandardError(_ message: String) {
		FileHandle.standardError.write(Data(message.utf8))
	}
}
