.PHONY: all
all: build

.PHONY: install
install: build
	cp build/* gobin

.PHONY: build
build: chapter-splitter

chapter-splitter:
	go build -o ./build/chapter-splitter ./cmd/chapter-splitter/main.go
