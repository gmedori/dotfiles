import ArgumentParser

// MARK: - Deploy

/// A placeholder until the site is set up on Cloudflare. The help text lists what the real command
/// has to do, so whoever builds it starts from the requirements.
struct Deploy: AsyncParsableCommand {
	static let configuration = CommandConfiguration(
		abstract: "Builds the site and deploys it to Cloudflare. Not implemented yet.",
		discussion: """
		REQUIREMENTS
		  - Depends on the site being set up on Cloudflare Workers with static
		    assets, and on `wrangler`. Wrangler runs on Node.js, but nothing in the
		    site repo may depend on Node.
		  - Refuses to deploy when `ths status` reports any problem or pending
		    change, when the site repo has uncommitted changes, or when HEAD isn't
		    on main.
		  - Runs `hugo --gc --minify --cleanDestinationDir` in the site repo and
		    stops on any warning or error.
		  - Prints what's about to be deployed, and runs `wrangler deploy` only
		    after confirmation. --yes skips the confirmation.
		  - Exits 0 on success, and 1 when it refuses or fails.
		""",
	)

	func run() async throws {
		print("Not implemented. See `ths deploy --help` for its requirements.")
		throw ExitCode.failure
	}
}
