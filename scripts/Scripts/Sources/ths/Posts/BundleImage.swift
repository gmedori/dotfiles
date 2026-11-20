import Foundation

/// An image copied from the vault into a post's bundle.
struct BundleImage: Equatable, Sendable {
	/// The image file in the vault.
	var source: URL
	/// The file name in the bundle, which the Markdown refers to.
	var name: String
}
