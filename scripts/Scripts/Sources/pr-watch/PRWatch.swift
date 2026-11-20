import ArgumentParser
import CommandKit
import Foundation
import System

@main
struct PRWatch: AsyncParsableCommand {
	static let configuration = CommandConfiguration(
		commandName: "pr-watch",
		abstract: "Watch a GitHub pull request until it merges",
	)

	@Argument(help: "The pull request number, URL, or branch to watch")
	var pullRequest: String

	@Option(
		name: [.customShort("R"), .long],
		help: "Select another repository using the [HOST/]OWNER/REPO format",
	)
	var repo: String? = nil

	@Option(
		name: [.customShort("i"), .customLong("interval")],
		help: "The number of seconds between polls",
	)
	var interval = 10

	func validate() throws {
		guard interval > 0 else {
			throw ValidationError("The polling interval must be greater than zero.")
		}
	}

	func run() async throws {
		let display = PollDisplay()
		let loadingTask = Terminal.echoLoadingText(
			loop: .weeee,
			writesNewlineOnCancellation: false,
		) { symbol in
			await display.line(symbol: symbol)
		}

		let mergedPullRequest: PullRequest
		do {
			mergedPullRequest = try await waitForMerge(display: display)
		} catch {
			loadingTask.cancel()
			await loadingTask.value
			Terminal.clearLine()
			throw error
		}

		loadingTask.cancel()
		await loadingTask.value
		Terminal.clearLine()
		await Terminal.echo(display.line(symbol: "✓"), "\n")
		print(mergedPullRequest.url)

		try await postNotification(
			message: "PR \(mergedPullRequest.number) has merged"
		)
	}
}

// MARK: - Private Helpers

extension PRWatch {
	private func waitForMerge(display: PollDisplay) async throws -> PullRequest {
		var reference: PullRequestReference? = nil
		var previousPullRequest: PullRequest? = nil

		while true {
			let pollDate = Date()
			await display.pollStarted(at: pollDate)

			do {
				if reference == nil {
					reference = try await resolvePullRequest()
				}
				guard let reference else {
					throw RuntimeError("Could not resolve the pull request.")
				}

				let pullRequest = try await fetchPullRequest(reference: reference)
				await display.pollSucceeded(with: pullRequest, at: pollDate)
				if pullRequest.isMerged {
					return pullRequest
				}

				if
					let previousPullRequest,
					let notification = pullRequest.queueRemovalNotification(
						after: previousPullRequest
					)
				{
					do {
						try await postNotification(message: notification)
					} catch {
						await display.notificationFailed(with: error, at: pollDate)
					}
				}

				previousPullRequest = pullRequest
			} catch is CancellationError {
				throw CancellationError()
			} catch {
				await display.pollFailed(with: error, at: pollDate)
			}

			try await Task.sleep(for: .seconds(interval))
		}
	}

	private func resolvePullRequest() async throws -> PullRequestReference {
		var arguments = ["pr", "view", pullRequest]
		if let repo {
			arguments.append(contentsOf: ["--repo", repo])
		}
		arguments.append(contentsOf: [
			"--json",
			"id,url",
		])

		let output = try await GitHubCLI().output(arguments)
		do {
			return try JSONDecoder().decode(PullRequestReference.self, from: Data(output.utf8))
		} catch {
			throw RuntimeError("Could not decode gh pr view output: \(error)")
		}
	}

	private func fetchPullRequest(
		reference: PullRequestReference
	) async throws -> PullRequest {
		let query = """
			query($id: ID!) {
			  node(id: $id) {
			    ... on PullRequest {
			      number
			      state
			      mergedAt
			      url
			      isInMergeQueue
			      mergeQueueEntry {
			        state
			        position
			        estimatedTimeToMerge
			      }
			      latestQueueRemoval: timelineItems(
			        last: 1
			        itemTypes: [REMOVED_FROM_MERGE_QUEUE_EVENT]
			      ) {
			        nodes {
			          ... on RemovedFromMergeQueueEvent {
			            id
			            reason
			          }
			        }
			      }
			    }
			  }
			}
			"""
		let output = try await GitHubCLI().output([
			"api",
			"graphql",
			"--hostname",
			reference.host,
			"-f",
			"query=\(query)",
			"-f",
			"id=\(reference.id)",
			"--jq",
			".data.node",
		])

		do {
			return try JSONDecoder().decode(PullRequest.self, from: Data(output.utf8))
		} catch {
			throw RuntimeError("Could not decode gh api output: \(error)")
		}
	}

	private func postNotification(message: String) async throws {
		let script = """
			on run arguments
				display notification (item 1 of arguments) with title "PR Watch" sound name "Purr"
			end run
			"""
		let result: ExecutionResult<
			Void,
			StringOutput<Unicode.UTF8>,
			StringOutput<Unicode.UTF8>,
		>
		do {
			result = try await Subprocess.run(
				.path(FilePath("/usr/bin/osascript")),
				arguments: ["-e", script, message],
				output: .string(limit: 64 * 1024),
				error: .string(limit: 64 * 1024),
			)
		} catch {
			throw RuntimeError("Could not run osascript: \(error)")
		}

		guard result.terminationStatus.isSuccess else {
			let error = result.standardError?
				.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
			throw RuntimeError(error.isEmpty ? "osascript failed." : error)
		}
	}
}
