#! /usr/bin/env fish
if not test -f "Package.swift"
	echo "This script must be run from the project root of the scripts repo where Package.swift is located."
	exit 1
end

swift package clean
swift build -c release

set -l binaries (cat Package.swift | rg -r '$1' '\s*\.executable\(name: "([^"]*)".*' | xargs printf "./.build/release/%s\n")

set -l bin_dir (git rev-parse --show-toplevel)/bin
mkdir -p $bin_dir

for bin in $binaries
	set -l name (basename $bin)
	echo "Installing $name to $bin_dir"
	cp $bin $bin_dir/
end

echo "Installed "(count $binaries)" binaries to $bin_dir"
