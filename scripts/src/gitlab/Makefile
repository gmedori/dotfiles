build:
	go build

clean:
	rm gitlab

install: build
	mv gitlab ../../bin/

uninstall:
	rm ../../bin/gitlab

reinstall: uninstall install
