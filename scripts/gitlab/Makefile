build:
	go build

clean:
	rm gitlab

install: build generateFishCompletion
	mv gitlab ../bin/
	mv gitlab.fish ~/dotfiles/fish/completions/


uninstall:
	-rm ../bin/gitlab 2> /dev/null
	-rm ~/dotfiles/fish/completions/gitlab.fish 2> /dev/null

reinstall: uninstall install

generateFishCompletion:
	go run generate/main.go

