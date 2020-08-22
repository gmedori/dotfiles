package cmd

import (
	"github.com/spf13/cobra"
)

// newCmd represents the new command
var newCmd = &cobra.Command{
	Use:   "new",
	Short: "Creates new things like projects.",
}

func init() {
	GitlabCmd.AddCommand(newCmd)
}
