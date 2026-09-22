import ArgumentParser
import CommandKit
import Foundation

struct PublicECRRepository: Equatable, Sendable {
	let registryAlias: String
	let repositoryName: String

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

		registryAlias = String(path[..<separator])
		repositoryName = String(path[path.index(after: separator)...])
		guard !registryAlias.isEmpty, !repositoryName.isEmpty else {
			throw ValidationError("Public ECR repository is malformed: \(imageRepository)")
		}
	}

	var tagsURL: URL {
		var components = URLComponents()
		components.scheme = "https"
		components.host = "public.ecr.aws"
		components.path = "/v2/\(registryAlias)/\(repositoryName)/tags/list"
		return components.url!
	}
}

struct PublicECRClient: Sendable {
	func tags(in repository: PublicECRRepository) async throws -> [String] {
		let tokenResponse: TokenResponse = try await get(
			URL(string: "https://public.ecr.aws/token/")!
		)
		guard !tokenResponse.token.isEmpty else {
			throw RuntimeError("Public ECR returned an empty authorization token.")
		}

		let response: TagsResponse = try await get(
			repository.tagsURL,
			authorization: "Bearer \(tokenResponse.token)"
		)
		return response.tags ?? []
	}

	private func get<Response: Decodable>(
		_ url: URL,
		authorization: String? = nil
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

		guard let httpResponse = response as? HTTPURLResponse,
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

enum NightlyTagResolver {
	static func newestTag(for version: String, from tags: [String]) -> String? {
		return tags.compactMap { NightlyTag(version: version, tag: $0) }
			.max()?.tag
	}
}

private struct NightlyTag: Comparable {
	let tag: String
	let date: String
	let build: Int
	let source: String

	init?(version: String, tag: String) {
		let prefix = "\(version)-nightly"
		guard tag.hasPrefix(prefix) else {
			return nil
		}

		let suffix = tag.dropFirst(prefix.count)
		let parts = suffix.split(separator: "-", omittingEmptySubsequences: false)
		guard parts.count >= 3,
			parts[0].count == 8,
			parts[0].allSatisfy(\.isNumber),
			let build = Int(parts[1])
		else {
			return nil
		}

		let source = parts.dropFirst(2).joined(separator: "-")
		guard !source.isEmpty else {
			return nil
		}

		self.tag = tag
		date = String(parts[0])
		self.build = build
		self.source = source
	}

	static func < (lhs: NightlyTag, rhs: NightlyTag) -> Bool {
		if lhs.date != rhs.date {
			return lhs.date < rhs.date
		}
		if lhs.build != rhs.build {
			return lhs.build < rhs.build
		}
		if (lhs.source == "master") != (rhs.source == "master") {
			return lhs.source != "master"
		}
		return lhs.tag < rhs.tag
	}
}

private struct TokenResponse: Decodable {
	let token: String
}

private struct TagsResponse: Decodable {
	let tags: [String]?
}
