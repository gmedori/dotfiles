#!/bin/bash

# Sets up a Mac from this repo. It runs from a clone, or straight from GitHub
# on a new Mac:
#
#   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/gmedori/dotfiles/master/install.sh)"
#
# That form keeps the terminal as stdin, which the prompts in the Homebrew
# installer and linker.pl read from.
#
# Installs Homebrew when it's missing, which also installs the Command Line
# Tools and with them git. When the script isn't running from a clone, it
# clones the repo over HTTPS to ~/dotfiles, or uses the clone already there.
# Then it installs mise when it's missing and runs the `setup` task in
# mise.toml, which lists every step.

set -euo pipefail

REPO_URL="https://github.com/gmedori/dotfiles.git"
CLONE_DIR="$HOME/dotfiles"

if [ ! -x /opt/homebrew/bin/brew ]; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
eval "$(/opt/homebrew/bin/brew shellenv)"

# BASH_SOURCE is empty under `bash -c`, so the script only finds the repo
# beside itself when it runs from a file in a clone.
DIR=""
if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
    DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
fi
if [ -z "$DIR" ] || [ ! -f "$DIR/mise.toml" ]; then
    if [ ! -d "$CLONE_DIR/.git" ]; then
        git clone "$REPO_URL" "$CLONE_DIR"
    fi
    DIR="$CLONE_DIR"
fi

MISE="$(command -v mise || echo "$HOME/.local/bin/mise")"
if [ ! -x "$MISE" ]; then
    curl -fsSL https://mise.run | sh
fi

"$MISE" -C "$DIR" run setup
