# Repository Guidelines

This file is the source of truth for AI-assisted development in this repository.
`AGENTS.md` is a symlink to this file.

## Repository Overview

This repository contains local macOS command-line tools written in Swift 6. It
is organized as three sibling SwiftPM packages:

- `Command/`: A library for launching and interacting with subprocesses.
- `Escape/`: A library for terminal output, colors, and control sequences.
- `Scripts/`: Executable tools that depend on the local `Command` and `Escape`
  packages.

`Scripts` currently builds `iosd`, `chapter-splitter`, and `notify`.

There is no root `Package.swift`. Run SwiftPM commands against the relevant
package directory.

## Platform and Tooling

- Swift tools version: 6.0
- Minimum platform: macOS 14
- Command-line parsing: `swift-argument-parser`
- Tests use Swift Testing syntax, but the existing test targets contain only
  placeholders and provide no meaningful automated coverage.
- No formatter or linter is currently configured.

## Build and Validation

Build the affected package:

```sh
swift build --package-path Command
swift build --package-path Escape
swift build --package-path Scripts
```

After changing `Command` or `Escape`, also build `Scripts` to verify its
integration with the shared library.

Do not claim that a change is covered by automated tests. If meaningful tests
are added, run the relevant test target and report the result.

## Development Conventions

- Follow the existing Swift style in the file being edited.
- Prefer focused changes over unrelated cleanup.
- Use Swift concurrency for asynchronous process work where appropriate.
- Keep command-line parsing and help text consistent with
  `swift-argument-parser`.
- Prefer `Command(executable:arguments:)` when arguments may contain spaces or
  user-provided values. The command-string initializer splits on whitespace.

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
- Do not run `Scripts/install.fish` unless explicitly requested. It builds
  release binaries, copies them into `bin/`, and writes fish completions under
  the user's home directory.
- Do not run commands that delete user files or development data without
  explicit approval. In particular, `iosd nuke-derived-data` removes Xcode's
  DerivedData directory.
- Be cautious when executing scripts that invoke external tools or macOS
  utilities such as `mkvmerge`, `osascript`, or `defaults`.

## Completion Checklist

1. Build the affected package.
2. After changing `Command` or `Escape`, build `Scripts`.
3. Review the diff for generated files and unrelated changes.
4. Do not claim test coverage where none exists.
