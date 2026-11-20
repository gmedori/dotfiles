import ArgumentParser
import Escape
import Foundation
import Subprocess

@main
struct ChapterSplitter: AsyncParsableCommand {
	@Option(
		name: [.short, .customLong("input")],
		help: "The input MKV file to split",
	)
	var inputFile: String

	@Option(
		name: [.short, .customLong("output")],
		help: "The format of the output files; use %n to indicate where to place the number",
	)
	var outputFileFormat: String

	@Option(
		name: .shortAndLong,
		help: "The chapter number to begin splitting on, 1-indexed; any chapters before this are ignored",
	)
	var firstChapter: UInt

	@Option(
		name: [.customShort("s"), .customLong("step")],
		help: "The number of chapters to include in each video",
	)
	var chapterStep: UInt

	@Option(
		name: .shortAndLong,
		help: "The number of videos/episodes to make",
	)
	var numberOfEpisodes: UInt

	@Option(
		name: [.customShort("e"), .long],
		help: "The episode number to start with when labeling the output files",
	)
	var startingEpisodeNumber: UInt

	/// The chapters to split on, as comma-separated values ready for mkvmerge's `--split chapters:`.
	var chapterSplits: String {
		var splits: [UInt] = []
		var chapterCursor = firstChapter
		while splits.count < numberOfEpisodes {
			splits.append(chapterCursor)
			chapterCursor += chapterStep
		}
		return splits.map(String.init(_:)).joined(separator: ",")
	}

	func run() async throws {
		guard FileManager.default.fileExists(atPath: inputFile) else {
			print("Could not find file: \(inputFile)".colorized(foreground: .red))
			Self.exit(withError: ExitCode.failure)
		}

		print("Splitting input file on the following chapters: \(chapterSplits, foreground: .cyan)")

		print("Running mkvmerge...")
		let mkvmergeOutputFormat = "output-%03d.mkv"
		let result = try await Subprocess.run(
			.name("mkvmerge"),
			arguments: ["-o", mkvmergeOutputFormat, "--split", "chapters:\(chapterSplits)", inputFile],
			input: .standardInput,
			output: .currentStandardOutput,
			error: .currentStandardError,
		)

		guard result.terminationStatus.isSuccess else {
			print("❌ Failed to split file with mkvmerge".colorized(foreground: .red))
			Self.exit(withError: ExitCode.failure)
		}

		print("✅ Successfully ran mkvmerge; renaming intermediate files...".colorized(foreground: .green))

		var renameFailures: [RenameFailure] = []
		for fileNumber in 1 ... numberOfEpisodes {
			let episodeNumber = startingEpisodeNumber + fileNumber - 1
			let integerLength = episodeNumber <= 100 ? 2 : 4

			// mkvmerge pads the numbers of the files it splits into to three digits, as
			// `mkvmergeOutputFormat` asks.
			let formattedIntermediateFileNumber = fileNumber.formatted(
				.number
					.precision(.integerLength(3))
					.grouping(.never)
			)
			let intermediateTitle = "output-\(formattedIntermediateFileNumber).mkv"

			let formattedOutputNumber = episodeNumber.formatted(
				.number
					.precision(.integerLength(integerLength))
					.grouping(.never)
			)
			let episodeTitle = outputFileFormat.replacingOccurrences(of: "%n", with: formattedOutputNumber)
			Terminal.echo("Renaming \(intermediateTitle) to \(episodeTitle)... ")
			do {
				try FileManager.default.moveItem(atPath: intermediateTitle, toPath: episodeTitle)
				print("✅")
			} catch {
				renameFailures.append(
					RenameFailure(intermediateTitle: intermediateTitle, episodeTitle: episodeTitle, error: error)
				)
				print("❌")
			}
		}

		guard renameFailures.isEmpty else {
			for failure in renameFailures {
				print(
					"❌ Failed to rename \(failure.intermediateTitle) to \(failure.episodeTitle): \(String(describing: failure.error))"
				)
			}
			Self.exit(withError: ExitCode.failure)
		}

		print("✅ Successfully renamed all files".colorized(foreground: .green))
	}
}

// MARK: - Supporting Types

extension ChapterSplitter {
	/// A file from mkvmerge that couldn't be renamed for its episode.
	struct RenameFailure {
		/// The name mkvmerge gave the file.
		var intermediateTitle: String
		/// The name the episode's file should have had.
		var episodeTitle: String
		/// Why the rename failed.
		var error: any Error
	}
}
