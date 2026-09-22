import ArgumentParser

// MARK: - Root Command

@main
struct TP: AsyncParsableCommand {
	static let configuration = CommandConfiguration(
		commandName: "tp",
		abstract: "A utility for commonly performed tasks while developing Teleport",
		subcommands: [Deploy.self, Tsh.self],
	)
}
