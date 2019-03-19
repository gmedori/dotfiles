function gr
    set DIR $PWD
    while not test -f $DIR/gradlew
        if [ $DIR = $HOME ]
            break
        end
        set DIR (dirname $DIR)
    end
    if test $DIR = $HOME
        echo "gradlew not found; defaulting to local gradle install"
        gradle $argv
    else
        echo "using $DIR/gradlew"
        eval $DIR/gradlew "$argv"
    end
end
