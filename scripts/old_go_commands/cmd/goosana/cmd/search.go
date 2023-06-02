/*
Copyright © 2022 Gustavo Poscidonio <mail@gustavo.sh>
*/
package cmd

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"
)

// searchCmd represents the search command
var searchCmd = &cobra.Command{
	Use:   "search",
	Short: "Search for tasks",
	// Long: `A longer description that spans multiple lines and likely contains examples
	// and usage of using your command. For example:

	// Cobra is a CLI library for Go that empowers applications.
	// This application is a tool to generate the needed files
	// to quickly create a Cobra application.`,
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("search called")
		fmt.Printf("GOOSANA_KEY length = %v.\n", len(goosanaKey))
		ws, _, err := asanaClient.Workspaces()
		if err != nil {
			cmd.PrintErrf("Error: %v\n", err)
			os.Exit(1)
		}
		for _, w := range ws {
			fmt.Printf("Workspace: %v.\n", w.Name)
		}
	},
}

func init() {
	rootCmd.AddCommand(searchCmd)

	// Here you will define your flags and configuration settings.

	// Cobra supports Persistent Flags which will work for this command
	// and all subcommands, e.g.:
	// searchCmd.PersistentFlags().String("foo", "", "A help for foo")

	// Cobra supports local flags which will only run when this command
	// is called directly, e.g.:
	// searchCmd.Flags().BoolP("toggle", "t", false, "Help message for toggle")
}
