.PHONY: all
all: build

.PHONY: install
install: build
	cp build/* gobin

.PHONY: build
build: build/*

.PHONY: clean
clean:
	rm -rf build/*

build/%: cmd/%/main.go cmd/%/**/*.go
	go build -o $@ $<

.PHONY: chapter-splitter
chapter-splitter: build/chapter-splitter

