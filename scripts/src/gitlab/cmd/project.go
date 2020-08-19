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
	"os"
	"os/exec"

	"github.com/spf13/cobra"
)

// projectCmd represents the project command
var projectCmd = &cobra.Command{
	Use:   "project <project_name>",
	Args:  cobra.ExactArgs(1),
	Short: "Creates a new Gitlab project with the specified name & namespace.",
	Run: func(cmd *cobra.Command, args []string) {
		err := createNewProject(args[0], projectFlags.Namespace, projectFlags.Host)
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error: %v\n", err)
			os.Exit(1)
		}
		fmt.Printf("\nCreated new project at %v/%v/%v\n", projectFlags.Host, projectFlags.Namespace, args[0])
	},
}

var projectFlags struct {
	Namespace string
	Host      string
}

func init() {
	newCmd.AddCommand(projectCmd)
	projectCmd.Flags().StringVarP(&projectFlags.Namespace, "namespace", "n", "gposcidonio", "The namespace of the project you wish to create. This is often your Gitlab username.")
	projectCmd.Flags().StringVar(&projectFlags.Host, "host", "gitlab.com", "The hostname of the Gitlab instance you wish to access. Defaults to gitlab.com")
}

func createNewProject(name, namespace, host string) error {
	_, err := exec.LookPath("git")
	if err != nil {
		return err
	}

	insideGitRepo, err := isInsideGitRepo()
	if err != nil {
		return err
	}

	if !insideGitRepo {
		err = exec.Command("git", "init").Run()
		if err != nil {
			return err
		}
	}

	originURL := fmt.Sprintf("git@%v:%v/%v.git", host, namespace, name)
	output, err := exec.Command("git", "remote", "add", "origin", originURL).CombinedOutput()
	if err != nil {
		return fmt.Errorf("%v\n%v", err, string(output))
	}
	fmt.Print(string(output))

	output, err = exec.Command("git", "commit", "--allow-empty", "-m", "Initializing Gitlab repo.").CombinedOutput()
	if err != nil {
		return fmt.Errorf("%v\n%v", err, string(output))
	}
	fmt.Print(string(output))

	output, err = exec.Command("git", "push", "-u", "origin", "master").CombinedOutput()
	if err != nil {
		return fmt.Errorf("%v\n%v", err, string(output))
	}
	fmt.Print(string(output))

	return nil
}

func isInsideGitRepo() (bool, error) {
	cmd := exec.Command("git", "rev-parse", "--git-dir")
	err := cmd.Run()
	if err != nil {
		return false, nil
	}

	return true, nil
}
