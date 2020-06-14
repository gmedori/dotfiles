#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

brew bundle --file=$DIR/Brewfile

curl -L https://install.perlbrew.pl | bash

# Pick a perl version
PERL_VERSION=5.30.3
perlbrew install $PERL_VERSION
perlbrew switch $PERL_VERSION

# Install cpanm
curl -L https://cpanmin.us | perl - App::cpanminus

$DIR/linker.pl
