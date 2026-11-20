# A function which filters options which starts with "-" from $argv.
function _swift_pr-draft_preprocessor
    set -l results
    for i in (seq (count $argv))
        switch (echo $argv[$i] | string sub -l 1)
            case '-'
            case '*'
                echo $argv[$i]
        end
    end
end

function _swift_pr-draft_using_command
    set -l currentCommands (_swift_pr-draft_preprocessor (commandline -opc))
    set -l expectedCommands (string split " " $argv[1])
    set -l subcommands (string split " " $argv[2])
    if [ (count $currentCommands) -ge (count $expectedCommands) ]
        for i in (seq (count $expectedCommands))
            if [ $currentCommands[$i] != $expectedCommands[$i] ]
                return 1
            end
        end
        if [ (count $currentCommands) -eq (count $expectedCommands) ]
            return 0
        end
        if [ (count $subcommands) -gt 1 ]
            for i in (seq (count $subcommands))
                if [ $currentCommands[(math (count $expectedCommands) + 1)] = $subcommands[$i] ]
                    return 1
                end
            end
        end
        return 0
    end
    return 1
end

complete -c pr-draft -n '_swift_pr-draft_using_command "pr-draft prepare"' -l alt -d 'Alt text for attachment N, used over any the draft gives it. Repeat it for more attachments.'
complete -c pr-draft -n '_swift_pr-draft_using_command "pr-draft prepare"' -s h -l help -d 'Show help information.'
complete -c pr-draft -n '_swift_pr-draft_using_command "pr-draft create"' -l draft -d 'Open the pull request as a draft.'
complete -c pr-draft -n '_swift_pr-draft_using_command "pr-draft create"' -l label -d 'Add this label to the pull request. Repeat it for more labels.'
complete -c pr-draft -n '_swift_pr-draft_using_command "pr-draft create"' -s h -l help -d 'Show help information.'
complete -c pr-draft -n '_swift_pr-draft_using_command "pr-draft" "prepare create help"' -s h -l help -d 'Show help information.'
complete -c pr-draft -n '_swift_pr-draft_using_command "pr-draft" "prepare create help"' -f -a 'prepare' -d 'Stages a draft\'s images and videos and prints what it found as JSON.'
complete -c pr-draft -n '_swift_pr-draft_using_command "pr-draft" "prepare create help"' -f -a 'create' -d 'Opens the pull request for a draft that `prepare` staged.'
complete -c pr-draft -n '_swift_pr-draft_using_command "pr-draft" "prepare create help"' -f -a 'help' -d 'Show subcommand help information.'
