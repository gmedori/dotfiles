# A function which filters options which starts with "-" from $argv.
function _swift_dia_preprocessor
    set -l results
    for i in (seq (count $argv))
        switch (echo $argv[$i] | string sub -l 1)
            case '-'
            case '*'
                echo $argv[$i]
        end
    end
end

function _swift_dia_using_command
    set -l currentCommands (_swift_dia_preprocessor (commandline -opc))
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

complete -c dia -n '_swift_dia_using_command "dia setup"' -s f -l force -d 'Force a fresh setup by passing --fresh to cmake'
complete -c dia -n '_swift_dia_using_command "dia setup"' -s h -l help -d 'Show help information.'
complete -c dia -n '_swift_dia_using_command "dia build"' -s h -l help -d 'Show help information.'
complete -c dia -n '_swift_dia_using_command "dia clean"' -s h -l help -d 'Show help information.'
complete -c dia -n '_swift_dia_using_command "dia run"' -s h -l help -d 'Show help information.'
complete -c dia -n '_swift_dia_using_command "dia workspace"' -s h -l help -d 'Show help information.'
complete -c dia -n '_swift_dia_using_command "dia" "setup build clean run workspace help"' -s h -l help -d 'Show help information.'
complete -c dia -n '_swift_dia_using_command "dia" "setup build clean run workspace help"' -f -a 'setup' -d 'Configure the Dia project with cmake'
complete -c dia -n '_swift_dia_using_command "dia" "setup build clean run workspace help"' -f -a 'build' -d 'Build the Dia target'
complete -c dia -n '_swift_dia_using_command "dia" "setup build clean run workspace help"' -f -a 'clean' -d 'Remove the dia-debug build directory'
complete -c dia -n '_swift_dia_using_command "dia" "setup build clean run workspace help"' -f -a 'run' -d 'Build and run the Dia target'
complete -c dia -n '_swift_dia_using_command "dia" "setup build clean run workspace help"' -f -a 'workspace' -d 'Open the current Dia project in a new Ghostty workspace'
complete -c dia -n '_swift_dia_using_command "dia" "setup build clean run workspace help"' -f -a 'help' -d 'Show subcommand help information.'
