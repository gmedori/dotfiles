function wt --description 'Create a git worktree and open it in tmux'
    argparse -n wt init-submodules -- $argv; or return 1

    set -l init_submodules false
    if set -q _flag_init_submodules
        set init_submodules true
    end

    set -l name $argv[1]
    set -l base $argv[2]

    if test -z "$name"
        echo "usage: wt [--init-submodules] <name> [base]"
        return 1
    end

    if test -z "$base"
        set base HEAD
    end

    if not git rev-parse --is-inside-work-tree >/dev/null 2>&1
        echo "wt: not inside a git repo"
        return 1
    end

    set -l repo_root (git rev-parse --show-toplevel)
    set -l repo_name (basename "$repo_root")
    set -l remote_url (git -C "$repo_root" remote get-url origin 2>/dev/null)

    if test -z "$remote_url"
        set remote_url (git -C "$repo_root" remote -v | string match -rg '^[^\s]+\s+([^\s]+)\s+\(fetch\)' | head -n 1)
    end

    if test -n "$remote_url"
        set -l remote_path (string replace -r '/$' '' -- "$remote_url")
        set repo_name (basename "$remote_path" .git)
    end

    set -l parent_dir (dirname "$repo_root")
    set -l dir_name (string replace -a "/" "-" -- "$name")
    set -l target "$parent_dir/$repo_name-$dir_name"
    set -l session_name (basename "$target")

    if test -e "$target"
        echo "wt: target already exists: $target"
        return 1
    end

    if not type -q tmux
        echo "wt: tmux not found"
        return 1
    end

    if tmux has-session -t "=$session_name" 2>/dev/null
        echo "wt: tmux session already exists: $session_name"
        return 1
    end

    git -C "$repo_root" worktree add -b "$name" "$target" "$base"; or return 1

    if test "$init_submodules" = true; and test -f "$target/.gitmodules"
        git -C "$target" submodule update --init --recursive; or return 1
    end

    cd "$target"; or return 1

    if test -n "$TMUX"
        tmux new-session -d -s "$session_name" -c "$target"; or return 1
        tmux switch-client -t "=$session_name"; or return 1
    else
        tmux new-session -s "$session_name" -c "$target"; or return 1
    end
end
