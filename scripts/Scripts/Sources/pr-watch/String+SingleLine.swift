extension String {
	/// The text with each run of whitespace, newlines included, collapsed to one space, and cut to
	/// `limit` characters with an ellipsis when it's longer.
	func singleLine(limit: Int) -> String {
		let text = split(whereSeparator: \.isWhitespace).joined(separator: " ")
		guard text.count > limit else {
			return text
		}

		return "\(text.prefix(limit))…"
	}
}
