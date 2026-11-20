import Testing
@testable import Escape

struct `colored text` {
	@Test
	func `Wraps text in its color's code and resets both colors after it`() {
		let expected = "\u{1B}[31;49mHoth\u{1B}[39;49m"
		let got = "Hoth".colorized(foreground: .red)
		#expect(got == expected)
	}

	@Test
	func `Sets the text and background colors in one sequence`() {
		let expected = "\u{1B}[93;40mPikachu\u{1B}[39;49m"
		let got = "Pikachu".colorized(foreground: .brightYellow, background: .black)
		#expect(got == expected)
	}

	@Test
	func `Colors only the interpolated string`() {
		let expected = "Next stop, \u{1B}[39;43mTatooine\u{1B}[39;49m."
		let got = "Next stop, \("Tatooine", background: .yellow)."
		#expect(got == expected)
	}
}

struct `loading loops` {
	@Test
	func `Shows each symbol for an equal share of the loop`() {
		#expect(LoadingLoop.snake.durationPerSymbol == .milliseconds(100))
	}
}
