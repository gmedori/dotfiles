package main

import (
	"fmt"
	"os"

	"gitlab.com/gposcidonio/scripts/chapter-splitter/cmd"
)

func main() {
	err := cmd.RootCmd.GenFishCompletionFile("chapter-splitter.fish", true)
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}
