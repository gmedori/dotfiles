build:
	go build

clean:
	-rm autogen

install: build generateFishCompletion
	mv autogen ../../bin/
	mv autogen.fish ~/dotfiles/fish/completions/


uninstall:
	-rm ../../bin/autogen 2> /dev/null
	-rm ~/dotfiles/fish/completions/autogen.fish 2> /dev/null

reinstall: uninstall install

generateFishCompletion:
	go run generate/main.go

