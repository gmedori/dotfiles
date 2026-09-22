import ArgumentParser
import CommandKit
import Foundation
import System

struct Deploy: AsyncParsableCommand {
	static let defaultBaseImageRepository =
		"public.ecr.aws/gravitational-staging/teleport-ent-distroless"

	static let configuration = CommandConfiguration(
		commandName: "deploy",
		abstract: "Deploy a local Teleport build to a Cloud staging tenant",
	)

	@Argument(help: "Tenant subdomain to deploy")
	var tenant: String

	@Option(
		name: .customLong("base-image-repo"),
		help: "Public ECR base-image repository used to resolve a nightly"
	)
	var baseImageRepository = defaultBaseImageRepository

	@Option(
		name: .customLong("base-image-tag"),
		help: "Use an exact base-image tag instead of resolving the newest nightly"
	)
	var baseImageTag: String?

	@Option(
		name: .long,
		help: "Linux amd64 C compiler passed to make; otherwise it is discovered automatically"
	)
	var cc: String?

	@Option(
		name: .customLong("teleport-dir"),
		help: "Teleport checkout containing the deploy-cloud make target"
	)
	var teleportDirectory = "."

	func validate() throws {
		guard !tenant.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
			throw ValidationError("The tenant must not be empty.")
		}
		guard !baseImageRepository.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
			throw ValidationError("--base-image-repo must not be empty.")
		}
		if let baseImageTag,
			baseImageTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
		{
			throw ValidationError("--base-image-tag must not be empty.")
		}
		if let cc, cc.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
			throw ValidationError("--cc must not be empty.")
		}
	}

	func run() async throws {
		let checkout = try TeleportCheckout(path: teleportDirectory)
		let compiler = try DeployCompiler.resolve(explicit: cc)

		print("Checking Cloud deployment access...")
		try await Make.run(
			arguments: ["deploy-cloud-login"],
			in: checkout.enterpriseDirectory,
			failureMessage: "deploy-cloud-login failed"
		)

		let version = try await Make.capture(
			arguments: ["--no-print-directory", "print-version"],
			in: checkout.rootDirectory,
			failureMessage: "Could not determine the Teleport version"
		)

		let tag: String
		if let baseImageTag {
			tag = baseImageTag
		} else {
			print("Resolving the newest staging nightly for \(version)...")
			let repository = try PublicECRRepository(baseImageRepository)
			let tags = try await PublicECRClient().tags(in: repository)
			guard let resolvedTag = NightlyTagResolver.newestTag(
				for: version,
				from: tags
			) else {
				throw RuntimeError(
					"No nightly tag beginning with \(version)-nightly was found in "
						+ baseImageRepository + "."
				)
			}
			tag = resolvedTag
		}

		print("Using base image: \(baseImageRepository):\(tag)")
		if let compiler {
			print("Using compiler: \(compiler)")
		}

		var arguments = [
			"TENANT=\(tenant)",
			"BASE_IMAGE_REPO=\(baseImageRepository)",
			"BASE_IMAGE_TAG=\(tag)",
		]
		if let compiler {
			arguments.append("CC=\(compiler)")
		}
		arguments.append("deploy-cloud")

		try await Make.run(
			arguments: arguments,
			in: checkout.enterpriseDirectory,
			failureMessage: "deploy-cloud failed"
		)
	}
}

private enum DeployCompiler {
	static func resolve(
		explicit: String?,
		environment: [String: String] = ProcessInfo.processInfo.environment,
		fileManager: FileManager = .default
	) throws -> String? {
		if let explicit {
			return explicit
		}
		if let configured = environment["CC"], !configured.isEmpty {
			return configured
		}

		let compilerName = "x86_64-unknown-linux-gnu-gcc"
		let knownPaths = [
			"/opt/homebrew/bin/\(compilerName)",
			"/usr/local/bin/\(compilerName)",
		]
		for path in knownPaths where fileManager.isExecutableFile(atPath: path) {
			return path
		}

		for component in (environment["PATH"] ?? "")
			.split(separator: ":", omittingEmptySubsequences: false)
		{
			let directory = component.isEmpty ? "." : String(component)
			let candidate = URL(fileURLWithPath: directory, isDirectory: true)
				.appending(path: compilerName)
			if fileManager.isExecutableFile(atPath: candidate.path) {
				return candidate.path
			}
		}

		#if arch(arm64)
		throw ValidationError(
			"Could not find \(compilerName). Install the macOS cross-toolchain or pass --cc."
		)
		#else
		return nil
		#endif
	}
}

private enum Make {
	static func run(
		arguments: [String],
		in directory: URL,
		failureMessage: String
	) async throws {
		let result: ExecutionResult<Void, FileDescriptorOutput, FileDescriptorOutput>
		do {
			result = try await Subprocess.run(
				.name("make"),
				arguments: Arguments(arguments),
				workingDirectory: FilePath(directory.path),
				input: .standardInput,
				output: .currentStandardOutput,
				error: .currentStandardError
			)
		} catch {
			throw RuntimeError("Could not run make: \(error)")
		}

		guard result.terminationStatus.isSuccess else {
			throw RuntimeError(failureMessage)
		}
	}

	static func capture(
		arguments: [String],
		in directory: URL,
		failureMessage: String
	) async throws -> String {
		let result: ExecutionResult<
			Void,
			StringOutput<Unicode.UTF8>,
			StringOutput<Unicode.UTF8>
		>
		do {
			result = try await Subprocess.run(
				.name("make"),
				arguments: Arguments(arguments),
				workingDirectory: FilePath(directory.path),
				output: .string(limit: 64 * 1024),
				error: .string(limit: 64 * 1024)
			)
		} catch {
			throw RuntimeError("Could not run make: \(error)")
		}

		guard result.terminationStatus.isSuccess else {
			let error = result.standardError?
				.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
			throw RuntimeError(error.isEmpty ? failureMessage : error)
		}

		let output = result.standardOutput?
			.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
		guard !output.isEmpty else {
			throw RuntimeError(failureMessage)
		}
		return output
	}
}
