function pr-watch
	gh pr checks $argv[1] --watch; and say "PR Checks Complete"
end
