#!/bin/bash

# Sets up a new Mac from this repo. Homebrew must already be installed.
# Installs mise with its official installer when it's missing, then runs the
# `setup` task in mise.toml, which lists every step.

set -euo pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

MISE="$(command -v mise || echo "$HOME/.local/bin/mise")"
if [ ! -x "$MISE" ]; then
    curl -fsSL https://mise.run | sh
fi

"$MISE" -C "$DIR" run setup
