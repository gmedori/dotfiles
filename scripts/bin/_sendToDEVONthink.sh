#!/bin/bash

FILE=$1
DATABASE=$2
GROUP=$3

if [ -z $FILE ]; then
    echo "No file provided."
    exit 1
fi


if [ -z $GROUP ]; then
    echo "No group provided."
    exit 1
fi

if [ -z $DATABASE ]; then
    echo "No database provided."
    exit 1
fi


if [ -z $GROUP ]; then
    echo "No group provided."
    exit 1
fi

read -r -d '' SCRIPT << EOM
-- Lauch DEVONthink if it isn't already open.
tell application "System Events"
	if not (exists process "DEVONthink 3") then
		tell application "DEVONthink 3" to activate
	end if
end tell

-- Import the file.

tell application "DEVONthink 3"
	set theDatabase to open database "$DATABASE"
	set theGroup to create location "$GROUP" in theDatabase
	set theImport to import $FILE name _name to theGroup
	-- set theIndex to indicate _path to theGroup
end tell
EOM

osascript -e $SCRIPT
