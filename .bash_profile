TERM=xterm-256color

export EDITOR="vim"

set -o vi

# Setting Up PS1
source ~/.git_prompt.sh
print_pre_prompt () 
{ 
	PS1R=$PWD
	if [[ $PS1L/ = "$HOME"/* ]]; then PS1L=\~${PS1L#$HOME}; fi
	PS1L=$USER@$HOSTNAME
	printf "\033[1;32;40m%s%$(($COLUMNS-${#PS1L}))s" "$PS1L" "$PS1R"
}
PROMPT_COMMAND=print_pre_prompt
PS1="\u\$(__git_ps1) $ \033[0;37m"

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
