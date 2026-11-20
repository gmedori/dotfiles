import ArgumentParser

@main
struct IOSD: AsyncParsableCommand {
	static let configuration = CommandConfiguration(
		commandName: "iosd",
		abstract: "A utility for commonly performed tasks in iOS development",
		subcommands: [NukeDerivedData.self],
	)
}
