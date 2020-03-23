#!/Users/odin/perl5/perlbrew/perls/perl-5.28.1/bin/perl

use JSON::MaybeXS ':all';

my $query = $ARGV[0];

use strict;
use warnings;

my $apple_script = q{
set output to ""

tell application "TextExpander"
	repeat with theGroup in groups
		repeat with theSnippet in snippets of theGroup
            if the prefix of theGroup is not missing value then
                set output to output & "[" & prefix of theGroup & abbreviation of theSnippet & "] " & name of theSnippet & "\n"
            else
                set output to output & "[" & abbreviation of theSnippet & "] " & name of theSnippet & "\n"
            end if
		end repeat
	end repeat
end tell

return output
};

my @te_output = qx(echo '$apple_script' | osascript);

my @items = ();
foreach( @te_output ) {
    my $line = $_;
    if ($line =~ /$query/i) {
        my $entry = {};
        chomp($line);
        $entry->{title} = $line;

        chomp($line);
        my $argument = $1 if $line =~ /\[([^\]]+)\].*/;

        $entry->{arg} = $argument;
        push(@items, $entry);
    }
}

my $output = {};
$output->{items} = \@items;

printf(encode_json($output));
