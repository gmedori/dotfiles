import Foundation

/// A pull request as `gh api graphql` returns it, with the merge queue fields `pr-watch` polls.
struct PullRequest: Decodable, Sendable {
	/// The pull request's number in its repository.
	var number: Int
	/// GitHub's state for it, like `OPEN`, `CLOSED`, or `MERGED`.
	var state: String
	/// When it merged, or `nil` when it hasn't.
	var mergedAt: String? = nil
	/// The pull request's web URL.
	var url: String
	/// Whether it's in the merge queue now.
	var isInMergeQueue: Bool
	/// Its entry in the merge queue, or `nil` when it isn't queued.
	var mergeQueueEntry: MergeQueueEntry? = nil
	/// The last time it was removed from the merge queue, if it ever was.
	var latestQueueRemoval: QueueRemovalConnection

	/// The state `pr-watch` shows, which puts merging and the merge queue ahead of GitHub's `state`.
	var displayState: PullRequestState {
		if isMerged {
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

	/// Whether the pull request has merged.
	var isMerged: Bool {
		mergedAt != nil || state.uppercased() == "MERGED"
	}

	/// The last removal from the merge queue, or `nil` when it was never removed.
	var latestRemoval: QueueRemoval? {
		latestQueueRemoval.nodes.compactMap(\.self).last
	}

	/// The text of a notification that the pull request left the merge queue after `previous` was
	/// polled, or `nil` when it didn't leave.
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
		guard
			let reason = newRemoval?.reason,
			!reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
		else {
			return prefix
		}

		return "\(prefix): \(reason.singleLine(limit: Self.notificationReasonLimit))"
	}
}

// MARK: - Supporting Types

extension PullRequest {
	/// A pull request's place in the merge queue.
	struct MergeQueueEntry: Decodable, Sendable {
		/// The entry's state, like `AWAITING_CHECKS`.
		var state: String
		/// The entry's position in the queue.
		var position: Int
		/// GitHub's estimate of the seconds until it merges, or `nil` when there's none.
		var estimatedTimeToMerge: Int? = nil
	}

	/// The timeline connection that holds the last removal from the merge queue.
	struct QueueRemovalConnection: Decodable, Sendable {
		/// The removal events, any of which can be `null` in GitHub's response.
		var nodes: [QueueRemoval?]
	}

	/// A time the pull request was removed from the merge queue.
	struct QueueRemoval: Decodable, Sendable {
		/// The event's ID, which tells one removal from the next.
		var id: String
		/// Why the pull request was removed, or `nil` when GitHub didn't say.
		var reason: String? = nil
	}
}

// MARK: - Static Members

extension PullRequest {
	/// The most characters of a removal reason that a notification shows.
	static let notificationReasonLimit = 180
}
