package cmd

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"
)

const (
	BlogRootDir = "~/Sync/Writing/techtechgoose/"
)

// TechTechGooseCmd represents the base command when called without any subcommands
var TechTechGooseCmd = &cobra.Command{
	Use:   "ttg",
	Short: "A CLI utility for managing the Tech Tech Goose blog.",
}

// Execute adds all child commands to the root command and sets flags appropriately.
// This is called by main.main(). It only needs to happen once to the rootCmd.
func Execute() {
	if err := TechTechGooseCmd.Execute(); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}

func init() {
}
