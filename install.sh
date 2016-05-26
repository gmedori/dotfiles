#!/bin/sh

FILELIST="vimrc tmux.conf"
BASEDIR=`dirname "$0"`

cd

for f in $FILELIST
do
	DOTFILE="."$f
	echo "Testing for existence of $DOTFILE"
	if [ -f $DOTFILE ]
	then
		echo "Found $DOTFILE. Moving old $DOTFILE to  $DOTFILE.old"
		mv $DOTFILE $DOTFILE".old"
	else
		echo "$DOTFILE not found"
	fi

	echo "Installing $DOTFILE"
	ln -s "$BASEDIR/.dotfiles/"$f "."$f
done

echo "Testing for existence of ~/.vim directory"
if [ -d .vim ]
then
	echo ".vim directory detected. Moving old .vim directory to ~/.vim.old"
	mv .vim .vim.old
else
	echo "Vim directory not detected"
fi

echo "Installing vim folder"
ln -s $BASEDIR/.dotfiles/vim ~/.vim

mkdir ~/.config
echo "Testing for existence of ~/.config/fish directory"
if [ -d ~/.config/fish ]
then
	echo "Fish directory detected. Moving old fish directory to ~/.config/fish.old"
	mv ~/.config/fish ~/.config/fish.old
else
	echo "Fish directory not detected"
fi

cd ~/.config

echo "Installing fish config files"
ln -s $BASEDIR/.dotfiles/fish fish
