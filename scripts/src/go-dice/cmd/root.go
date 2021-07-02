/*
Copyright © 2021 NAME HERE <EMAIL ADDRESS>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/
package cmd

import (
	"fmt"
	"os"
	"regexp"
	"strings"

	"github.com/c-bata/go-prompt"
	"github.com/spf13/cobra"

	homedir "github.com/mitchellh/go-homedir"
	"github.com/spf13/viper"
)

var cfgFile string

// rootCmd represents the base command when called without any subcommands
var rootCmd = &cobra.Command{
	Use:   "dice",
	Short: "A brief description of your application",
	Long: `A longer description that spans multiple lines and likely contains
examples and usage of using your application. For example:

Cobra is a CLI library for Go that empowers applications.
This application is a tool to generate the needed files
to quickly create a Cobra application.`,
	// Uncomment the following line if your bare application
	// has an action associated with it:
	Run: func(cmd *cobra.Command, args []string) {
		completer := func(d prompt.Document) []prompt.Suggest {
			if d.TextBeforeCursor() == "" {
				return []prompt.Suggest{}
			}

			args = strings.Split(d.TextBeforeCursor(), " ")
			w := d.GetWordBeforeCursor()

			if len(args) > 1 && args[len(args)-2] == "roll" {
				s := []prompt.Suggest{
					{Text: "1d20", Description: "Roll a d20."},
					{Text: "adv", Description: "Roll with advantage."},
				}

				if w == args[len(args)-2] {
					return s
				} else {
					return prompt.FilterFuzzy(s, w, true)
				}

			}

			s := []prompt.Suggest{
				{Text: "roll", Description: "Roll one or more dice"},
				{Text: "reroll", Description: "Reroll the last dice"},
			}

			return prompt.FilterHasPrefix(s, d.GetWordBeforeCursorWithSpace(), true)
		}

		executor := func(input string) {
			if input == "" {
				return
			}

			args := strings.Split(input, " ")

			switch args[0] {
			case "roll":
				roll(args[1:])
				fmt.Printf("Attempting to roll: %v\n", strings.Join(args[1:], ", "))
			case "exit":
				os.Exit(0)
			default:
				fmt.Printf("Unknown command: %v\n", args[0])
			}
		}

		p := prompt.New(executor, completer, prompt.OptionPrefix("> "))
		p.Run()
	},
}

func roll(args []string) {
	roller := NewRoller()
	regexp.MustCompile("^(\d*)d(\d+)$")
}

// Execute adds all child commands to the root command and sets flags appropriately.
// This is called by main.main(). It only needs to happen once to the rootCmd.
func Execute() {
	cobra.CheckErr(rootCmd.Execute())
}

func init() {
	cobra.OnInitialize(initConfig)

	// Here you will define your flags and configuration settings.
	// Cobra supports persistent flags, which, if defined here,
	// will be global for your application.

	rootCmd.PersistentFlags().StringVar(&cfgFile, "config", "", "config file (default is $HOME/.dice.yaml)")

	// Cobra also supports local flags, which will only run
	// when this action is called directly.
	rootCmd.Flags().BoolP("toggle", "t", false, "Help message for toggle")
}

// initConfig reads in config file and ENV variables if set.
func initConfig() {
	if cfgFile != "" {
		// Use config file from the flag.
		viper.SetConfigFile(cfgFile)
	} else {
		// Find home directory.
		home, err := homedir.Dir()
		cobra.CheckErr(err)

		// Search config in home directory with name ".dice" (without extension).
		viper.AddConfigPath(home)
		viper.SetConfigName(".dice")
	}

	viper.AutomaticEnv() // read in environment variables that match

	// If a config file is found, read it in.
	if err := viper.ReadInConfig(); err == nil {
		fmt.Fprintln(os.Stderr, "Using config file:", viper.ConfigFileUsed())
	}
}
