function activate
	osascript -e 'tell application "System Events" to set frontmost of (first process whose unix id is '"$argv"') to true'
end
