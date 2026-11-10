#! /usr/bin/env fish
if not test -f "Package.swift"
	echo "This script must be run from the `Scripts` package directory, where Package.swift is located."
	exit 1
end

swift package clean
swift build -c release

set -l binaries (cat Package.swift | rg -r '$1' '\s*\.executable\(name: "([^"]*)".*' | xargs printf "./.build/release/%s\n")

set -l bin_dir (path resolve (status dirname)/../bin)
mkdir -p $bin_dir

for bin in $binaries
	set -l name (basename $bin)
	echo "Installing $name to $bin_dir"
	cp $bin $bin_dir/
end

echo "Installed "(count $binaries)" binaries to $bin_dir"

# Install fish completions
set -l completions_dir ~/.config/fish/completions
mkdir -p $completions_dir

for bin in $binaries
	set -l name (basename $bin)
	set -l completion_file "$completions_dir/$name.fish"
	echo "Generating fish completions for $name"
	$bin --generate-completion-script fish > $completion_file
end

echo "Installed "(count $binaries)" fish completion scripts to $completions_dir"
