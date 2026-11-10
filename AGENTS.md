# Agent Instructions

This file is the source of truth for both `AGENTS.md` and `CLAUDE.md`.
`CLAUDE.md` should stay as a relative symlink to this file.

## Repository Purpose

This is a personal dotfiles repo for macOS development environment config. Most
files are intended to be symlinked into `$HOME` and reflect personal workflow
preferences, so avoid broad rewrites or "standardizing" settings unless the user
asks for that.

Main areas:

- `fish/`: Fish shell config, functions, completions, and plugin lists.
- `nvim/`: Neovim config using Lua and lazy.nvim.
- `tmux/`: tmux config plus plugin files.
- `ghostty/`, `iterm/`: terminal config, themes, and color profiles.
- `zellij/`: Zellij config and themes.
- `zed/`, `xcode/`, `keyboards/`, `whitefox/`: editor, IDE, and keyboard config.
- `Brewfile`: Homebrew dependencies for a new machine.
- `install.sh` and `linker.pl`: bootstrap and symlink scripts.
- `scripts/`: Swift command-line tools such as `tp`, `ths`, and `is-work-mac`.
  It has its own AGENTS.md. Its install script puts the binaries in
  `scripts/bin`, which `fish/config.fish` adds to `PATH`.

## Safety Rules

- Do not run `install.sh`, `linker.pl`, `brew bundle`, `perlbrew install`, or
  curl-based installers unless the user explicitly asks. These mutate the host
  machine and can replace files under `$HOME`.
- Treat files under `work_specific/` as potentially local/private. Read only
  what is needed and do not expose contents in summaries unless relevant.
- Do not edit submodules or vendored plugin directories unless the task is
  specifically about them. Current submodules include `qmk/qmk_firmware` and
  `tmux/tmux/plugins/tmux-yank`.
- Do not add secrets, tokens, machine-local absolute paths, or private account
  details to tracked files unless the repo already intentionally tracks that
  exact kind of value and the user asks for it.
- Preserve user changes in the working tree. Check `git status --short` before
  making edits and do not revert unrelated changes.

## Style

- Keep edits small and specific to the requested tool or config.
- Prefer the existing style of each config file over introducing new structure.
- For generated or downloaded config snapshots, avoid reformatting unrelated
  sections.
- Use relative paths inside the repo when possible.
- If adding a new managed dotfile, update `linker.pl` only when it should be
  symlinked by the bootstrap flow.

## Validation

Use the narrowest relevant checks after changes:

- Fish syntax: `fish --no-execute path/to/file.fish`
- Neovim Lua syntax:
  `NVIM_LOG_FILE=/tmp/nvim-dotfiles.log nvim --headless --clean '+lua for _, f in ipairs(vim.fn.glob("nvim/**/*.lua", false, true)) do local chunk, err = loadfile(f); if not chunk then error(err) end end' +quit`
- Ghostty config: `ghostty +validate-config --config-file=ghostty/config`
- Zellij config: `zellij --config zellij/config.kdl setup --check`
- Swift tools: `swift build --package-path scripts/Scripts` and
  `swift test --package-path scripts/Scripts`
- Git sanity: `git diff --check`

Some checks may read the live config location or start local helper processes.
If a command would install dependencies, change `$HOME`, or require network
access, ask first.

## Syncing Agent Files

Keep `AGENTS.md` canonical. `CLAUDE.md` should be a symlink:

```sh
ln -s AGENTS.md CLAUDE.md
```

If a platform cannot preserve symlinks, replace the symlink with a small sync
check or copy step, but do not maintain two independent instruction files.
