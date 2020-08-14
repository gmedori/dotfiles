/*
Copyright © 2020 NAME HERE <EMAIL ADDRESS>

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

	"github.com/spf13/cobra"
)

// projectCmd represents the project command
var projectCmd = &cobra.Command{
	Use:   "project <project_name>",
	Args:  cobra.ExactArgs(1),
	Short: "Creates a new Gitlab project with the specified name & namespace.",
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Printf("Creating new project at %v/%v/%v", projectFlags.Host, projectFlags.Namespace, args[0])
	},
}

var projectFlags struct {
	Namespace string
	Host      string
}

func init() {
	newCmd.AddCommand(projectCmd)

	// Here you will define your flags and configuration settings.

	// Cobra supports Persistent Flags which will work for this command
	// and all subcommands, e.g.:
	// projectCmd.PersistentFlags().String("foo", "", "A help for foo")
	projectCmd.PersistentFlags().StringVarP(&projectFlags.Namespace, "namespace", "n", "gposcidonio", "The namespace of the project you wish to create. This is often your Gitlab username.")
	projectCmd.PersistentFlags().StringVar(&projectFlags.Host, "host", "gitlab.com", "The hostname of the Gitlab instance you wish to access. Defaults to gitlab.com")

	// Cobra supports local flags which will only run when this command
	// is called directly, e.g.:
	// projectCmd.Flags().BoolP("toggle", "t", false, "Help message for toggle")
}
