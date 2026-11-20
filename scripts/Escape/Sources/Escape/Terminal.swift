import Darwin

/// Writes text and loading animations to standard output.
public enum Terminal {
	/// Prints each item in turn, with nothing between them and no newline after them.
	public static func echo(_ items: Any...) {
		for item in items {
			print(item, terminator: "")
		}
	}

	/// Erases the current line and moves the cursor to its start, so the next output replaces the line.
	public static func clearLine() {
		echo(ControlSequence.clearLine)
	}

	/// Shows a loading animation on the current line, between `prefix` and `suffix` and in the given
	/// colors, until the returned task is canceled. Canceling it ends the line.
	public static func echoLoadingText(
		prefix: String? = nil,
		suffix: String? = nil,
		loop: LoadingLoop = .weeee,
		foreground: Color = .reset,
		background: Color = .reset,
	) -> Task<Void, Never> {
		echoLoadingText(loop: loop) { symbol in
			"\(prefix ?? "")\(symbol)\(suffix ?? "")".colorized(foreground: foreground, background: background)
		}
	}

	/// Shows a loading animation on the current line until the returned task is canceled. Each frame
	/// clears the line and prints what `content` returns for the frame's symbol. Canceling the task ends
	/// the line, unless `writesNewlineOnCancellation` is `false`.
	public static func echoLoadingText(
		loop: LoadingLoop = .weeee,
		writesNewlineOnCancellation: Bool = true,
		content: @escaping @Sendable (_ symbol: String) async -> String,
	) -> Task<Void, Never> {
		Task {
			var cursor = loop.symbols.startIndex
			while !Task.isCancelled {
				clearLine()
				await echo(content(loop.symbols[cursor]))
				fflush(stdout)
				// Ignoring the error here means a cancellation cuts the sleep short, and the loop stops when it
				// checks `Task.isCancelled` next.
				try? await Task.sleep(for: loop.durationPerSymbol)
				loop.symbols.formIndex(after: &cursor)
				if cursor == loop.symbols.endIndex {
					cursor = loop.symbols.startIndex
				}
			}
			if writesNewlineOnCancellation {
				echo("\n")
			}
		}
	}
}
