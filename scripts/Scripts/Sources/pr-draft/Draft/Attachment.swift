/// An image or video that a draft's body embeds, staged for `gh pr create --attach`.
struct Attachment: Codable, Equatable, Sendable {
	/// The attachment's number, counting from 1 in the order the files first appear in the body.
	var number: Int
	/// Whether it's an image or a video.
	var kind: Kind
	/// The file's path from the vault root.
	var source: String
	/// The staged copy's path from the staging folder, like `./01-share-sheet.png`. The body refers
	/// to the file by this path, and `gh` replaces it with the upload's URL.
	var staged: String
	/// The image's alt text. Videos have none.
	var alt: String? = nil
	/// Where `alt` came from.
	var altFrom: AltSource? = nil

	/// The value for `gh --attach`, which is the staged path with the alt text after a `#`.
	var attachArgument: String {
		alt.map { "\(staged)#\($0)" } ?? staged
	}
}

// MARK: - Supporting Types

extension Attachment {
	/// Whether an attachment is an image or a video, which decides how GitHub shows it.
	enum Kind: String, Codable, Sendable {
		/// An image, which GitHub shows inline.
		case image
		/// A video, which GitHub shows as a player when its link is a paragraph of its own.
		case video
	}

	/// Where an image's alt text came from.
	enum AltSource: String, Codable, Sendable {
		/// The `--alt` option of `prepare`.
		case option = "--alt"
		/// The embed, after the `|` in `![[shot.png|Alt text]]` or in the brackets of a Markdown image.
		case embed
		/// The bold label line directly above the embed.
		case label
	}
}
