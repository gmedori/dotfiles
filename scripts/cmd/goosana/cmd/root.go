/*
Copyright © 2022 Gustavo Poscidonio <mail@gustavo.sh>
*/
package cmd

import (
	"fmt"
	"os"

	"github.com/gposcidonio/scripts/asana"
	"github.com/spf13/cobra"
)

var goosanaKey string
var defaultWorkspaceID = "15793206719"

// rootCmd represents the base command when called without any subcommands
var rootCmd = &cobra.Command{
	Use:   "goosana",
	Short: "Interact with Asana on the command line.",
	// Uncomment the following line if your bare application
	// has an action associated with it:
	Run: func(cmd *cobra.Command, args []string) {
		client := &asana.AsanaClient{APIKey: goosanaKey}
		tasks, err := client.GetTasks(defaultWorkspaceID)
		if err != nil {
			fmt.Fprintf(os.Stderr, "Bad stuff happened getting tasks: %v\n", err)
			os.Exit(1)
		}
		fmt.Printf("Fount %v tasks!\n", len(tasks))
		for _, t := range tasks {
			fmt.Printf("%v - %v\n", t.DueDate, t.Text)
		}
	},
}

// Execute adds all child commands to the root command and sets flags appropriately.
// This is called by main.main(). It only needs to happen once to the rootCmd.
func Execute() {
	err := rootCmd.Execute()
	if err != nil {
		os.Exit(1)
	}
}

func init() {
	// Here you will define your flags and configuration settings.
	// Cobra supports persistent flags, which, if defined here,
	// will be global for your application.

	// rootCmd.PersistentFlags().StringVar(&cfgFile, "config", "", "config file (default is $HOME/.goosana.yaml)")
	rootCmd.PersistentFlags().StringVarP(&goosanaKey, "key", "k", "", "API access token for Asana")

	// Cobra also supports local flags, which will only run
	// when this action is called directly.
	// rootCmd.Flags().BoolP("toggle", "t", false, "Help message for toggle")

	// Default to looking up the GOOSANA_KEY environment variable if goosanaKey is empty.
	goosanaKeyIsSet := false
	if len(goosanaKey) == 0 {
		goosanaKey, goosanaKeyIsSet = os.LookupEnv("GOOSANA_KEY")
	}
	if !goosanaKeyIsSet {
		fmt.Fprintf(os.Stderr, "No API key set. Please use --key or set the GOOSANA_KEY environment variable.")
		os.Exit(1)
	}
}
