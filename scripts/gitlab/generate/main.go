package main

import (
	"fmt"
	"os"

	"gitlab.com/gposcidonio/scripts/gitlab/cmd"
)

func main() {
	err := cmd.GitlabCmd.GenFishCompletionFile("gitlab.fish", true)
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}
