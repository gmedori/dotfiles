import Foundation
import Testing
@testable import tp

@Suite("deploy nightly tag resolution")
struct DeployNightlyTagResolverTests {
	@Test("Selects the newest matching nightly")
	func selectsNewestNightly() {
		let tags = [
			"19.0.0-prealpha.2-nightly20260817-1-master",
			"19.0.0-prealpha.2-nightly20260916-1-master",
			"19.0.0-prealpha.1-nightly20260920-1-master",
		]

		#expect(
			NightlyTagResolver.newestTag(
				for: "19.0.0-prealpha.2",
				from: tags
			) == "19.0.0-prealpha.2-nightly20260916-1-master"
		)
	}

	@Test("Accepts commit and branch suffixes")
	func acceptsPublishedSuffixes() {
		let tags = [
			"19.0.0-prealpha.2-nightly20260915-1-6c1e6e25",
			"19.0.0-prealpha.2-nightly20260916-1-master",
		]

		#expect(
			NightlyTagResolver.newestTag(
				for: "19.0.0-prealpha.2",
				from: tags
			) == "19.0.0-prealpha.2-nightly20260916-1-master"
		)
	}

	@Test("Uses numeric build ordering")
	func usesNumericBuildOrdering() {
		let tags = [
			"19.0.0-prealpha.2-nightly20260916-2-master",
			"19.0.0-prealpha.2-nightly20260916-10-master",
		]

		#expect(
			NightlyTagResolver.newestTag(
				for: "19.0.0-prealpha.2",
				from: tags
			) == "19.0.0-prealpha.2-nightly20260916-10-master"
		)
	}

	@Test("Prefers master for otherwise equal tags")
	func prefersMaster() {
		let tags = [
			"19.0.0-prealpha.2-nightly20260916-1-feat",
			"19.0.0-prealpha.2-nightly20260916-1-master",
		]

		#expect(
			NightlyTagResolver.newestTag(
				for: "19.0.0-prealpha.2",
				from: tags
			) == "19.0.0-prealpha.2-nightly20260916-1-master"
		)
	}

	@Test("Ignores malformed nightlies")
	func ignoresMalformedTags() {
		let tags = [
			"19.0.0-prealpha.2",
			"19.0.0-prealpha.2-nightly2026091-1-master",
			"19.0.0-prealpha.2-nightly20260916-master",
		]

		#expect(
			NightlyTagResolver.newestTag(
				for: "19.0.0-prealpha.2",
				from: tags
			) == nil
		)
	}
}

@Suite("Public ECR repository parsing")
struct PublicECRRepositoryTests {
	@Test("Parses a registry alias and nested repository")
	func parsesRepository() throws {
		let repository = try PublicECRRepository(
			"public.ecr.aws/gravitational-staging/team/teleport-ent-distroless"
		)

		#expect(repository.registryAlias == "gravitational-staging")
		#expect(repository.repositoryName == "team/teleport-ent-distroless")
		#expect(
			repository.tagsURL.absoluteString
				== "https://public.ecr.aws/v2/gravitational-staging/team/teleport-ent-distroless/tags/list"
		)
	}

	@Test("Rejects a non-public repository")
	func rejectsNonPublicRepository() {
		#expect(throws: (any Error).self) {
			_ = try PublicECRRepository("example.com/teleport-ent-distroless")
		}
	}
}

@Suite("Teleport checkout")
struct TeleportCheckoutTests {
	@Test("Resolves the root and enterprise directories")
	func resolvesDirectories() throws {
		let fixture = try TeleportCheckoutFixture()
		defer { fixture.remove() }

		let checkout = try TeleportCheckout(path: fixture.root.path)

		#expect(checkout.rootDirectory.path == fixture.root.path)
		#expect(checkout.enterpriseDirectory.path == fixture.root.appending(path: "e").path)
	}

	@Test("Rejects a directory without the enterprise deploy script")
	func rejectsIncompleteCheckout() throws {
		let root = FileManager.default.temporaryDirectory
			.appending(path: "tp-checkout-tests-\(UUID().uuidString)")
		try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
		defer { try? FileManager.default.removeItem(at: root) }
		#expect(FileManager.default.createFile(
			atPath: root.appending(path: "Makefile").path,
			contents: Data()
		))

		#expect(throws: (any Error).self) {
			_ = try TeleportCheckout(path: root.path)
		}
	}
}

private struct TeleportCheckoutFixture {
	let root: URL

	init() throws {
		root = FileManager.default.temporaryDirectory
			.appending(path: "tp-checkout-tests-\(UUID().uuidString)")
		let scripts = root.appending(path: "e/scripts", directoryHint: .isDirectory)
		try FileManager.default.createDirectory(at: scripts, withIntermediateDirectories: true)
		guard FileManager.default.createFile(
			atPath: root.appending(path: "Makefile").path,
			contents: Data()
		), FileManager.default.createFile(
			atPath: scripts.appending(path: "deploy-cloud.sh").path,
			contents: Data()
		) else {
			throw TeleportCheckoutFixtureError.couldNotCreateFiles
		}
	}

	func remove() {
		try? FileManager.default.removeItem(at: root)
	}
}

private enum TeleportCheckoutFixtureError: Error {
	case couldNotCreateFiles
}
