setenv EDITOR "nvim"

fish_vi_key_bindings

#################################
#	ENVIRONMENT VARIABLES
#################################

set -gx FZF_DEFAULT_COMMAND 'rg --files --no-ignore --hidden --follow --glob "!.git/*"'

set -gx HOMEBREW_GITHUB_API_TOKEN 2a0fa730f314728ded05e8d546706626f3bea9f7

set -gx PATH /opt/brew/opt/ruby/bin $PATH
set -gx PATH /opt/brew/lib/ruby/gems/3.0.0/bin $PATH
set -gx PATH /opt/homebrew/bin $PATH

# Directories
set -gx appleWork $HOME/Library/Mobile\ Documents/com~apple~icloud~applecorporate/Documents 
set -gx workNotes $appleWork/Work\ Notes

#################################
#	CUSTOM ALIASES
#################################

#Editing configs
alias vim  'nvim'
abbr evim  'nvim ~/.config/nvim/init.vim'
abbr ebash 'nvim ~/.bash_profile'
abbr efish 'nvim ~/.config/fish/config.fish'
abbr etmux 'nvim ~/.tmux.conf'
abbr egit  'nvim ~/.git'
abbr essh  'nvim ~/.ssh/config'
abbr estar 'nvim ~/.config/starship.toml'
abbr rld   'source ~/.config/fish/config.fish'

#General
alias ls  'ls -G'
alias l   'ls -Flh'
alias la  'ls -AFlh'

abbr  cdc 'cd ~/code'
abbr  cds 'cd ~/scratchpad'
abbr  cdw 'cd ~/Sync/Writing'
abbr  cdt 'cd ~/Sync/Writing/techtechgoose'
abbr  cdd 'cd ~/dotfiles'

abbr cdsc 'cd ~/Sync/Scripts/src'

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

#Git
abbr gs   'git status -s'
abbr gl   'git pull'
abbr glm  'git pull upstream main'
abbr glr  'git pull upstream release'
abbr gld  'git pull upstream develop'
abbr gp   'git push'
abbr gf   'git fetch'
abbr ga   'git add'
abbr gaa  'git add --all; and git status -s'
abbr gc   'git commit'
abbr gfc  'git commit -eF (git rev-parse --show-toplevel)/.git/COMMIT_EDITMSG'
abbr gg   'git log --graph --oneline --decorate'
abbr glg  'git log --graph --oneline --decorate --all'
abbr gd   'git diff --color-words'
abbr gdc  'git diff --color-words --cached'
abbr gk   'git checkout'
abbr gb   'git branch'
abbr gkb  'git checkout -b'
abbr gkd  'git checkout develop'
abbr gkm  'git checkout main'
abbr gkr  'git checkout release'
abbr gkf  'git checkout -b feature/'
abbr gdd  'git diff develop'
abbr gdm  'git diff master'
abbr gsh  'git stash push -m '
abbr gsp  'git stash pop'
abbr gpub 'git push -u origin (git branch | rg "\\\\*" | cut -d " " -f 2)'

alias currentBranch "git branch | rg '\\*' | cut -d ' ' -f 2"

#Docker
abbr jshell 'docker run -it openjdk jshell'

#Gradle
abbr grf 'gr clean build jacocoTestReport'

#Other Tools
abbr kb 'kubectl'
abbr java_home '/usr/libexec/java_home'

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

cat ~/perl5/perlbrew/etc/perlbrew.fish | source


# Path Setup

# Go
if not contains $GOPATH/bin $PATH
    set -gx PATH $PATH $GOPATH/bin
end

## Scripts
set -gx SCRIPT_DIR $HOME/Dropbox/Scripts/bin
if not contains $SCRIPT_DIR $PATH
    set -gx PATH $PATH $SCRIPT_DIR
end

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

starship init fish | source
