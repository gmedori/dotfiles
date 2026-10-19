import ArgumentParser
import Foundation

// MARK: - Path Options

/// The two directories every `ths` subcommand works between: the source directory, which is The
/// Honking Smith folder in the vault, and the website repo. Each comes from its flag, or from its
/// environment variable when the flag isn't given. When neither is set, validation fails with the
/// fish command that sets the variable, so the fix is in the error itself.
struct SitePaths: ParsableArguments {
	static let sourceVariable = "THS_SOURCE_DIR"
	static let siteVariable = "THS_SITE_DIR"
	static let sourceSetCommand = #"set -Ux THS_SOURCE_DIR "$HOME/Obsidian/gooseOS/The Honking Smith""#
	static let siteSetCommand = "set -Ux THS_SITE_DIR $HOME/code/the-honking-smith-dot-com"

	@Option(help: ArgumentHelp(
		"The Honking Smith folder in the vault. Defaults to $\(Self.sourceVariable).",
		valueName: "path",
	))
	var source: String?

	@Option(help: ArgumentHelp(
		"The website repo. Defaults to $\(Self.siteVariable).",
		valueName: "path",
	))
	var site: String?

	/// The source directory. Only valid after `validate()` has passed.
	var sourceDirectory: URL {
		Self.resolve(source, variable: Self.sourceVariable)!
	}

	/// The website repo. Only valid after `validate()` has passed.
	var siteDirectory: URL {
		Self.resolve(site, variable: Self.siteVariable)!
	}

	func validate() throws {
		try Self.validateDirectory(
			source,
			flag: "--source",
			variable: Self.sourceVariable,
			setCommand: Self.sourceSetCommand,
		)
		try Self.validateDirectory(
			site,
			flag: "--site",
			variable: Self.siteVariable,
			setCommand: Self.siteSetCommand,
		)

		let blog = siteDirectory.appending(path: "content/blog")
		guard FileManager.default.fileExists(atPath: blog.path(percentEncoded: false)) else {
			throw ValidationError("\(siteDirectory.path(percentEncoded: false)) has no content/blog folder, so it isn't the site repo.")
		}
	}

	private static func validateDirectory(
		_ flagValue: String?,
		flag: String,
		variable: String,
		setCommand: String,
	) throws {
		guard let url = resolve(flagValue, variable: variable) else {
			throw ValidationError("""
			No \(flag.dropFirst(2)) directory. Pass \(flag), or set $\(variable) once for every fish session:

			  \(setCommand)
			""")
		}

		var isDirectory: ObjCBool = false
		guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory), isDirectory.boolValue else {
			throw ValidationError("\(url.path) isn't a directory.")
		}
	}

	private static func resolve(_ flagValue: String?, variable: String) -> URL? {
		let environmentValue = ProcessInfo.processInfo.environment[variable]
		guard let path = flagValue ?? environmentValue, !path.isEmpty else {
			return nil
		}

		let expanded = (path as NSString).expandingTildeInPath
		return URL(filePath: expanded, directoryHint: .isDirectory).standardizedFileURL
	}
}
