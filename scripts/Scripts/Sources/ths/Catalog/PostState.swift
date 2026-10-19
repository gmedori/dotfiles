import Escape

// MARK: - Post State

/// Where a post stands between the vault and the site repo.
///
/// `Catalog` gives every blog post note, and every bundle `ths` manages, exactly one state.
/// `status` reports the states, and `sync` acts on them. The states come from comparing three
/// things: the bundle `ths` would generate from the note now, the bundle on disk, and the
/// `generatedHash` stored in the bundle on disk, which is the hash of the bundle as `ths` last wrote
/// it.
///
/// Six states are fine and only say what `sync` will do. The other five are problems: `sync` skips
/// them, reports them, and exits 1, but still handles every other post. Every `switch` over this
/// enum is exhaustive, so a new state has to be handled everywhere.
enum PostState: CaseIterable, Sendable {
	/// The note is a blog post with no `status`, so it stays in the vault. Ideas and unfinished
	/// posts sit here until they get a status, and canceled posts end up here once their bundle is
	/// deleted. It isn't checked for anything the site needs, and `sync` leaves it alone. If a bundle
	/// `ths` manages has the same slug as a post with no status, that bundle shows up separately as
	/// orphaned.
	case vaultOnly

	/// The post has a status and passes every check, but its bundle doesn't exist yet. This is a
	/// post's state the first time it gets a status, and after its bundle is deleted by hand to clear
	/// a conflict or a hand edit. `sync` creates the bundle.
	case new

	/// The bundle on disk is exactly what `ths` would generate from the note now. `sync` leaves it
	/// alone, except to rewrite the stored hash when the bundle was edited by hand and the same
	/// edit was then made in the vault.
	case upToDate

	/// The note changed after the last sync, and nobody touched the bundle since: the bundle on disk
	/// still matches its stored hash, but generating it now gives different files. Editing the post
	/// in the vault, or moving or renaming its note, does this. `sync` rewrites the bundle.
	case stale

	/// The note's status is `canceled`, and its bundle is still in the site repo. Setting a post's
	/// status to `canceled` is how it's taken down. `sync` deletes the bundle, and the post is then
	/// `vaultOnly`. Deleting a published bundle takes its URL off the site, so `status` and `sync`
	/// warn that the URL needs a redirect, but the deletion goes ahead: the canceled status says the
	/// post should come down.
	case canceled

	/// A draft bundle `ths` manages whose slug no post with a status claims anymore. Removing a
	/// draft's status, changing its slug, or deleting its note does this. A draft has no public URL,
	/// so `sync` deletes the bundle.
	case orphanedDraft

	/// Problem. The bundle on disk was changed outside `ths` after the last sync: its files no longer
	/// match the stored hash, and they also differ from what the vault would generate now. Usually a
	/// hand edit in the site repo, by a person or an agent, a file added to the bundle, or a bundle
	/// restored from an older commit. `sync` skips the bundle so the change isn't lost. Moving the
	/// change into the vault note, discarding it with `git restore`, or deleting the bundle clears it
	/// on the next sync.
	case edited

	/// Problem. A bundle `ths` doesn't manage, one without `params.vaultSource`, uses this post's
	/// slug. Usually a bundle written by hand before `ths` existed, or a new post reusing the slug of
	/// a page made by hand. `sync` skips the post and never touches the bundle. If the bundle is an
	/// older copy of the post, deleting it lets the next sync create the managed one. Otherwise the
	/// post needs a different slug.
	case conflict

	/// Problem. The note has at least one issue that blocks it, like a missing slug, a wiki link, or,
	/// on a published post, a TODO. `sync` skips the post and leaves its existing bundle, if any, as
	/// it is. Each issue says what to change in the note.
	case invalid

	/// Problem. A published bundle `ths` manages whose slug no post with a status claims anymore.
	/// Changing a published post's slug, removing its status, removing its `type`, or deleting or
	/// moving its note out of the source directory does this. Deleting the bundle would break a
	/// public URL, so `sync` never does. Restoring the old slug, status, or note clears it. If the post
	/// should come down, restore its note and slug and set its status to `canceled`.
	case orphanedPublished

	/// Problem. The note's status is `draft`, but its bundle is published. Setting a published post
	/// back to draft does this. Rewriting the bundle as a draft would take the post off the site and
	/// break its URL, so `sync` skips it. Setting the status back to `published` clears it. If the post
	/// should come down, set its status to `canceled` instead.
	case retracted

	/// Whether the state is a problem, which makes `status` and `sync` exit 1.
	var isProblem: Bool {
		switch self {
			case .vaultOnly, .new, .upToDate, .stale, .canceled, .orphanedDraft:
				false
			case .edited, .conflict, .invalid, .orphanedPublished, .retracted:
				true
		}
	}

	/// The word `status` prints for the state.
	var label: String {
		switch self {
			case .vaultOnly: "vault only"
			case .new: "new"
			case .upToDate: "up to date"
			case .stale: "stale"
			case .canceled: "canceled"
			case .orphanedDraft: "orphaned draft"
			case .edited: "edited"
			case .conflict: "conflict"
			case .invalid: "invalid"
			case .orphanedPublished: "orphaned published"
			case .retracted: "retracted"
		}
	}

	/// The color the state's label is printed in: gray when there's nothing to do, green for a bundle
	/// to create, cyan for one to rewrite, magenta for one to delete, and red for a problem.
	var color: Color {
		switch self {
			case .vaultOnly, .upToDate: .brightBlack
			case .new: .green
			case .stale: .cyan
			case .canceled, .orphanedDraft: .magenta
			case .edited, .conflict, .invalid, .orphanedPublished, .retracted: .red
		}
	}

	/// One line on what the state means, for the `status` help.
	var summary: String {
		switch self {
			case .vaultOnly: "Has no status, or was canceled. Stays in the vault."
			case .new: "Has a status but no bundle yet. sync creates it."
			case .upToDate: "The bundle matches the vault. Nothing to do."
			case .stale: "The vault changed since the last sync. sync rewrites it."
			case .canceled: "Canceled, and its bundle still exists. sync deletes it."
			case .orphanedDraft: "A draft bundle no post claims. sync deletes it."
			case .edited: "The bundle was changed outside ths. Skipped."
			case .conflict: "A bundle ths didn't make has the post's slug. Skipped."
			case .invalid: "The note has issues that block it. Skipped."
			case .orphanedPublished: "A published bundle no post claims. Never deleted."
			case .retracted: "Back to draft, but its bundle is published. Skipped."
		}
	}
}
