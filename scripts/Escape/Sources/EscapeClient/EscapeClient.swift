import Escape

/// Shows the default loading animation for a few seconds, so changes to `Escape` can be checked by eye.
@main
enum EscapeClient {
	/// How many seconds the animation runs before the client cancels it.
	static let durationInSeconds = 5

	static func main() async {
		let loadingTask = Terminal.echoLoadingText(prefix: "Hello... ")
		// Ignoring the error here is safe, since nothing cancels this task, so the sleep always finishes.
		try? await Task.sleep(for: .seconds(durationInSeconds))
		loadingTask.cancel()
		await loadingTask.value
	}
}
