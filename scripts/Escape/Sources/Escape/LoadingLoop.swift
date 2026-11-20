/// The frames of a loading animation and how long one pass through them takes.
public struct LoadingLoop: Sendable {
	/// The symbols shown one after another, each for `durationPerSymbol`.
	var symbols: [String]
	/// How long one pass through every symbol takes.
	var duration: Duration

	/// How long each symbol is shown.
	var durationPerSymbol: Duration {
		duration / symbols.count
	}
}

// MARK: - Static Members

extension LoadingLoop {
	/// Four braille dots that circle their cell once every 0.6 seconds.
	public static var snake: LoadingLoop {
		LoadingLoop(
			symbols: ["\u{280F}", "\u{281B}", "\u{2839}", "\u{283C}", "\u{2836}", "\u{2827}"],
			duration: .milliseconds(600),
		)
	}

	/// Braille dots that fill their cell one at a time and then drain away, starting from a different dot
	/// in each of six phases, over six seconds.
	public static var weeee: LoadingLoop {
		LoadingLoop(
			symbols: [
				// Phase 1
				[
					"\u{2801}",
					"\u{2809}",
					"\u{2819}",
					"\u{2839}",
					"\u{283D}",
					"\u{283F}",
					"\u{283E}",
					"\u{2836}",
					"\u{2826}",
					"\u{2806}",
				],
				// Phase 2
				[
					"\u{2802}",
					"\u{2803}",
					"\u{280B}",
					"\u{281B}",
					"\u{283B}",
					"\u{283F}",
					"\u{283D}",
					"\u{283C}",
					"\u{2834}",
					"\u{2824}",
				],
				// Phase 3
				[
					"\u{2804}",
					"\u{2806}",
					"\u{2807}",
					"\u{280F}",
					"\u{281F}",
					"\u{283F}",
					"\u{283B}",
					"\u{2839}",
					"\u{2838}",
					"\u{2830}",
				],
				// Phase 4
				[
					"\u{2820}",
					"\u{2824}",
					"\u{2826}",
					"\u{2827}",
					"\u{282F}",
					"\u{283F}",
					"\u{281F}",
					"\u{281B}",
					"\u{2819}",
					"\u{2818}",
				],
				// Phase 5
				[
					"\u{2810}",
					"\u{2830}",
					"\u{2834}",
					"\u{2836}",
					"\u{2837}",
					"\u{283F}",
					"\u{282F}",
					"\u{280F}",
					"\u{280B}",
					"\u{2809}",
				],
				// Phase 6
				[
					"\u{2808}",
					"\u{2818}",
					"\u{2838}",
					"\u{283C}",
					"\u{283E}",
					"\u{283F}",
					"\u{2837}",
					"\u{2827}",
					"\u{2807}",
					"\u{2803}",
				],
			].flatMap(\.self),
			duration: .seconds(6),
		)
	}
}
