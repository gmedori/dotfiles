function normalize_path --description 'Expand a leading ~ then resolve to a canonical absolute path'
    set -l p $argv[1]
    switch $p
        case '~'   ; set p $HOME
        case '~/*' ; set p $HOME/(string sub -s 3 -- $p)
    end
    path resolve -- $p
end
