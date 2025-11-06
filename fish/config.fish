set -gx EDITOR "nvim"

fish_vi_key_bindings

#################################
#	ENVIRONMENT VARIABLES
#################################

set -gx FZF_DEFAULT_COMMAND 'rg --files --no-ignore --hidden --follow --glob "!.git/*"'
set -gx MANPAGER 'nvim +Man!'


#################################
#	OTHER VARIABLES
#################################

set -gx FISH_FUNC_DIR ~/.config/fish/functions/

#################################
#	CUSTOM ALIASES
#################################

#Editing configs
alias vim   'nvim'
abbr evim   'nvim ~/.config/nvim/init.lua'
abbr ebash  'nvim ~/.bash_profile'
abbr efish  'nvim ~/.config/fish/config.fish'
abbr efunc  "nvim $FISH_FUNC_DIR"
abbr etmux  'nvim ~/.tmux.conf'
abbr egit   'nvim ~/.gitconfig'
abbr essh   'nvim ~/.ssh/config'
abbr estar  'nvim ~/.config/starship.toml'
abbr eghost 'nvim ~/.config/ghostty/config'
abbr ework  'nvim ~/dotfiles/work_specific'
abbr rld    'source ~/.config/fish/config.fish'

#General
#alias ls  'ls -G'
#alias l   'ls -Flh'
#alias la  'ls -AFlh'
alias l   'eza --icons -s type'
alias la  'eza --icons -s type --all'
alias ll  'eza --long --icons -s type'
alias lla 'eza --long --icons -s type --all'

abbr  cdc 'cd ~/code'
abbr  cds 'cd ~/scratchpad'
abbr  cdw 'cd ~/dotfiles/work_specific'
abbr  cdd 'cd ~/dotfiles'

abbr cdsc 'cd ~/scripts'

abbr  cl  'clear'

# System Info
alias show-path 'string join \n ">>> fish_user_paths" "" $fish_user_paths "" ">>> PATH" "" $PATH'

#FZF
alias fzf 'fzf --height=15 --reverse -m --bind ctrl-a:toggle-all'

#Tmux
abbr tml  'tmux list-sessions'
abbr tma  'tmux attach -t'
abbr tmn  'tmux new -s'
abbr tmnp 'tmux new -s (basename (pwd))'

#Git
abbr gs   'git status -s'
abbr gl   'git pull'
abbr glm  'git pull upstream main'
abbr gp   'git push'
abbr gf   'git fetch'
abbr ga   'git add'
abbr gaa  'git add --all; and git status -s'
abbr gc   'git commit -v'
abbr gcn  'git commit -v --no-verify'
abbr gca  'git commit --amend --date=now'
abbr gfc  'git commit -eF (git rev-parse --show-toplevel)/.git/COMMIT_EDITMSG'
abbr gg   'git lg'
abbr ggm  'git lg main..'
abbr glg  'git lg --all'
abbr gd   'git diff'
abbr gdc  'git diff --cached'
abbr gk   'git checkout'
abbr gb   'git branch'
abbr gkb  'git checkout -b'
abbr gkbg 'git checkout -b goose/'
abbr gkm  'git checkout main'
abbr gdm  'git diff main'
abbr gsh  'git stash push -m '
abbr gsp  'git stash pop'
abbr gpub 'git push -u origin (git branch --show-current)'
abbr gcs  'git rev-parse --short HEAD | tr -d \' \\n\' | pbcopy'
abbr gcp  'git cherry-pick'
abbr gr   'git rebase'
abbr grm  'git rebase main'
abbr grc  'git rebase --continue'
abbr gci  'git clean -i'

# Graphite

abbr gtsu 'gt submit --stack --update-only'

# Github
abbr pr   'gh pr'
abbr mypr 'gh pr list -a @me'
abbr prv  'gh pr view'
abbr prvw 'gh pr view --web'
abbr prk  'gh pr checkout'
abbr prs  'gh pr status'

# 1Password
alias ynab-token 'op item get "YNAB Personal Access Token" --fields password --reveal'

alias currentBranch "git branch | rg '\\*' | cut -d ' ' -f 2"

#Other Tools
alias lipsum 'cat $HOME/dotfiles/resources/lipsum.txt'
alias keyboardmaestro '/Applications/Keyboard\ Maestro.app/Contents/MacOS/keyboardmaestro'
alias km keyboardmaestro

#################################
#	COLORS
#################################

set fish_color_normal white
set fish_color_command white
set fish_color_param cyan
set fish_color_quote yellow
set fish_color_redirection blue
set fish_color_end cyan
set fish_color_error red
set fish_color_comment magenta
set fish_color_match green
set fish_color_search_match green
set fish_color_operator green
set fish_color_escape yellow
set fish_color_autosuggestion A0A0A0
set fish_color_cancel white

#################################
#	FUNCTIONS
#################################

set fish_function_path ~/.config/fish/functions/*/ $fish_function_path

set fish_color_search_match --background=8A8A8A

function vimf --description 'Fuzzy file opener for vim'
	if fzf > $TMPDIR/fzf.result
		vim (cat $TMPDIR/fzf.result)
	end
end

function temp
    set -l UUID (uuidgen)
    set -l FILE /tmp/$UUID.$argv[1]
    nvim $FILE
    echo "Temp file located at $FILE"
end

function capitalize --description 'Capitalize the first letter of each word provided'
    awk '{for (i=1; i<=NF; ++i) { $i=toupper(substr($i,1,1)) tolower(substr($i,2)); } print }'
end

function fish_title
    # Prevent fish from trying to write the title to the terminal window by overwriting fish_title to not print anything.
end

function title
    echo -e "\033];$argv\007"
end




#################################
#	ENVIRONMENT VARIABLES
#################################

## GOPATH
set -gx GOPATH $HOME/go

fish_add_path /opt/homebrew/bin #.................... Homebrew
fish_add_path $HOME/scripts/bin #.................... Scripts
fish_add_path (brew --prefix go@1.24)/bin #.......... Golang binary
fish_add_path $GOPATH/bin #.......................... GOPATH
fish_add_path $HOME/.cargo/bin #..................... Rust

## Work Specific Stuff
set WORK_SPECIFIC_DIR $HOME/dotfiles/work_specific
if [ -f $WORK_SPECIFIC_DIR/config.fish ] # Only do this one if the directory exists (i.e. only on a work computer)
    source $WORK_SPECIFIC_DIR/config.fish
end

## Starship

starship init fish | source
