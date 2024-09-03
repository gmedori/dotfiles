#! /usr/bin/env fish
if not test -f "Package.swift"
	echo "This script must be run from the project root of the scripts repo where Package.swift is located."
	exit 1
end

swift package clean
swift build -c release

set -l binaries (cat Package.swift | rg -r '$1' '\s*\.executable\(name: "([^"]*)".*' | xargs printf "./.build/release/%s\n")

for bin in $binaries
	echo "Install script would install $bin but installation isn't implemented yet."
end
