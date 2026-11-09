function __iosd_should_offer_completions_for_flags_or_options -a expected_commands
    set -l non_repeating_flags_or_options $argv[2..]
    set -l non_repeating_flags_or_options_absent 0
    set -l positional_index 0
    set -l commands
    __iosd_parse_tokens
    test "$commands" = "$expected_commands"; and return $non_repeating_flags_or_options_absent
end

function __iosd_should_offer_completions_for_positional -a expected_commands positional_index_comparison expected_positional_index
    set -l non_repeating_flags_or_options
    set -l non_repeating_flags_or_options_absent 0
    set -l positional_index 0
    set -l commands
    __iosd_parse_tokens
    test "$commands" = "$expected_commands" -a \( "$positional_index" "$positional_index_comparison" "$expected_positional_index" \)
end

function __iosd_parse_tokens -S
    set -l unparsed_tokens (__iosd_tokens -pc)
    switch $unparsed_tokens[1]
    case 'iosd'
        __iosd_parse_subcommand 0 'h/help'
        switch $unparsed_tokens[1]
        case 'nuke-derived-data'
            __iosd_parse_subcommand 0 'h/help'
        case 'help'
            __iosd_parse_subcommand -r 1 
        end
    end
end

function __iosd_tokens
    if test (string split -m 1 -f 1 -- . "$FISH_VERSION") -gt 3
        commandline --tokens-raw $argv
    else
        commandline -o $argv
    end
end

function __iosd_parse_subcommand -S -a positional_count
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

function __iosd_complete_directories
    set -l token (commandline -t)
    string match -- '*/' $token
    set -l subdirs $token*/
    printf %s\n $subdirs
end

function __iosd_custom_completion
    set -x SAP_SHELL fish
    set -x SAP_SHELL_VERSION $FISH_VERSION
    set -l tokens (__iosd_tokens -p)
    if test -z "$(__iosd_tokens -t)"
        set -l index (count (__iosd_tokens -pc))
        set tokens $tokens[..$index] \'\' $tokens[(math $index + 1)..]
    end
    command $tokens[1] $argv $tokens
end

complete -c 'iosd' -f
complete -c 'iosd' -n '__iosd_should_offer_completions_for_flags_or_options "iosd" h help' -s 'h' -l 'help' -d 'Show help information.'
complete -c 'iosd' -n '__iosd_should_offer_completions_for_positional "iosd" -eq 1' -fa 'nuke-derived-data' -d 'Forcefully deletes the derived data directory where Xcode stores many intermediate products.'
complete -c 'iosd' -n '__iosd_should_offer_completions_for_positional "iosd" -eq 1' -fa 'help' -d 'Show subcommand help information.'
complete -c 'iosd' -n '__iosd_should_offer_completions_for_flags_or_options "iosd nuke-derived-data" h help' -s 'h' -l 'help' -d 'Show help information.'
