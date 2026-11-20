extension Substring {
	/// The substring without the whitespace at its end.
	func trimmingTrailingWhitespace() -> Substring {
		var result = self
		while let last = result.last, last.isWhitespace {
			result.removeLast()
		}
		return result
	}
}
