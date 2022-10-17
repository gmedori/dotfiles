EXECUTABLES = $(shell ls cmd)
BUILDS = $(foreach ex, ${EXECUTABLES},build/${ex})

.PHONY: all install uninstall build clean

all: build

install: build gobin
	cp ${BUILDS} gobin

uninstall:
	rm -rf gobin

build: ${BUILDS}

clean:
	rm -rf $(wildcard build/*)

build/%: cmd/%/main.go cmd/%/**/*.go
	go build -o $@ $<

gobin:
	mkdir -p gobin
