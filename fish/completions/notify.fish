function __notify_should_offer_completions_for_flags_or_options -a expected_commands
    set -l non_repeating_flags_or_options $argv[2..]
    set -l non_repeating_flags_or_options_absent 0
    set -l positional_index 0
    set -l commands
    __notify_parse_tokens
    test "$commands" = "$expected_commands"; and return $non_repeating_flags_or_options_absent
end

function __notify_should_offer_completions_for_positional -a expected_commands positional_index_comparison expected_positional_index
    set -l non_repeating_flags_or_options
    set -l non_repeating_flags_or_options_absent 0
    set -l positional_index 0
    set -l commands
    __notify_parse_tokens
    test "$commands" = "$expected_commands" -a \( "$positional_index" "$positional_index_comparison" "$expected_positional_index" \)
end

function __notify_parse_tokens -S
    set -l unparsed_tokens (__notify_tokens -pc)
    switch $unparsed_tokens[1]
    case 'notify'
        __notify_parse_subcommand -r 1 't/title=' 'subtitle=' 's/sound=' 'h/help'
        switch $unparsed_tokens[1]
        case 'help'
            __notify_parse_subcommand -r 1 
        end
    end
end

function __notify_tokens
    if test (string split -m 1 -f 1 -- . "$FISH_VERSION") -gt 3
        commandline --tokens-raw $argv
    else
        commandline -o $argv
    end
end

function __notify_parse_subcommand -S -a positional_count
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

function __notify_complete_directories
    set -l token (commandline -t)
    string match -- '*/' $token
    set -l subdirs $token*/
    printf %s\n $subdirs
end

function __notify_custom_completion
    set -x SAP_SHELL fish
    set -x SAP_SHELL_VERSION $FISH_VERSION
    set -l tokens (__notify_tokens -p)
    if test -z "$(__notify_tokens -t)"
        set -l index (count (__notify_tokens -pc))
        set tokens $tokens[..$index] \'\' $tokens[(math $index + 1)..]
    end
    command $tokens[1] $argv $tokens
end

complete -c 'notify' -f
complete -c 'notify' -n '__notify_should_offer_completions_for_flags_or_options "notify" t title' -l 'title' -s 't' -d 'The title of the message' -rfka ''
complete -c 'notify' -n '__notify_should_offer_completions_for_flags_or_options "notify" subtitle' -l 'subtitle' -d 'An optional subtitle to include with the notification' -rfka ''
complete -c 'notify' -n '__notify_should_offer_completions_for_flags_or_options "notify" s sound' -l 'sound' -s 's' -d 'The sound to play when the notification is displayed' -rfka 'basso blow bottle frog funk glass hero morse ping pop purr sosumi submarine tink'
complete -c 'notify' -n '__notify_should_offer_completions_for_flags_or_options "notify" h help' -s 'h' -l 'help' -d 'Show help information.'
complete -c 'notify' -n '__notify_should_offer_completions_for_positional "notify" -eq 1' -fa 'help' -d 'Show subcommand help information.'
