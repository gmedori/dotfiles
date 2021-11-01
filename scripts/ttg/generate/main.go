package main

import (
	"fmt"
	"os"

	"gitlab.com/gposcidonio/scripts/ttg/cmd"
)

func main() {
	err := cmd.TechTechGooseCmd.GenFishCompletionFile("ttg.fish", true)
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}
