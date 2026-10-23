# A function which filters options which starts with "-" from $argv.
function _swift_tp_preprocessor
    set -l results
    for i in (seq (count $argv))
        switch (echo $argv[$i] | string sub -l 1)
            case '-'
            case '*'
                echo $argv[$i]
        end
    end
end

function _swift_tp_using_command
    set -l currentCommands (_swift_tp_preprocessor (commandline -opc))
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

complete -c tp -n '_swift_tp_using_command "tp deploy"' -l base-image-repo -d 'Public ECR base-image repository used to resolve a nightly'
complete -c tp -n '_swift_tp_using_command "tp deploy"' -l base-image-tag -d 'Use an exact base-image tag instead of resolving the newest nightly'
complete -c tp -n '_swift_tp_using_command "tp deploy"' -l cc -d 'Linux amd64 C compiler passed to make; otherwise it is discovered automatically'
complete -c tp -n '_swift_tp_using_command "tp deploy"' -l teleport-dir -d 'Teleport checkout containing the deploy-cloud make target'
complete -c tp -n '_swift_tp_using_command "tp deploy"' -s h -l help -d 'Show help information.'
complete -c tp -n '_swift_tp_using_command "tp tsh list"' -s h -l help -d 'Show help information.'
complete -c tp -n '_swift_tp_using_command "tp tsh use"' -l path -d 'Select the tsh executable at this path'
complete -c tp -n '_swift_tp_using_command "tp tsh use"' -l source -d 'Limit a version selection to this installation source' -r -f -k -a 'connect standalone managed homebrew source other'
complete -c tp -n '_swift_tp_using_command "tp tsh use"' -s h -l help -d 'Show help information.'
complete -c tp -n '_swift_tp_using_command "tp tsh current"' -s h -l help -d 'Show help information.'
complete -c tp -n '_swift_tp_using_command "tp tsh unlink"' -s h -l help -d 'Show help information.'
complete -c tp -n '_swift_tp_using_command "tp tsh" "list use current unlink"' -s h -l help -d 'Show help information.'
complete -c tp -n '_swift_tp_using_command "tp tsh" "list use current unlink"' -f -a 'list' -d 'List discovered tsh installations'
complete -c tp -n '_swift_tp_using_command "tp tsh" "list use current unlink"' -f -a 'use' -d 'Select a tsh installation by version or path'
complete -c tp -n '_swift_tp_using_command "tp tsh" "list use current unlink"' -f -a 'current' -d 'Show the currently selected tsh installation'
complete -c tp -n '_swift_tp_using_command "tp tsh" "list use current unlink"' -f -a 'unlink' -d 'Remove the managed tsh symbolic link'
complete -c tp -n '_swift_tp_using_command "tp" "deploy tsh help"' -s h -l help -d 'Show help information.'
complete -c tp -n '_swift_tp_using_command "tp" "deploy tsh help"' -f -a 'deploy' -d 'Deploy a local Teleport build to a Cloud staging tenant'
complete -c tp -n '_swift_tp_using_command "tp" "deploy tsh help"' -f -a 'tsh' -d 'Manage the tsh executable available in ~/scripts/bin'
complete -c tp -n '_swift_tp_using_command "tp" "deploy tsh help"' -f -a 'help' -d 'Show subcommand help information.'
