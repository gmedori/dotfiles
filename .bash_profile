TERM=xterm-256color

export EDITOR="vim"

set -o vi

# Setting Up PS1
source ~/.git_prompt.sh
PS1="\\[\e[1;36m\\]\W ○\\[\e[1;33m\\]\$(__git_ps1)\\[\e[1;36m\\] $ \\[\e[0;37m\\]"

#################################
#	CUSTOM ALIASES
#################################

#Editing configs
alias evim='vim ~/.vimrc'
alias ebash='vim ~/.bash_profile'
alias etmux='vim ~/.tmux.conf'
alias egit='vim ~/.git'
alias rld='source ~/.bash_profile'
alias wiki='vim ~/vimwiki/index.wiki'

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
alias gg='git log --graph --oneline --decorate'

#Development
alias mk='make clean all'

[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*

eval "$(rbenv init -)"

# The next line updates PATH for the Google Cloud SDK.
source '/Users/Freya/Downloads/google-cloud-sdk/path.bash.inc'

# The next line enables shell command completion for gcloud.
source '/Users/Freya/Downloads/google-cloud-sdk/completion.bash.inc'
