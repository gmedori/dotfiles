# Repository Guidelines

This file is the source of truth for AI-assisted development in this repository.
`AGENTS.md` is a symlink to this file.

## Repository Overview

This repository contains local macOS command-line tools written in Swift 6. It
is organized as two sibling SwiftPM packages:

- `Escape/`: A library for terminal output, colors, and control sequences.
- `Scripts/`: Executable tools that depend on the local `Escape` package and
  `swift-subprocess`. Its `CommandKit` library target is what the tools use to
  run other commands, either raw through `Subprocess` or through a wrapper like
  `GitHubCLI` for `gh`.

`Scripts` currently builds `iosd`, `chapter-splitter`, `github-permalink`,
`notify`, `pr-watch`, `tp`, `ths`, `is-work-mac`, and `pr-draft`. `ths`
publishes The Honking Smith blog posts from the Obsidian vault to the website
repo. Its post states are documented on `PostState`. `is-work-mac` tells the
work Mac from personal Macs by MDM enrollment, and
`$HOME/dotfiles/agent-github/activate.sh` relies on its exit codes, so keep them
as documented in its help. `pr-draft` opens a pull request from a PR draft in
the vault, uploading its images and videos with `gh pr create --attach`. The
vault's submit-pr skill reads the JSON it prints, as its help says, so keep
the two in step.

There is no root `Package.swift`. Run SwiftPM commands against the relevant
package directory.

## Platform and Tooling

- Toolchain: the newest installed swift.org Swift 6.4.x, pinned in
  `mise.toml`. A shell with mise activated picks it up in this folder.
  Elsewhere, run SwiftPM through `mise exec --` from this folder, as the
  commands below do, or SwiftPM runs on Xcode's Swift instead.
- Swift tools version: 6.0 for `Escape`, 6.2 for `Scripts`
- Minimum platform: macOS 14
- Command-line parsing: `swift-argument-parser`
- Tests use Swift Testing syntax. `tpTests` and `thsTests` cover parts of `tp`
  and `ths`, `is-work-macTests` covers the parsing in `is-work-mac`,
  `pr-draftTests` covers `pr-draft` against a throwaway vault and a stand-in
  `gh`, and `CommandKitTests` covers `GitHubCLI`. Run them with
  `mise exec -- swift test --package-path Scripts`.
- Style: the Swift style guide, enforced by SwiftFormat and SwiftLint as
  described under Formatting and Linting.

## Build and Validation

Build the affected package:

```sh
mise exec -- swift build --package-path Escape
mise exec -- swift build --package-path Scripts
```

After changing `Escape`, also build `Scripts` to verify its integration with
the shared library.

Do not claim that a change is covered by automated tests. If meaningful tests
are added, run the relevant test target and report the result.

## Formatting and Linting

Swift here follows the style guide at
`$HOME/gooseOS/Skills/swift-style-guide/SKILL.md`. Read it before writing or
reviewing Swift. SwiftFormat and SwiftLint enforce its mechanical rules with
the shared configs beside it, at the versions that the dotfiles repo's
`mise/config.toml` pins.

- `.swiftformat` holds only this folder's overrides of the shared
  `base.swiftformat`. The tools have no `Macrobox` module, so it turns off the
  rewrite to the `#URL` macro.
- `.swiftlint.yml` names the shared `swiftlint-base.yml` as its parent and
  skips the `.build` folders.
- `.swiftlint-baseline.json` records the SwiftLint violations that were in the
  code when SwiftLint was adopted. A baselined violation stays quiet until its
  line is edited, so new and edited code follows every rule. Fix a new
  violation in the code instead of writing the baseline again.

Run these from this folder before committing. The first formats in place, and
the other two report anything left to fix.

```sh
mise exec -- swiftformat --base-config "$HOME/gooseOS/Skills/swift-style-guide/base.swiftformat" .
mise exec -- swiftformat --base-config "$HOME/gooseOS/Skills/swift-style-guide/base.swiftformat" --lint .
mise exec -- swiftlint lint
```

## Development Conventions

- Prefer focused changes over unrelated cleanup.
- Use Swift concurrency for asynchronous process work where appropriate.
- Keep command-line parsing and help text consistent with
  `swift-argument-parser`.
- Pass subprocess arguments as separate values to `Subprocess.run`, especially
  when they may contain spaces or user-provided values.
- Run other commands through `CommandKit`. A command that more than one tool
  runs gets a wrapper there, like `GitHubCLI`, instead of a copy in each tool.
  Helpers only one tool needs stay in that tool, as an extension of the
  wrapper.

## Dependencies

- Keep local package dependencies expressed as relative paths.
- Never edit `Package.resolved` manually.
- Build the relevant artifacts and let SwiftPM manage `Package.resolved`.
- Review any resulting dependency-resolution changes before committing them.
- Avoid new dependencies when the standard library or an existing package is
  sufficient.

## Safety and Generated Files

- Do not edit `.build/` contents.
- Treat `bin/` as generated output; change sources under `Scripts/Sources/`
  instead.
- Do not run `Scripts/install.fish`, or the dotfiles repo's `scripts` and
  `scripts:rebuild` mise tasks that run it, unless explicitly requested. It
  builds release binaries, copies them into `bin/`, and writes fish
  completions under the user's home directory.
- Do not run commands that delete user files or development data without
  explicit approval. In particular, `iosd nuke-derived-data` removes Xcode's
  DerivedData directory.
- Be cautious when executing scripts that invoke external tools or macOS
  utilities such as `mkvmerge`, `osascript`, or `defaults`.

## Completion Checklist

1. Build the affected package.
2. After changing `Escape`, build `Scripts`.
3. Format with SwiftFormat, and check that `swiftformat --lint` and
   `swiftlint lint` report nothing, as Formatting and Linting describes.
4. Review the diff for generated files and unrelated changes.
5. Do not claim test coverage where none exists.
