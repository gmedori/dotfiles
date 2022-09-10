#!/usr/bin/env perl

use strict;
use warnings;
use autodie;

use Env qw(HOME);
use Term::ANSIColor;
use File::Basename;
use Cwd 'abs_path';

my ($file, $directory, $extension) = fileparse(__FILE__);
$directory = abs_path($directory);

my @fileList = (
    ["$directory/nvim", "$HOME/.config/nvim"],
    ["$directory/fish", "$HOME/.config/fish"],
    ["$directory/starship.toml", "$HOME/.config/starship.toml"],
    ["$directory/tmux/tmux.conf", "$HOME/.tmux.conf"],
    ["$directory/tmux/tmux", "$HOME/.tmux"]
    ["$directory/gitconfig", "$HOME/.gitconfig"]
);


print color('bold red');
print "WARNING: ";
print color('white');
print "The following files/directories will be obliterated and replaced with the ones in this repo. ";
print "Are you sure you wish to continue?\n";
for my $f (@fileList) {
    print "\t@$f[1]\n"
}
print "Type yes to continue. All other inputs will abort: ";
my $userResponse = <STDIN>;
chomp $userResponse;

if ("yes" ne $userResponse) {
    print "Aborting...\n";
    exit 1;
}


my $exitCode = 0;
for my $f (@fileList) {
    my ($source, $destination) = @$f;
    if (-e $destination) {
        my $unlinkedCount = unlink $destination;
        if ($unlinkedCount != 1) {
            print color("bold red");
            print "Failed to unlink $destination $!\n";
            $exitCode = 1;
            next;
        }
        print color("white");
        print "Successfully unlinked $destination.\n";
    }
    my $success = symlink $source, $destination;
    if ($success != 1) {
        print color("bold red");
        print "Failed to symlink $source to $destination.\n";
        next;
    }
    print color("white");
    print "Successfully symlinked $source to $destination.\n"
}

exit $exitCode;
