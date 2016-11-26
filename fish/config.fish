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
alias cdc 'cd ~/code'

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
alias gk  'git checkout'
alias gb  'git branch'
alias gkb 'git checkout -b'

#Task Warrior
alias os 'task add project:os'

#Development
alias mk 'make clean all'

function fish_mode_prompt; end

set fish_color_search_match --background=8A8A8A

function fish_right_prompt --description 'Write out the right prompt'

	if not set -q __fish_prompt_normal
		set -g __fish_prompt_normal (set_color normal)
	end

	# PWD
	set directory (echo $PWD | sed -e "s|^$HOME|~|")
	echo -n "[ $directory ]"

	set_color 63FF00

	printf '%s ' (__fish_git_prompt)


	set_color normal
end

function fish_prompt --description 'Write out the prompt'
	set -l last_status $status

	if not set -q __fish_prompt_normal
		set -g __fish_prompt_normal (set_color normal)
	end

	switch $fish_bind_mode
		case insert
			set_color 00E2FF
		case default
			set_color FFFA75
		case visual
			set_color FF955C
	end

	echo -n '' (whoami) ''

	if not test $last_status -eq 0
		set_color FF1C00
	end

	echo -n '><> '

	set_color normal
end

function vimf --description 'Fuzzy file opener for vim'
	if fzf > $TMPDIR/fzf.result
		vim (cat $TMPDIR/fzf.result)
	end
end

eval (thefuck --alias | tr '\n' ';')
rvm default
