build:
	go build

clean:
	-rm chapter-splitter

install: build generateFishCompletion
	mv chapter-splitter ../bin/
	mv chapter-splitter.fish ~/dotfiles/fish/completions/


uninstall:
	-rm ../bin/chapter-splitter 2> /dev/null
	-rm ~/dotfiles/fish/completions/chapter-splitter.fish 2> /dev/null

reinstall: uninstall install

generateFishCompletion:
	go run generate/main.go

