# A function which filters options which starts with "-" from $argv.
function _swift_notify_preprocessor
    set -l results
    for i in (seq (count $argv))
        switch (echo $argv[$i] | string sub -l 1)
            case '-'
            case '*'
                echo $argv[$i]
        end
    end
end

function _swift_notify_using_command
    set -l currentCommands (_swift_notify_preprocessor (commandline -opc))
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

complete -c notify -n '_swift_notify_using_command "notify"' -l title -s t -d 'The title of the message'
complete -c notify -n '_swift_notify_using_command "notify"' -l subtitle -d 'An optional subtitle to include with the notification'
complete -c notify -n '_swift_notify_using_command "notify"' -l sound -s s -d 'The sound to play when the notification is displayed' -r -f -k -a 'basso blow bottle frog funk glass hero morse ping pop purr sosumi submarine tink'
complete -c notify -n '_swift_notify_using_command "notify"' -s h -l help -d 'Show help information.'
