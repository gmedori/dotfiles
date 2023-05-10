setenv EDITOR "nvim"

fish_vi_key_bindings

#################################
#	ENVIRONMENT VARIABLES
#################################

set -gx FZF_DEFAULT_COMMAND 'rg --files --no-ignore --hidden --follow --glob "!.git/*"'


#################################
#	OTHER VARIABLES
#################################

set -gx FISH_FUNC_DIR ~/.config/fish/functions/

#################################
#	CUSTOM ALIASES
#################################

#Editing configs
alias vim  'nvim'
abbr evim  'nvim ~/.config/nvim/init.vim'
abbr ebash 'nvim ~/.bash_profile'
abbr efish 'nvim ~/.config/fish/config.fish'
abbr efunc "nvim $FISH_FUNC_DIR"
abbr etmux 'nvim ~/.tmux.conf'
abbr egit  'nvim ~/.gitconfig'
abbr essh  'nvim ~/.ssh/config'
abbr estar 'nvim ~/.config/starship.toml'
abbr rld   'source ~/.config/fish/config.fish'

#General
#alias ls  'ls -G'
#alias l   'ls -Flh'
#alias la  'ls -AFlh'
alias ls 'exa --icons'
alias l  'exa --oneline --icons'
alias la 'exa --all --oneline --icons'

abbr  cdc 'cd ~/code'
abbr  cds 'cd ~/scratchpad'
abbr  cdw 'cd ~/dotfiles/work_specific'
abbr  cdt 'cd ~/Sync/Writing/techtechgoose'
abbr  cdd 'cd ~/dotfiles'

abbr cdsc 'cd ~/scripts'

abbr  cl  'clear'

# System Info
alias showPath 'string join \n $PATH'

#FZF
alias fzf 'fzf --height=15 --reverse -m --bind ctrl-a:toggle-all'

#Tmux
abbr tml  'tmux list-sessions'
abbr tma  'tmux attach -t'
abbr tmn  'tmux new -s'
abbr tmnp 'tmux new -s (basename (pwd))'
abbr tmni 'tmux new -s asana-ios'
abbr tmns 'tmux new -s asana-server'

#Git
abbr gs   'git status -s'
abbr gl   'git pull'
abbr glm  'git pull upstream master'
abbr glr  'git pull upstream release'
abbr gld  'git pull upstream develop'
abbr gp   'git push'
abbr gf   'git fetch'
abbr ga   'git add'
abbr gaa  'git add --all; and git status -s'
abbr gc   'git commit'
abbr gca  'git commit --amend --date=now'
abbr gfc  'git commit -eF (git rev-parse --show-toplevel)/.git/COMMIT_EDITMSG'
abbr gg   'git log --graph --oneline --decorate'
abbr ggm  'git log --graph --oneline --decorate master..'
abbr glg  'git log --graph --oneline --decorate --all'
abbr gd   'git diff'
abbr gdc  'git diff --cached'
abbr gk   'git checkout'
abbr gb   'git branch'
abbr gkb  'git checkout -b'
abbr gkbg 'git checkout -b gposcidonio/'
abbr gkd  'git checkout develop'
abbr gkm  'git checkout master'
abbr gkr  'git checkout release'
abbr gkf  'git checkout -b feature/'
abbr gdd  'git diff develop'
abbr gdm  'git diff master'
abbr gsh  'git stash push -m '
abbr gsp  'git stash pop'
abbr gpub 'git push -u origin (git branch --show-current)'
abbr gcp  'git cherry-pick'
abbr gr   'git rebase'
abbr grm  'git rebase master'
abbr grc  'git rebase --continue'

# Github
abbr pr   'gh pr'
abbr mypr 'gh pr list -a @me'
abbr prv  'gh pr view'
abbr prvw 'gh pr view --web'
abbr prk  'gh pr checkout'
abbr prs  'gh pr status'

alias currentBranch "git branch | rg '\\*' | cut -d ' ' -f 2"

#Docker
abbr jshell 'docker run -it openjdk jshell'

#Gradle
abbr grf 'gr clean build jacocoTestReport'

#Other Tools
abbr kb 'kubectl'
abbr java_home '/usr/libexec/java_home'
alias lipsum 'cat $HOME/dotfiles/resources/lipsum.txt'

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
    nvim /tmp/(uuidgen).$argv[1]
end


#################################
#	ENVIRONMENT VARIABLES
#################################

## Homebrew
set HOMEBREW_PATH /opt/homebrew/bin
if contains $HOMEBREW_PATH $PATH
    set PATH (string match -v $HOMEBREW_PATH $PATH)
end
set -gx PATH $HOMEBREW_PATH $PATH

## Scripts
set SCRIPT_DIR $HOME/scripts/bin
if not contains $SCRIPT_DIR $PATH
    set -gx PATH $PATH $SCRIPT_DIR
end

set GO_SCRIPT_DIR $HOME/scripts/gobin
if not contains $GO_SCRIPT_DIR $PATH
    set -gx PATH $PATH $GO_SCRIPT_DIR
end

## Go (Homebrew requires a specific path setup)

set GOBIN $GOPATH/bin
if not contains $GOBIN $PATH
    set -gx PATH $PATH $GOBIN
end
set -gx GOROOT (brew --prefix golang)/libexec

## Ruby
set RUBY_PATH /usr/local/opt/ruby/bin
if contains $RUBY_PATH $PATH
    # Ruby path goes in front to override system Ruby
    set PATH (string match -v $RUBY_PATH $PATH)
end
set -gx PATH $RUBY_PATH $PATH

## Perlbrew
set PERLBREW_BIN $HOME/perl5/perlbrew/bin
if contains $PERLBREW_BIN $PATH
    set PATH (string match -v $PERLBREW_BIN $PATH)
end
set -gx PATH $PERLBREW_BIN $PATH

## Rust
set RUST_BIN $HOME/.cargo/bin
if contains $RUST_BIN $PATH
    set PATH (string match -v $RUST_BIN $PATH)
end
set -gx PATH $RUST_BIN $PATH

## Work Specific Stuff
set WORK_SPECIFIC_DIR $HOME/dotfiles/work_specific
if [ -d $WORK_SPECIFIC_DIR ] # Only do this one if the directory exists (i.e. only on a work computer)
    source $WORK_SPECIFIC_DIR/config/config.fish
end

## Perlbrew 

cat ~/perl5/perlbrew/etc/perlbrew.fish | source

## Starship

starship init fish | source

## Ruby Management // rbenv

status --is-interactive; and rbenv init - fish | source
