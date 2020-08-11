setenv EDITOR "nvim"

fish_vi_key_bindings

#################################
#	ENVIRONMENT VARIABLES
#################################

set -gx GOPATH $HOME/code/go
set -gx PATH $PATH $GOPATH/bin

set -gx SCRIPT_DIR $HOME/Sync/Scripts/bin
set -gx PATH $PATH $SCRIPT_DIR

set -gx FZF_DEFAULT_COMMAND 'rg --files --no-ignore --hidden --follow --glob "!.git/*"'

set -gx HOMEBREW_GITHUB_API_TOKEN 2a0fa730f314728ded05e8d546706626f3bea9f7

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
abbr rld   'source ~/.config/fish/config.fish'

#General
alias ls  'ls -G'
alias l   'ls -Flh'
alias la  'ls -AFlh'

abbr  cdc 'cd ~/code'
abbr  cdg 'cd ~/code/go/src'
abbr  cds 'cd ~/scratchpad'
abbr  cl  'clear'

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
abbr glm  'git pull upstream master'
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
abbr gd   'git diff'
abbr gk   'git checkout'
abbr gb   'git branch'
abbr gkb  'git checkout -b'
abbr gkm  'git checkout master'
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

function fish_mode_prompt; end

set fish_color_search_match --background=8A8A8A

function fish_right_prompt --description 'Write out the right prompt'

    set_color red --bold

	printf '%s ' (__fish_git_prompt)

	set_color normal
    set_color yellow

	# PWD
	set directory (echo $PWD | sed -e "s|^$HOME|~|")
	echo -n "[ $directory ]"

	set_color normal
end

function fish_prompt --description 'Write out the prompt'
	set -l last_status $status

	if not set -q __fish_prompt_normal
		set -g __fish_prompt_normal (set_color normal)
	end

	switch $fish_bind_mode
		case insert
            set_color green
		case default
            set_color yellow
		case visual
            set_color magenta
	end

    echo -n ' ['
    echo -n (date '+%H:%M:%S')
	echo -n ']' (whoami) ''

	if not test $last_status -eq 0
        #set_color FF1C00
        set_color red
	end

	echo -n '><> '

	set_color normal
end

function vimf --description 'Fuzzy file opener for vim'
	if fzf > $TMPDIR/fzf.result
		vim (cat $TMPDIR/fzf.result)
	end
end

cat ~/perl5/perlbrew/etc/perlbrew.fish | source

set PATH $HOME/dotfiles/scripts/ $PATH
set PATH $HOME/perl5/perlbrew/bin $PATH
