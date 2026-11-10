#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
OLDDIR="$(pwd)"

cd $DIR

git submodule update --init --recursive

brew bundle --file=$DIR/Brewfile

# Perl comes from Homebrew (see Brewfile). CPAN modules go to ~/perl5 via
# local::lib; the matching environment is set statically in fish/config.fish.
# Run cpanm with Homebrew's perl explicitly, since /usr/bin may still be ahead
# of Homebrew in this script's PATH.
BREW_PREFIX="$(brew --prefix)"
PERL_LOCAL_LIB="$HOME/perl5"
if ! "$BREW_PREFIX/bin/perl" -I"$PERL_LOCAL_LIB/lib/perl5" -Mlocal::lib -e1 2>/dev/null; then
    "$BREW_PREFIX/bin/perl" "$BREW_PREFIX/bin/cpanm" --local-lib="$PERL_LOCAL_LIB" local::lib
fi

$DIR/linker.pl

cd $OLDDIR
