import CommandKit
import Foundation

/// Reads the tags of a repository in Amazon ECR Public, with the anonymous token the registry hands
/// out for public images.
struct PublicECRClient: Sendable {
	/// Every tag in `repository`.
	func tags(in repository: PublicECRRepository) async throws -> [String] {
		let tokenResponse: TokenResponse = try await get(Self.url(path: "/token/"))
		guard !tokenResponse.token.isEmpty else {
			throw RuntimeError("Public ECR returned an empty authorization token.")
		}

		let response: TagsResponse = try await get(
			repository.tagsURL,
			authorization: "Bearer \(tokenResponse.token)",
		)
		return response.tags ?? []
	}
}

// MARK: - Supporting Types

extension PublicECRClient {
	/// The registry's response to a request for a token.
	struct TokenResponse: Decodable {
		/// The anonymous token for reading public repositories.
		var token: String
	}

	/// The registry's response to a request for a repository's tags.
	struct TagsResponse: Decodable {
		/// The repository's tags. The registry leaves the key out for a repository without tags, and
		/// this type mirrors the response, so it's optional.
		// swiftlint:disable:next discouraged_optional_collection
		var tags: [String]? = nil
	}
}

// MARK: - Static Members

extension PublicECRClient {
	/// The `public.ecr.aws` URL with `path`.
	static func url(path: String) throws -> URL {
		var components = URLComponents()
		components.scheme = "https"
		components.host = "public.ecr.aws"
		components.path = path
		guard let url = components.url else {
			throw RuntimeError("Could not build a Public ECR URL for \(path).")
		}

		return url
	}
}

// MARK: - Private Helpers

extension PublicECRClient {
	private func get<Response: Decodable>(
		_ url: URL,
		authorization: String? = nil,
	) async throws -> Response {
		var request = URLRequest(url: url)
		if let authorization {
			request.setValue(authorization, forHTTPHeaderField: "Authorization")
		}

		let data: Data
		let response: URLResponse
		do {
			(data, response) = try await URLSession.shared.data(for: request)
		} catch {
			throw RuntimeError("Could not query Public ECR: \(error)")
		}

		guard
			let httpResponse = response as? HTTPURLResponse,
			(200 ..< 300).contains(httpResponse.statusCode)
		else {
			let status = (response as? HTTPURLResponse)?.statusCode
				.description ?? "unknown"
			throw RuntimeError("Public ECR returned HTTP \(status).")
		}

		do {
			return try JSONDecoder().decode(Response.self, from: data)
		} catch {
			throw RuntimeError("Could not decode the Public ECR response: \(error)")
		}
	}
}
