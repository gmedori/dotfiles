# Gives an agent's shell commands the GitHub identity of defective-talos, the
# machine account agents push and open pull requests as. Teleport work is the
# exception and keeps the user's own account, because defective-talos has no
# access to the gravitational org.
#
# This file only points the command at two things:
#
# - bin/gh, first on PATH, which runs gh with the bot's token, or as the user
#   for Teleport work. The token never enters the agent's shell.
# - agent.gitconfig, through GIT_CONFIG_*, which sets the bot's commit identity
#   and pushes over HTTPS with credentials from bin/gh, or switches back to the
#   user in any repo with a gravitational remote.
#
# Claude Code sources this before each Bash command through claude-hook.sh. Pi
# sources it once at startup through agent-github.ts in the vault's Pi
# Extensions folder, and copies what it sets into Pi's environment. It's POSIX
# sh, because Claude Code runs zsh and the Pi extension runs /bin/sh.
#
# defective-talos is for personal Macs only and must never act on the work Mac.
# This file does nothing and says nothing unless both of these hold:
#
# - `is-work-mac`, from the scripts repo, exits 1, meaning this Mac isn't
#   enrolled in MDM. It exits 0 on the work Mac and 2 when it can't tell, and a
#   missing binary exits 127, so anything but 1 counts as the work Mac.
# - defective-talos is signed in to gh.

"$HOME/scripts/bin/is-work-mac" >/dev/null 2>&1
if [ "$?" -eq 1 ] && gh auth token --user defective-talos >/dev/null 2>&1; then
  case ":$PATH:" in
    *":$HOME/dotfiles/agent-github/bin:"*) ;;
    *) export PATH="$HOME/dotfiles/agent-github/bin:$PATH" ;;
  esac
  export GIT_CONFIG_COUNT=1
  export GIT_CONFIG_KEY_0=include.path
  export GIT_CONFIG_VALUE_0="$HOME/dotfiles/agent-github/agent.gitconfig"
fi
