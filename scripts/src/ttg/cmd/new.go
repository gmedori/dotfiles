package cmd

import "github.com/spf13/cobra"

var newCmd = &cobra.Command{
	Use:   "new",
	Short: "Creates new things like posts.",
}

func init() {
	TechTechGooseCmd.AddCommand(newCmd)
}
