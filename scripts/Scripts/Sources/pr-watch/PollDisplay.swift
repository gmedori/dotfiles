import CommandKit
import Foundation

/// The status line `pr-watch` redraws while it waits, with what the last poll found.
actor PollDisplay {
	private var pullRequest: PullRequest? = nil
	private var lastPollDate: Date? = nil
	private var operationError: (kind: String, message: String)? = nil
	private let dateFormatter: DateFormatter = {
		let formatter = DateFormatter()
		formatter.locale = Locale(identifier: "en_US_POSIX")
		formatter.dateFormat = "yyyy-MM-dd HH:mm:ss zzz"
		return formatter
	}()

	/// Records that a poll started at `date`, which clears the last poll's error.
	func pollStarted(at date: Date) {
		lastPollDate = date
		operationError = nil
	}

	/// Records what a poll at `date` found.
	func pollSucceeded(with pullRequest: PullRequest, at date: Date) {
		self.pullRequest = pullRequest
		lastPollDate = date
		operationError = nil
	}

	/// Records that the poll at `date` failed with `error`.
	func pollFailed(with error: any Error, at date: Date) {
		lastPollDate = date
		operationError = (
			kind: "poll error",
			message: String(describing: error).singleLine(limit: Self.errorMessageLimit),
		)
	}

	/// Records that a notification after the poll at `date` failed with `error`.
	func notificationFailed(with error: any Error, at date: Date) {
		lastPollDate = date
		operationError = (
			kind: "notification error",
			message: String(describing: error).singleLine(limit: Self.errorMessageLimit),
		)
	}

	/// The status line, starting with `symbol`.
	func line(symbol: String) -> String {
		let state = pullRequest?.displayState ?? .unknown
		let description = if let pullRequest {
			"PR #\(pullRequest.number): \(state.label)"
		} else {
			"PR: \(state.label)"
		}
		let status = "\(symbol) \(description)".colorized(foreground: state.color)

		let detail = if let operationError, let lastPollDate {
			"\(operationError.kind) \(formatted(lastPollDate)): \(operationError.message)".colorized(foreground: .red)
		} else if let lastPollDate {
			"last poll \(formatted(lastPollDate))"
		} else {
			"waiting for first poll"
		}

		return "\(status) - \(detail)"
	}
}

// MARK: - Static Members

extension PollDisplay {
	/// The most characters of an error that the status line shows.
	static let errorMessageLimit = 160
}

// MARK: - Private Helpers

extension PollDisplay {
	private func formatted(_ date: Date) -> String {
		dateFormatter.string(from: date)
	}
}
