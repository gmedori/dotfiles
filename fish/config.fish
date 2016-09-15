setenv EDITOR "nvim"

fish_vi_key_bindings

#################################
#	CUSTOM ALIASES
#################################

#Editing configs
alias vim 'nvim'
alias evim 'nvim ~/.config/nvim/init.vim'
alias ebash 'nvim ~/.bash_profile'
alias efish 'nvim ~/.config/fish/config.fish'
alias etmux 'nvim ~/.tmux.conf'
alias egit 'nvim ~/.git'
alias rld 'source ~/.config/fish/config.fish'
alias wiki 'nvim +VimwikiIndex'

#General
alias ls 'ls -G'
alias l 'ls -Flh'
alias la 'ls -AFlh'

#Tmux
alias tml 'tmux list-sessions'
alias tma 'tmux attach -t'
alias tmn 'tmux new -s'

#Git
alias gs  'git status -s'
alias gl  'git pull'
alias gp  'git push'
alias gf  'git fetch'
alias ga  'git add --all; and gs'
alias gc  'git commit'
alias gg  'git log --graph --oneline --decorate'
alias gd  'git diff'
alias go  'git checkout'
alias gb  'git branch'
alias gob 'git checkout -b'

#Development
alias mk 'make clean all'

#Remap ctrl-j
bind -k f7 down-or-search

function fish_prompt --description 'Write out the prompt'
	set -l last_status $status

	if not set -q __fish_prompt_normal
		set -g __fish_prompt_normal (set_color normal)
	end

	# PWD
	set_color 00E2FF
	echo -n (basename $PWD)
	set_color 63FF00

	printf '%s ' (__fish_git_prompt)

	set_color normal

	if not test $last_status -eq 0
		set_color FF1C00
	end

	echo -n '><> '

	set_color normal
end
eval (thefuck --alias | tr '\n' ';')
rvm default
