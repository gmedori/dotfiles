import ArgumentParser
import Foundation

@main
struct Notify: ParsableCommand {
	static let configuration = CommandConfiguration(
		commandName: "notify",
		abstract: "Display a macOS notification",
	)

	@Argument(help: "The message to display")
	var message: [String]

	@Option(name: .shortAndLong, help: "The title of the message")
	var title: String = "Notify"

	@Option(name: .long, help: "An optional subtitle to include with the notification")
	var subtitle: String?

	@Option(name: .shortAndLong, help: "The sound to play when the notification is displayed")
	var sound: Sound = .purr

	func run() throws {
		let messageText = message.joined(separator: " ")
		var script = "display notification \"\(messageText)\""
		script += " with title \"\(title)\""
		if let subtitle {
			script += " subtitle \"\(subtitle)\""
		}
		script += " sound name \"\(sound.rawValue)\""

		let process = Process()
		process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
		process.arguments = ["-e", script]

		try process.run()
	}
}

enum Sound: String, ExpressibleByArgument, CaseIterable {
	case basso
	case blow
	case bottle
	case frog
	case funk
	case glass
	case hero
	case morse
	case ping
	case pop
	case purr
	case sosumi
	case submarine
	case tink
}
