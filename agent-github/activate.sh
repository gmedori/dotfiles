# Gives an agent's shell commands the GitHub identity of defective-talos, the
# machine account agents push and open pull requests as. Teleport work is the
# exception and keeps the user's own account, because defective-talos has no
# access to the gravitational org:
#
# - Git reads agent.gitconfig, which switches back to the user in any repo with
#   a gravitational remote, wherever the command runs.
# - `gh` gets no GH_TOKEN in a repo with a gravitational remote. Elsewhere, a
#   `gh` call whose arguments name `gravitational/`, as `gh -R gravitational/core`
#   and `gh api repos/gravitational/...` do, runs without it. The `gh` function
#   below does this, so it covers `gh` typed in the command itself, not `gh` run
#   by a script or another tool.
#
# Claude Code sources this before each Bash command through claude-hook.sh, and
# Pi through `shellCommandPrefix` in ~/.pi/agent/settings.json. It's POSIX sh,
# because Claude Code runs zsh and Pi runs bash.
#
# The token comes from the Keychain, where `gh auth login` stored it, so reading
# it never prompts while the user is logged in. defective-talos is signed in only
# on the personal Mac. The work Mac must never have it, so where it isn't signed
# in, this file does nothing and says nothing.

if agent_github_token=$(gh auth token --user defective-talos 2>/dev/null); then
  export GIT_CONFIG_COUNT=1
  export GIT_CONFIG_KEY_0=include.path
  export GIT_CONFIG_VALUE_0="$HOME/dotfiles/agent-github/agent.gitconfig"

  if ! git config --get-regexp '^remote\..*\.url$' 2>/dev/null | grep -q 'github\.com[:/]gravitational/'; then
    export GH_TOKEN="$agent_github_token"

    gh() {
      case " $* " in
        *gravitational/*) (unset GH_TOKEN; command gh "$@") ;;
        *) command gh "$@" ;;
      esac
    }
  fi
fi

unset agent_github_token
