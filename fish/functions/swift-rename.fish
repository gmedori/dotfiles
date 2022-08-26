function swift-rename
    set -l FROM $argv[1]
    set -l TO $argv[2]
    echo "Renaming all instances of \"$FROM\" to \"$TO\""
    echo "Executing `sd -s \"$FROM\" \"$TO\" (rg -l -t swift \"$FROM\")`"
    sd -s "$FROM" "$TO" (rg -l -t swift "$FROM")
end
