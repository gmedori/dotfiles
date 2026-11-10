#!/bin/sh
# Claude Code's SessionStart and CwdChanged hook, set in claude/settings.json.
#
# A hook runs in its own process, so anything it exports is gone before Claude
# Code runs a Bash command. Instead, Claude Code runs the file named by
# CLAUDE_ENV_FILE before every Bash command, so this hook adds a line to that
# file that sources activate.sh. activate.sh then decides, command by command,
# whether the command acts as defective-talos.
#
# The line goes in single quotes so $HOME expands when each command runs. Claude
# Code clears the file's variables when the working folder changes, and it isn't
# documented whether that empties the file, so CwdChanged runs this hook too, and
# the line is added only when it's missing.

[ -n "$CLAUDE_ENV_FILE" ] || exit 0

if ! grep -qsF 'agent-github/activate.sh' "$CLAUDE_ENV_FILE"; then
  echo '. "$HOME/dotfiles/agent-github/activate.sh"' >> "$CLAUDE_ENV_FILE"
fi
