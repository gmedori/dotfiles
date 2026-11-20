import CommandKit
import Foundation

/// What `pr-watch` shows a pull request as, with the details each state needs.
enum PullRequestState: Sendable {
	/// Open, and not in the merge queue.
	case open
	/// Closed without merging.
	case closed
	/// Merged, which ends the watch.
	case merged
	/// In the merge queue, with its entry when GitHub reports one.
	case queued(PullRequest.MergeQueueEntry?)
	/// Removed from the merge queue, with GitHub's reason when it gives one.
	case removedFromQueue(String?)
	/// A state `pr-watch` doesn't know, or the state before the first poll.
	case unknown

	/// The state's description in the status line.
	var label: String {
		switch self {
			case .open: "open"
			case .closed: "closed"
			case .merged: "merged"
			case let .queued(entry): queueLabel(entry: entry)
			case let .removedFromQueue(reason): removalLabel(reason: reason)
			case .unknown: "unknown"
		}
	}

	/// The color the status line is printed in.
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
}

// MARK: - Static Members

extension PullRequestState {
	/// The most characters of a removal reason that the status line shows.
	static let reasonLimit = 120
}

// MARK: - Private Helpers

extension PullRequestState {
	private func queueLabel(entry: PullRequest.MergeQueueEntry?) -> String {
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
		let hours = totalSeconds / 3600
		let minutes = totalSeconds % 3600 / 60
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
		guard
			let reason,
			!reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
		else {
			return "removed from merge queue"
		}

		return "removed from merge queue: \(reason.singleLine(limit: Self.reasonLimit))"
	}
}
