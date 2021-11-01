build:
	go build

clean:
	-rm ttg

install: build generateFishCompletion
	mv ttg ../bin/
	mv ttg.fish ~/dotfiles/fish/completions/


uninstall:
	-rm ../bin/ttg 2> /dev/null
	-rm ~/dotfiles/fish/completions/ttg.fish 2> /dev/null

reinstall: uninstall install

generateFishCompletion:
	go run generate/main.go

