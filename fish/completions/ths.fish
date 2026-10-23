# A function which filters options which starts with "-" from $argv.
function _swift_ths_preprocessor
    set -l results
    for i in (seq (count $argv))
        switch (echo $argv[$i] | string sub -l 1)
            case '-'
            case '*'
                echo $argv[$i]
        end
    end
end

function _swift_ths_using_command
    set -l currentCommands (_swift_ths_preprocessor (commandline -opc))
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

complete -c ths -n '_swift_ths_using_command "ths status"' -l source -d 'The Honking Smith folder in the vault. Defaults to $THS_SOURCE_DIR.'
complete -c ths -n '_swift_ths_using_command "ths status"' -l site -d 'The website repo. Defaults to $THS_SITE_DIR.'
complete -c ths -n '_swift_ths_using_command "ths status"' -s h -l help -d 'Show help information.'
complete -c ths -n '_swift_ths_using_command "ths sync"' -l source -d 'The Honking Smith folder in the vault. Defaults to $THS_SOURCE_DIR.'
complete -c ths -n '_swift_ths_using_command "ths sync"' -l site -d 'The website repo. Defaults to $THS_SITE_DIR.'
complete -c ths -n '_swift_ths_using_command "ths sync"' -l write -d 'Apply the changes. Without it, sync only shows what it would do.'
complete -c ths -n '_swift_ths_using_command "ths sync"' -s h -l help -d 'Show help information.'
complete -c ths -n '_swift_ths_using_command "ths deploy"' -s h -l help -d 'Show help information.'
complete -c ths -n '_swift_ths_using_command "ths" "status sync deploy help"' -s h -l help -d 'Show help information.'
complete -c ths -n '_swift_ths_using_command "ths" "status sync deploy help"' -f -a 'status' -d 'Shows where each post stands between the vault and the site, without changing anything.'
complete -c ths -n '_swift_ths_using_command "ths" "status sync deploy help"' -f -a 'sync' -d 'Writes the vault\'s blog posts into the site repo.'
complete -c ths -n '_swift_ths_using_command "ths" "status sync deploy help"' -f -a 'deploy' -d 'Builds the site and deploys it to Cloudflare. Not implemented yet.'
complete -c ths -n '_swift_ths_using_command "ths" "status sync deploy help"' -f -a 'help' -d 'Show subcommand help information.'
