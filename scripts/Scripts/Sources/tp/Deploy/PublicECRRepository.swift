import ArgumentParser
import Foundation

/// A repository in Amazon ECR Public, read from an image repository like
/// `public.ecr.aws/gravitational-staging/teleport-ent-distroless`.
struct PublicECRRepository: Equatable, Sendable {
	/// The registry's alias, the part after `public.ecr.aws/`.
	let registryAlias: String
	/// The repository's name in the registry, which can hold slashes.
	let repositoryName: String
	/// The registry API's URL for the repository's tags.
	let tagsURL: URL

	init(_ imageRepository: String) throws {
		let prefix = "public.ecr.aws/"
		guard imageRepository.hasPrefix(prefix) else {
			throw ValidationError(
				"Automatic tag resolution requires a repository beginning with \(prefix)."
			)
		}

		let path = imageRepository.dropFirst(prefix.count)
		guard let separator = path.firstIndex(of: "/") else {
			throw ValidationError("Public ECR repository is missing a repository name.")
		}

		self.registryAlias = String(path[..<separator])
		self.repositoryName = String(path[path.index(after: separator)...])
		guard !registryAlias.isEmpty, !repositoryName.isEmpty else {
			throw ValidationError("Public ECR repository is malformed: \(imageRepository)")
		}

		self.tagsURL = try PublicECRClient.url(path: "/v2/\(registryAlias)/\(repositoryName)/tags/list")
	}
}
