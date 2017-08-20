setenv EDITOR "nvim"

fish_vi_key_bindings

#################################
#	ENVIRONMENT VARIABLES
#################################

<<<<<<< Updated upstream
set -gx GOPATH /Users/mjolnir/code/go
set -gx PATH $PATH $GOPATH/bin
=======
set -x GOPATH $HOME/code/go
set -x PATH $PATH $GOPATH/bin
>>>>>>> Stashed changes

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
abbr rld   'source ~/.config/fish/config.fish'
abbr wiki  'nvim +VimwikiIndex'
abbr pwiki 'nvim $HOME/code/private-wiki/vimwiki/index.wiki'

#General
alias ls  'ls -G'
alias l   'ls -Flh'
alias la  'ls -AFlh'

abbr  cdc 'cd ~/code'
abbr  cdg 'cd ~/code/go/src'
abbr  cds 'cd ~/scratchpad'
abbr  cl  'clear'

#Work AWS
alias ssh_dev "ssh agent ssh centos@192.168.1.203"
alias ssh_git "ssh -v -A -t -i \"/Users/gustavo/Jiko/certs/bastion_server.pem\" -R 20101:localhost:22 ec2-user@52.54.62.115 ssh -t -R 20201:localhost:20101 centos@192.168.1.203 '\"\"sshfs -p 20201 -o ro gustavo@localhost:/Users/gustavo/Jiko/certs /home/centos/.certs\";fish\"'"

#Tmux
abbr tml 'tmux list-sessions'
abbr tma 'tmux attach -t'
abbr tmn 'tmux new -s'

#Git
abbr gs  'git status -s'
abbr gl  'git pull'
abbr gp  'git push'
abbr gf  'git fetch'
abbr ga  'git add'
abbr gaa 'git add --all; and git status -s'
abbr gr  'git reset'
abbr gc  'git commit'
abbr gg  'git log --graph --oneline --decorate'
abbr glg 'git log --graph --oneline --decorate --all'
abbr gd  'git diff'
abbr gk  'git checkout'
abbr gb  'git branch'
abbr gkb 'git checkout -b'

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

	echo -n '' (whoami) ''

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

eval (thefuck --alias | tr '\n' ';')

# The next line updates PATH for the Google Cloud SDK.
# if [ -f '/Users/gustavo/Downloads/google-cloud-sdk/path.fish.inc' ]; if type source > /dev/null; source '/Users/gustavo/Downloads/google-cloud-sdk/path.fish.inc'; else; . '/Users/gustavo/Downloads/google-cloud-sdk/path.fish.inc'; end; end

rvm default

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/mjolnir/gcloud/path.fish.inc' ]; if type source > /dev/null; source '/Users/mjolnir/gcloud/path.fish.inc'; else; . '/Users/mjolnir/gcloud/path.fish.inc'; end; end
