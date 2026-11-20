import ArgumentParser

/// Picks the installation that `tp tsh use` selects by version.
enum TshSelector {
	/// The one installation of `requestedVersion`, from `source` when it's given. Throws when none
	/// matches or more than one does.
	static func select(
		version requestedVersion: String,
		source: TshSource?,
		from installations: [TshInstallation],
	) throws -> TshInstallation {
		let requestedVersion = TshVersionParser.normalize(requestedVersion)
		let matches = installations.filter { installation in
			installation.version == requestedVersion && (source == nil || installation.source == source)
		}

		guard !matches.isEmpty else {
			let sourceDescription = source.map { " from \($0.rawValue)" } ?? ""
			throw ValidationError(
				"No discovered tsh installation reports version \(requestedVersion)\(sourceDescription). "
					+ "Run 'tp tsh list' to see available installations."
			)
		}
		guard matches.count == 1 else {
			let choices = matches
				.map { "  \($0.source.rawValue): \($0.displayPath)" }
				.joined(separator: "\n")
			throw ValidationError(
				"Multiple installations provide tsh \(requestedVersion):\n\(choices)\n"
					+ "Use --source or --path to select one."
			)
		}

		return matches[0]
	}
}
