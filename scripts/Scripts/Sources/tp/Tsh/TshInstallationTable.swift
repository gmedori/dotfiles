import Foundation

/// The table `tp tsh list` prints, with a column each for the version, the source, and the path.
struct TshInstallationTable {
	private let versionWidth: Int
	private let sourceWidth: Int

	/// The row of column headings.
	var header: String {
		formattedRow(marker: " ", version: "VERSION", source: "SOURCE", location: "PATH")
	}

	/// Creates a table with columns wide enough for every one of `installations`.
	init(installations: [TshInstallation]) {
		self.versionWidth = max("VERSION".count, installations.map(\.version.count).max() ?? 0)
		self.sourceWidth = max("SOURCE".count, installations.map(\.source.rawValue.count).max() ?? 0)
	}

	/// The row for `installation`, marked with `*` when it's the one the link selects.
	func row(for installation: TshInstallation, isActive: Bool) -> String {
		formattedRow(
			marker: isActive ? "*" : " ",
			version: installation.version,
			source: installation.source.rawValue,
			location: installation.displayPath,
		)
	}
}

// MARK: - Private Helpers

extension TshInstallationTable {
	private func formattedRow(
		marker: String,
		version: String,
		source: String,
		location: String,
	) -> String {
		let selectionAndVersion = "\(marker) \(padded(version, to: versionWidth))"
		return [selectionAndVersion, padded(source, to: sourceWidth), location]
			.joined(separator: "  ")
	}

	private func padded(_ value: String, to width: Int) -> String {
		value.padding(toLength: width, withPad: " ", startingAt: 0)
	}
}
