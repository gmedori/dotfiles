import Escape

/// Shows the default loading animation for a few seconds, so changes to `Escape` can be checked by eye.
@main
enum EscapeClient {
	/// How many seconds the animation runs before the client cancels it.
	static let durationInSeconds = 5

	// Only the runtime calls the entry point that `@main` marks, so `unused_declaration` reports it as unused.
	// swiftlint:disable:next unused_declaration
	static func main() async {
		let loadingTask = Terminal.echoLoadingText(prefix: "Hello... ")
		// Ignoring the error here is safe, since nothing cancels this task, so the sleep always finishes.
		try? await Task.sleep(for: .seconds(durationInSeconds))
		loadingTask.cancel()
		await loadingTask.value
	}
}
