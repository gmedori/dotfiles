package main

import (
	"bufio"
	"fmt"
	"os"
	"regexp"
)

func main() {
	r := regexp.MustCompile(`(\d{2}:\d{2})`)

	s := bufio.NewScanner(os.Stdin)
	for s.Scan() {
		text := s.Text()
		if r.MatchString(text) {
			s.Scan()
			nextLine := s.Text()
			fmt.Printf("%v %v\n", r.FindString(text), nextLine)
		}
	}
}
