package main

import (
	"fmt"
	"os"

	"gitlab.com/gposcidonio/scripts/autogen/cmd"
)

func main() {
	err := cmd.AutogenCmd.GenFishCompletionFile("autogen.fish", true)
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}
