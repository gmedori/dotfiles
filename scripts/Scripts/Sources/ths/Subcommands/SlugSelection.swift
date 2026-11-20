/// The catalog entries a command acts on. That's all of them, or only those with the slugs given on
/// the command line. A slug that matches nothing is reported as an error.
struct SlugSelection {
	/// The entries to act on, in catalog order.
	let entries: [CatalogEntry]
	/// The slugs given on the command line that match no entry.
	let unknownSlugs: [String]

	/// An error for each slug in `unknownSlugs`.
	var unknownSlugMessages: [Message] {
		unknownSlugs.map { slug in
			Message(kind: .error, headline: "no post or bundle has the slug \(slug)", details: [])
		}
	}

	init(slugs: [String], catalog: Catalog) {
		guard !slugs.isEmpty else {
			self.entries = catalog.entries
			self.unknownSlugs = []
			return
		}

		let wanted = Set(slugs)
		self.entries = catalog.entries.filter { $0.slug.map(wanted.contains) == true }
		let found = Set(entries.compactMap(\.slug))
		self.unknownSlugs = slugs.filter { !found.contains($0) }
	}
}
