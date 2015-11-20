TERM=xterm-256color

export EDITOR="vim"

set -o vi

# Setting Up PS1
source ~/.git_prompt.sh
print_pre_prompt () 
{ 
	PS1R=$PWD
	if [[ $PS1R/ = "$HOME"/* ]]; then PS1R=\~${PS1R#$HOME}; fi
	PS1L=""
	printf "\033[1;36m%s%$(($COLUMNS-${#PS1L}))s" "$PS1L" "$PS1R"
}
PROMPT_COMMAND=print_pre_prompt
PS1="\u ○\033[1;33m\$(__git_ps1)\033[1;36m $ \033[0;37m"

#################################
#	CUSTOM ALIASES
#################################

#Editing configs
alias evim='vim ~/.vimrc'
alias ebash='vim ~/.bash_profile'
alias etmux='vim ~/.tmux.conf'
alias egit='vim ~/.git'
alias rld='source ~/.bash_profile'

#General
alias ls='ls -G'
alias l='ls -Flh'
alias la='ls -AFlh'

#Tmux
alias tml='tmux list-sessions'
alias tma='tmux attach -t'
alias tmn='tmux new -s'

#Git
alias gs='git status -s'
alias gl='git pull'
alias gp='git push'
alias gf='git fetch'
alias ga='git add --all && gs'
alias gc='git commit'

[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*
