import Foundation
import System

public actor Command: Sendable {
	public init(_ commandString: String) {
		let tokens = commandString.split(separator: /\s+/)
		if let firstToken = tokens.first {
			executable = String(firstToken)
		} else {
			executable = ""
		}
		arguments = tokens.dropFirst().map(String.init(_:))
	}

	public init(executable: String, arguments: [String]) {
		self.executable = executable
		self.arguments = arguments
	}

	nonisolated public let executable: String
	nonisolated public let arguments: [String]

	public private(set) var standardOutput: String?
	public private(set) var standardError: String?
	public private(set) var exitStatus: Int?

	let queue = DispatchQueue(label: "swift.command")

	public func run(
		interactive isInteractive: Bool = true,
		passthroughOutput: Bool = false
	) throws {
		guard !executable.isEmpty else { throw Error.missingExecutable }
		let process = Process()
		let envURL = URL(filePath: "/usr/bin/env")
		process.executableURL = envURL
		process.arguments = [executable] + arguments

		let stdoutPipe = Pipe()
		let stderrPipe = Pipe()

		if !passthroughOutput {
			process.standardOutput = stdoutPipe
			process.standardError = stderrPipe
		}

		if isInteractive {
			let stdinPipe = Pipe()
			process.standardInput = stdinPipe
			let fileHandle = FileHandle(fileDescriptor: STDIN_FILENO)
			fileHandle.readabilityHandler = { handle in
				let data = handle.availableData
				if !data.isEmpty {
					stdinPipe.fileHandleForWriting.write(data)
				}
			}
		}

		try process.run()
		process.waitUntilExit()

		if !passthroughOutput {
			if let outputData = try stdoutPipe.fileHandleForReading.readToEnd() {
				standardOutput = String(data: outputData, encoding: .utf8)
			}

			if let errorData = try stderrPipe.fileHandleForReading.readToEnd() {
				standardError = String(data: errorData, encoding: .utf8)
			}
		}

		self.exitStatus = Int(process.terminationStatus)
	}

	public func output() async throws -> String? {
		try run()
		return standardOutput
	}
}

// MARK: Command + Error

extension Command {
	enum Error: Swift.Error {
		case missingExecutable
	}
}
