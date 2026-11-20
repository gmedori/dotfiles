extension String {
	/// Wraps the string in the sequences that set `foreground` and `background` and then reset both.
	public mutating func colorize(foreground: Color = .reset, background: Color = .reset) {
		self = colorized(foreground: foreground, background: background)
	}

	/// The string wrapped in the sequences that set `foreground` and `background` and then reset both,
	/// so text after it keeps the terminal's colors.
	public func colorized(foreground: Color = .reset, background: Color = .reset) -> String {
		ControlSequence.colors(foreground: foreground, background: background) + self + ControlSequence.colors()
	}
}

extension String.StringInterpolation {
	// These are three overloads instead of one method with default arguments, because a method whose
	// labels can all be left out would also match every plain `\(string)` interpolation.

	/// Interpolates `string` on the `background` color.
	public mutating func appendInterpolation(_ string: String, background: Color) {
		appendInterpolation(string.colorized(background: background))
	}

	/// Interpolates `string` in the `foreground` color.
	public mutating func appendInterpolation(_ string: String, foreground: Color) {
		appendInterpolation(string.colorized(foreground: foreground))
	}

	/// Interpolates `string` in the `foreground` color on the `background` color.
	public mutating func appendInterpolation(_ string: String, foreground: Color, background: Color) {
		appendInterpolation(string.colorized(foreground: foreground, background: background))
	}
}
