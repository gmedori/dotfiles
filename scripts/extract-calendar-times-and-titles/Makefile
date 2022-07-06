build:
	go build
	
.PHONY: clean build install uninstall

.SILENT: clean

install: build
	cp extract-calendar-times-and-titles ../bin

uninstall:
	rm ../bin/extract-calendar-times-and-titles

clean:
	rm extract-calendar-times-and-titles 2>/dev/null || true

