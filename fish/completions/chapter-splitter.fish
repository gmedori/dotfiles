function __chapter-splitter_should_offer_completions_for_flags_or_options -a expected_commands
    set -l non_repeating_flags_or_options $argv[2..]
    set -l non_repeating_flags_or_options_absent 0
    set -l positional_index 0
    set -l commands
    __chapter-splitter_parse_tokens
    test "$commands" = "$expected_commands"; and return $non_repeating_flags_or_options_absent
end

function __chapter-splitter_should_offer_completions_for_positional -a expected_commands positional_index_comparison expected_positional_index
    set -l non_repeating_flags_or_options
    set -l non_repeating_flags_or_options_absent 0
    set -l positional_index 0
    set -l commands
    __chapter-splitter_parse_tokens
    test "$commands" = "$expected_commands" -a \( "$positional_index" "$positional_index_comparison" "$expected_positional_index" \)
end

function __chapter-splitter_parse_tokens -S
    set -l unparsed_tokens (__chapter-splitter_tokens -pc)
    switch $unparsed_tokens[1]
    case 'chapter-splitter'
        __chapter-splitter_parse_subcommand 0 'i/input=' 'o/output=' 'f/first-chapter=' 's/step=' 'n/number-of-episodes=' 'e/starting-episode-number=' 'h/help'
        switch $unparsed_tokens[1]
        case 'help'
            __chapter-splitter_parse_subcommand -r 1 
        end
    end
end

function __chapter-splitter_tokens
    if test (string split -m 1 -f 1 -- . "$FISH_VERSION") -gt 3
        commandline --tokens-raw $argv
    else
        commandline -o $argv
    end
end

function __chapter-splitter_parse_subcommand -S -a positional_count
    argparse -s r -- $argv
    set -l option_specs $argv[2..]
    set -l is_repeating_positional $_flag_r
    set -el _flag_r
    set -a commands $unparsed_tokens[1]
    set positional_index 0
    while true
        set -e unparsed_tokens[1]
        argparse -sn "$commands" $option_specs -- $unparsed_tokens 2> /dev/null
        set unparsed_tokens $argv
        set positional_index (math $positional_index + 1)
        for non_repeating_flag_or_option in $non_repeating_flags_or_options
            if set -ql "_flag_$(string replace -a - _ -- $non_repeating_flag_or_option)"
                set non_repeating_flags_or_options_absent 1
                break
            end
        end
        test (count $unparsed_tokens) -eq 0 -o \( -z "$is_repeating_positional" -a "$positional_index" -gt "$positional_count" \) && break
    end
end

function __chapter-splitter_complete_directories
    set -l token (commandline -t)
    string match -- '*/' $token
    set -l subdirs $token*/
    printf %s\n $subdirs
end

function __chapter-splitter_custom_completion
    set -x SAP_SHELL fish
    set -x SAP_SHELL_VERSION $FISH_VERSION
    set -l tokens (__chapter-splitter_tokens -p)
    if test -z "$(__chapter-splitter_tokens -t)"
        set -l index (count (__chapter-splitter_tokens -pc))
        set tokens $tokens[..$index] \'\' $tokens[(math $index + 1)..]
    end
    command $tokens[1] $argv $tokens
end

complete -c 'chapter-splitter' -f
complete -c 'chapter-splitter' -n '__chapter-splitter_should_offer_completions_for_flags_or_options "chapter-splitter" i input' -s 'i' -l 'input' -d 'The input MKV file to split' -rfka ''
complete -c 'chapter-splitter' -n '__chapter-splitter_should_offer_completions_for_flags_or_options "chapter-splitter" o output' -s 'o' -l 'output' -d 'The format of the output files; use %n to indicate where to place the number' -rfka ''
complete -c 'chapter-splitter' -n '__chapter-splitter_should_offer_completions_for_flags_or_options "chapter-splitter" f first-chapter' -l 'first-chapter' -s 'f' -d 'The chapter number to begin splitting on, 1-indexed; any chapters before this are ignored' -rfka ''
complete -c 'chapter-splitter' -n '__chapter-splitter_should_offer_completions_for_flags_or_options "chapter-splitter" s step' -s 's' -l 'step' -d 'The number of chapters to include in each video' -rfka ''
complete -c 'chapter-splitter' -n '__chapter-splitter_should_offer_completions_for_flags_or_options "chapter-splitter" n number-of-episodes' -l 'number-of-episodes' -s 'n' -d 'The number of videos/episodes to make' -rfka ''
complete -c 'chapter-splitter' -n '__chapter-splitter_should_offer_completions_for_flags_or_options "chapter-splitter" e starting-episode-number' -s 'e' -l 'starting-episode-number' -d 'The episode number to start with when labeling the output files' -rfka ''
complete -c 'chapter-splitter' -n '__chapter-splitter_should_offer_completions_for_flags_or_options "chapter-splitter" h help' -s 'h' -l 'help' -d 'Show help information.'
complete -c 'chapter-splitter' -n '__chapter-splitter_should_offer_completions_for_positional "chapter-splitter" -eq 1' -fa 'help' -d 'Show subcommand help information.'
