import ArgumentParser

struct GlobalOptions: ParsableArguments {
	@Option(
		name: .customLong("data-dir"),
		help: "Path to Teleport's data directory."
	)
	var dataDirectory = "data/teleport"
}
