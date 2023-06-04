SHELL = fish
EXECUTABLES = iosd notify
BUILDS = $(foreach ex, ${EXECUTABLES}, target/release/${ex})

.PHONY: all clean install uninstall ${EXECUTABLES}

install: all bin
	cp ${BUILDS} bin

uninstall:
	rm -rf bin

all:
	cargo build --release

bin:
	mkdir -p bin
