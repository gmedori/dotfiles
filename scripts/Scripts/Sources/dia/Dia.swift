import ArgumentParser

@main
struct Dia: AsyncParsableCommand {
	static let configuration = CommandConfiguration(
		commandName: "dia",
		abstract: "Build tools for the Dia project",
		subcommands: [Setup.self, Build.self, Clean.self, Run.self, Workspace.self]
	)
}
