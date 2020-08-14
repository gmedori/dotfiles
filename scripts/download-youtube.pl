#!/Users/fenrir/perl5/perlbrew/perls/perl-5.28.1/bin/perl

use strict;
use warnings;

use LWP::UserAgent;
use Mozilla::CA;

my $debug = 1;

sub pushover {
    my $message = shift;
    my $token = "ajnt2s64mkfr5a7qtkfp2jo3egi7h1";
    my $user_key = "u8pvdverbgxdcvvoh9tezhgfx1r2ee";

    print("$message\n");
    my $response = LWP::UserAgent->new()->post(
        "https://api.pushover.net/1/messages.json", 
        [
            "token" => $token,
            "user" => $user_key,
            "message" => $message,
        ]
    );

    print $response->decoded_content;
}

if (-d "/Volumes/Gyarados/Plex/Youtube") {
    chdir("/Volumes/Gyarados/Plex/Youtube");
} else {
    my $message = "Plex's YouTube directory does not exist. We must not be on the right machine.";
    pushover($message);
    exit 1;
}

my ($file_path) = @ARGV;

if (not defined $file_path) {
    pushover("Could not download video. No file path provided to script.");
    exit 1;
}

if (open(my $fh, '<:encoding(UTF-8)', $file_path)) {
    while (my $line = <$fh>) {
        chomp $line;
        if ($line =~ /https:\/\/[^y]*youtu(\.be|be.com)\/.*/) {
            my $video_file_name = qx(youtube-dl --get-filename -o '%(title)s-[%(id)s].%(ext)s' $line 2>&1);
            my $output = qx(youtube-dl -v -o '%(title)s-[%(id)s].%(ext)s' $line 2>&1);
            print($video_file_name);
            if ($? != 0) {
                pushover("An error occurred: $output");
            } else {
                my $message = "Successfully downloaded video! $video_file_name";
                if ($debug) {
                    $message = "$message\n$output";
                }
                pushover($message);
            }
        } else {
            pushover("$file_path did not match the YouTube Regex");
            exit 1;
        }
    }
    close($fh);
} else {
    pushover("Could not open provided file: $file_path");
    exit 1;
}

qx(rm $file_path)

