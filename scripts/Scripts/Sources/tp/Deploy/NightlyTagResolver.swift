/// Picks the nightly base image to deploy on top of.
enum NightlyTagResolver {
	/// The newest of `tags` that's a nightly of `version`, or `nil` when none is. Nightlies are ordered
	/// by date, then build number, and a `master` build wins a tie with another branch.
	static func newestTag(for version: String, from tags: [String]) -> String? {
		tags.compactMap { NightlyTag(version: version, tag: $0) }
			.max()?
			.tag
	}
}

// MARK: - Supporting Types

extension NightlyTagResolver {
	/// A nightly tag, like `19.0.0-prealpha.2-nightly20260916-1-master`, split into its parts.
	struct NightlyTag {
		/// The whole tag.
		let tag: String
		/// The build's date, written as YYYYMMDD.
		let date: String
		/// The build's number on its date.
		let build: Int
		/// The branch or commit the build came from.
		let source: String

		init?(version: String, tag: String) {
			let prefix = "\(version)-nightly"
			guard tag.hasPrefix(prefix) else {
				return nil
			}

			let suffix = tag.dropFirst(prefix.count)
			let parts = suffix.split(separator: "-", omittingEmptySubsequences: false)
			guard
				parts.count >= 3,
				parts[0].count == 8,
				parts[0].allSatisfy(\.isNumber),
				let build = Int(parts[1])
			else {
				return nil
			}

			let source = parts.dropFirst(2).joined(separator: "-")
			guard !source.isEmpty else {
				return nil
			}

			self.tag = tag
			self.date = String(parts[0])
			self.build = build
			self.source = source
		}
	}
}

// MARK: - NightlyTagResolver.NightlyTag + Comparable

extension NightlyTagResolver.NightlyTag: Comparable {
	static func < (lhs: Self, rhs: Self) -> Bool {
		if lhs.date != rhs.date {
			return lhs.date < rhs.date
		}
		if lhs.build != rhs.build {
			return lhs.build < rhs.build
		}
		if (lhs.source == "master") != (rhs.source == "master") {
			return lhs.source != "master"
		}
		return lhs.tag < rhs.tag
	}
}
