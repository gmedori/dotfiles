function __tp_should_offer_completions_for_flags_or_options -a expected_commands
    set -l non_repeating_flags_or_options $argv[2..]
    set -l non_repeating_flags_or_options_absent 0
    set -l positional_index 0
    set -l commands
    __tp_parse_tokens
    test "$commands" = "$expected_commands"; and return $non_repeating_flags_or_options_absent
end

function __tp_should_offer_completions_for_positional -a expected_commands positional_index_comparison expected_positional_index
    set -l non_repeating_flags_or_options
    set -l non_repeating_flags_or_options_absent 0
    set -l positional_index 0
    set -l commands
    __tp_parse_tokens
    test "$commands" = "$expected_commands" -a \( "$positional_index" "$positional_index_comparison" "$expected_positional_index" \)
end

function __tp_parse_tokens -S
    set -l unparsed_tokens (__tp_tokens -pc)
    switch $unparsed_tokens[1]
    case 'tp'
        __tp_parse_subcommand 0 'h/help'
        switch $unparsed_tokens[1]
        case 'deploy'
            __tp_parse_subcommand 1 'base-image-repo=' 'base-image-tag=' 'cc=' 'teleport-dir=' 'h/help'
        case 'tsh'
            __tp_parse_subcommand 0 'h/help'
            switch $unparsed_tokens[1]
            case 'list'
                __tp_parse_subcommand 0 'h/help'
            case 'use'
                __tp_parse_subcommand 1 'path=' 'source=' 'h/help'
            case 'current'
                __tp_parse_subcommand 0 'h/help'
            case 'unlink'
                __tp_parse_subcommand 0 'h/help'
            end
        case 'help'
            __tp_parse_subcommand -r 1 
        end
    end
end

function __tp_tokens
    if test (string split -m 1 -f 1 -- . "$FISH_VERSION") -gt 3
        commandline --tokens-raw $argv
    else
        commandline -o $argv
    end
end

function __tp_parse_subcommand -S -a positional_count
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

function __tp_complete_directories
    set -l token (commandline -t)
    string match -- '*/' $token
    set -l subdirs $token*/
    printf %s\n $subdirs
end

function __tp_custom_completion
    set -x SAP_SHELL fish
    set -x SAP_SHELL_VERSION $FISH_VERSION
    set -l tokens (__tp_tokens -p)
    if test -z "$(__tp_tokens -t)"
        set -l index (count (__tp_tokens -pc))
        set tokens $tokens[..$index] \'\' $tokens[(math $index + 1)..]
    end
    command $tokens[1] $argv $tokens
end

complete -c 'tp' -f
complete -c 'tp' -n '__tp_should_offer_completions_for_flags_or_options "tp" h help' -s 'h' -l 'help' -d 'Show help information.'
complete -c 'tp' -n '__tp_should_offer_completions_for_positional "tp" -eq 1' -fa 'deploy' -d 'Deploy a local Teleport build to a Cloud staging tenant'
complete -c 'tp' -n '__tp_should_offer_completions_for_positional "tp" -eq 1' -fa 'tsh' -d 'Manage the tsh executable available in ~/scripts/bin'
complete -c 'tp' -n '__tp_should_offer_completions_for_positional "tp" -eq 1' -fa 'help' -d 'Show subcommand help information.'
complete -c 'tp' -n '__tp_should_offer_completions_for_flags_or_options "tp deploy" base-image-repo' -l 'base-image-repo' -d 'Public ECR base-image repository used to resolve a nightly' -rfka ''
complete -c 'tp' -n '__tp_should_offer_completions_for_flags_or_options "tp deploy" base-image-tag' -l 'base-image-tag' -d 'Use an exact base-image tag instead of resolving the newest nightly' -rfka ''
complete -c 'tp' -n '__tp_should_offer_completions_for_flags_or_options "tp deploy" cc' -l 'cc' -d 'Linux amd64 C compiler passed to make; otherwise it is discovered automatically' -rfka ''
complete -c 'tp' -n '__tp_should_offer_completions_for_flags_or_options "tp deploy" teleport-dir' -l 'teleport-dir' -d 'Teleport checkout containing the deploy-cloud make target' -rfka ''
complete -c 'tp' -n '__tp_should_offer_completions_for_flags_or_options "tp deploy" h help' -s 'h' -l 'help' -d 'Show help information.'
complete -c 'tp' -n '__tp_should_offer_completions_for_flags_or_options "tp tsh" h help' -s 'h' -l 'help' -d 'Show help information.'
complete -c 'tp' -n '__tp_should_offer_completions_for_positional "tp tsh" -eq 1' -fa 'list' -d 'List discovered tsh installations'
complete -c 'tp' -n '__tp_should_offer_completions_for_positional "tp tsh" -eq 1' -fa 'use' -d 'Select a tsh installation by version or path'
complete -c 'tp' -n '__tp_should_offer_completions_for_positional "tp tsh" -eq 1' -fa 'current' -d 'Show the currently selected tsh installation'
complete -c 'tp' -n '__tp_should_offer_completions_for_positional "tp tsh" -eq 1' -fa 'unlink' -d 'Remove the managed tsh symbolic link'
complete -c 'tp' -n '__tp_should_offer_completions_for_flags_or_options "tp tsh list" h help' -s 'h' -l 'help' -d 'Show help information.'
complete -c 'tp' -n '__tp_should_offer_completions_for_flags_or_options "tp tsh use" path' -l 'path' -d 'Select the tsh executable at this path' -rfka ''
complete -c 'tp' -n '__tp_should_offer_completions_for_flags_or_options "tp tsh use" source' -l 'source' -d 'Limit a version selection to this installation source' -rfka 'connect standalone managed homebrew source other'
complete -c 'tp' -n '__tp_should_offer_completions_for_flags_or_options "tp tsh use" h help' -s 'h' -l 'help' -d 'Show help information.'
complete -c 'tp' -n '__tp_should_offer_completions_for_flags_or_options "tp tsh current" h help' -s 'h' -l 'help' -d 'Show help information.'
complete -c 'tp' -n '__tp_should_offer_completions_for_flags_or_options "tp tsh unlink" h help' -s 'h' -l 'help' -d 'Show help information.'
