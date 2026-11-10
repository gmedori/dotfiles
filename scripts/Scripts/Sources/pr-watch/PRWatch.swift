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
		help: "Select another repository using the [HOST/]OWNER/REPO format"
	)
	var repo: String?

	@Option(
		name: [.customShort("i"), .customLong("interval")],
		help: "The number of seconds between polls"
	)
	var interval: Int = 10

	func validate() throws {
		guard interval > 0 else {
			throw ValidationError("The polling interval must be greater than zero.")
		}
	}

	func run() async throws {
		let display = PollDisplay()
		let loadingTask = echoLoadingText(
			loop: .weeee,
			writesNewlineOnCancellation: false
		) { symbol in
			await display.line(symbol: symbol)
		}

		let mergedPullRequest: PullRequest
		do {
			mergedPullRequest = try await waitForMerge(display: display)
		} catch {
			loadingTask.cancel()
			await loadingTask.value
			clearLine()
			throw error
		}

		loadingTask.cancel()
		await loadingTask.value
		clearLine()
		echo(await display.line(symbol: "✓"), "\n")
		print(mergedPullRequest.url)

		try await postNotification(
			message: "PR \(mergedPullRequest.number) has merged"
		)
	}

	private func waitForMerge(display: PollDisplay) async throws -> PullRequest {
		var reference: PullRequestReference?
		var previousPullRequest: PullRequest?

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

				if let previousPullRequest,
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

		let output = try await runGH(arguments: arguments)
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
		let output = try await runGH(arguments: [
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

	private func runGH(arguments: [String]) async throws -> String {
		let result: ExecutionResult<
			Void,
			StringOutput<Unicode.UTF8>,
			StringOutput<Unicode.UTF8>
		>
		do {
			result = try await Subprocess.run(
				.name("gh"),
				arguments: Arguments(arguments),
				output: .string(limit: 64 * 1024),
				error: .string(limit: 64 * 1024)
			)
		} catch {
			throw RuntimeError(
				"Could not run gh. Make sure GitHub CLI is installed and available in PATH: \(error)"
			)
		}

		guard result.terminationStatus.isSuccess else {
			let error = result.standardError?
				.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
			throw RuntimeError(error.isEmpty ? "gh failed." : error)
		}

		return result.standardOutput ?? ""
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
			StringOutput<Unicode.UTF8>
		>
		do {
			result = try await Subprocess.run(
				.path(FilePath("/usr/bin/osascript")),
				arguments: ["-e", script, message],
				output: .string(limit: 64 * 1024),
				error: .string(limit: 64 * 1024)
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

private struct PullRequestReference: Decodable, Sendable {
	let id: String
	let url: String

	var host: String {
		URL(string: url)?.host ?? "github.com"
	}
}

private struct PullRequest: Decodable, Sendable {
	let number: Int
	let state: String
	let mergedAt: String?
	let url: String
	let isInMergeQueue: Bool
	let mergeQueueEntry: MergeQueueEntry?
	let latestQueueRemoval: QueueRemovalConnection

	var displayState: PullRequestState {
		if mergedAt != nil || state.uppercased() == "MERGED" {
			return .merged
		}
		if isInMergeQueue {
			return .queued(mergeQueueEntry)
		}
		if let removal = latestRemoval {
			return .removedFromQueue(removal.reason)
		}

		switch state.uppercased() {
			case "OPEN": return .open
			case "CLOSED": return .closed
			default: return .unknown
		}
	}

	var isMerged: Bool {
		mergedAt != nil || state.uppercased() == "MERGED"
	}

	var latestRemoval: QueueRemoval? {
		latestQueueRemoval.nodes.compactMap { $0 }.last
	}

	func queueRemovalNotification(after previous: PullRequest) -> String? {
		guard !isMerged, !isInMergeQueue else {
			return nil
		}
		let newRemoval = latestRemoval?.id != previous.latestRemoval?.id
			? latestRemoval
			: nil
		guard previous.isInMergeQueue || newRemoval != nil else {
			return nil
		}

		let prefix = "PR \(number) left the merge queue"
		guard let reason = newRemoval?.reason,
			!reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
		else {
			return prefix
		}
		return "\(prefix): \(singleLine(reason, limit: 180))"
	}
}

private struct MergeQueueEntry: Decodable, Sendable {
	let state: String
	let position: Int
	let estimatedTimeToMerge: Int?
}

private struct QueueRemovalConnection: Decodable, Sendable {
	let nodes: [QueueRemoval?]
}

private struct QueueRemoval: Decodable, Sendable {
	let id: String
	let reason: String?
}

private enum PullRequestState: Sendable {
	case open
	case closed
	case merged
	case queued(MergeQueueEntry?)
	case removedFromQueue(String?)
	case unknown

	var label: String {
		switch self {
			case .open: "open"
			case .closed: "closed"
			case .merged: "merged"
			case .queued(let entry): queueLabel(entry: entry)
			case .removedFromQueue(let reason): removalLabel(reason: reason)
			case .unknown: "unknown"
		}
	}

	var color: Color {
		switch self {
			case .open: .green
			case .closed: .red
			case .merged: .magenta
			case .queued: .cyan
			case .removedFromQueue: .red
			case .unknown: .yellow
		}
	}

	private func queueLabel(entry: MergeQueueEntry?) -> String {
		guard let entry else {
			return "queued"
		}
		var details = [
			"position \(entry.position)",
			queueStateLabel(entry.state),
		]
		if let estimatedTimeToMerge = entry.estimatedTimeToMerge {
			details.append("~\(formattedDuration(estimatedTimeToMerge))")
		}
		return "queued (\(details.joined(separator: ", ")))"
	}

	private func queueStateLabel(_ state: String) -> String {
		if state.uppercased() == "AWAITING_CHECKS" {
			return "checks in progress"
		}
		return state.lowercased().replacingOccurrences(of: "_", with: " ")
	}

	private func formattedDuration(_ totalSeconds: Int) -> String {
		let totalSeconds = max(0, totalSeconds)
		let hours = totalSeconds / 3_600
		let minutes = totalSeconds % 3_600 / 60
		let seconds = totalSeconds % 60

		if hours > 0 {
			return "\(hours)h \(minutes)m \(seconds)s"
		}
		if minutes > 0 {
			return "\(minutes)m \(seconds)s"
		}
		return "\(seconds)s"
	}

	private func removalLabel(reason: String?) -> String {
		guard let reason,
			!reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
		else {
			return "removed from merge queue"
		}
		return "removed from merge queue: \(singleLine(reason, limit: 120))"
	}
}

private actor PollDisplay {
	private var pullRequest: PullRequest?
	private var lastPollDate: Date?
	private var operationError: (kind: String, message: String)?
	private let dateFormatter: DateFormatter = {
		let formatter = DateFormatter()
		formatter.locale = Locale(identifier: "en_US_POSIX")
		formatter.dateFormat = "yyyy-MM-dd HH:mm:ss zzz"
		return formatter
	}()

	func pollStarted(at date: Date) {
		lastPollDate = date
		operationError = nil
	}

	func pollSucceeded(with pullRequest: PullRequest, at date: Date) {
		self.pullRequest = pullRequest
		lastPollDate = date
		operationError = nil
	}

	func pollFailed(with error: any Error, at date: Date) {
		lastPollDate = date
		operationError = (
			kind: "poll error",
			message: singleLine(String(describing: error), limit: 160)
		)
	}

	func notificationFailed(with error: any Error, at date: Date) {
		lastPollDate = date
		operationError = (
			kind: "notification error",
			message: singleLine(String(describing: error), limit: 160)
		)
	}

	func line(symbol: String) -> String {
		let state = pullRequest?.displayState ?? .unknown
		let description = if let pullRequest {
			"PR #\(pullRequest.number): \(state.label)"
		} else {
			"PR: \(state.label)"
		}
		let status = colorize(
			"\(symbol) \(description)",
			foreground: state.color
		)

		let detail: String
		if let operationError, let lastPollDate {
			detail = colorize(
				"\(operationError.kind) \(formatted(lastPollDate)): \(operationError.message)",
				foreground: .red
			)
		} else if let lastPollDate {
			detail = "last poll \(formatted(lastPollDate))"
		} else {
			detail = "waiting for first poll"
		}

		return "\(status) - \(detail)"
	}

	private func formatted(_ date: Date) -> String {
		dateFormatter.string(from: date)
	}
}

private func singleLine(_ text: String, limit: Int) -> String {
	let text = text
		.split(whereSeparator: \.isWhitespace)
		.joined(separator: " ")
	guard text.count > limit else {
		return text
	}
	return "\(text.prefix(limit))…"
}
