extension String {
	/// The string without `suffix` at its end, or the string as it is when it doesn't end with it.
	func trimmingSuffix(_ suffix: String) -> String {
		hasSuffix(suffix) ? String(dropLast(suffix.count)) : self
	}

	/// The string without the whitespace at its end.
	func trimmingTrailingWhitespace() -> String {
		String(Substring(self).trimmingTrailingWhitespace())
	}
}
