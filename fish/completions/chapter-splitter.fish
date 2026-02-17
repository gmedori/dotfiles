# A function which filters options which starts with "-" from $argv.
function _swift_chapter-splitter_preprocessor
    set -l results
    for i in (seq (count $argv))
        switch (echo $argv[$i] | string sub -l 1)
            case '-'
            case '*'
                echo $argv[$i]
        end
    end
end

function _swift_chapter-splitter_using_command
    set -l currentCommands (_swift_chapter-splitter_preprocessor (commandline -opc))
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

complete -c chapter-splitter -n '_swift_chapter-splitter_using_command "chapter-splitter"' -s i -l input -d 'The input MKV file to split'
complete -c chapter-splitter -n '_swift_chapter-splitter_using_command "chapter-splitter"' -s o -l output -d 'The format of the output files; use %n to indicate where to place the number'
complete -c chapter-splitter -n '_swift_chapter-splitter_using_command "chapter-splitter"' -l first-chapter -s f -d 'The chapter number to begin splitting on, 1-indexed; any chapters before this are ignored'
complete -c chapter-splitter -n '_swift_chapter-splitter_using_command "chapter-splitter"' -s s -l step -d 'The number of chapters to include in each video'
complete -c chapter-splitter -n '_swift_chapter-splitter_using_command "chapter-splitter"' -l number-of-episodes -s n -d 'The number of videos/episodes to make'
complete -c chapter-splitter -n '_swift_chapter-splitter_using_command "chapter-splitter"' -s e -l starting-episode-number -d 'The episode number to start with when labeling the output files'
complete -c chapter-splitter -n '_swift_chapter-splitter_using_command "chapter-splitter"' -s h -l help -d 'Show help information.'
