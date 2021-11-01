package cmd

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/spf13/cobra"
)

var newPostCmd = &cobra.Command{
	Use:   "post <post-name>",
	Args:  cobra.MinimumNArgs(1),
	Short: "Creates a new Hugo post in the /content/posts/ subdirectory.",
	Run:   createNewPost,
}

func init() {
	newCmd.AddCommand(newPostCmd)
}

func createNewPost(cmd *cobra.Command, args []string) {

	errFunc := func(err error) {
		fmt.Printf("Error when attempting to create a new post: %v\n", err)
		os.Exit(1)
	}

	oldDir, err := os.Getwd()
	if err != nil {
		errFunc(err)
	}
	defer func() {
		_ = os.Chdir(oldDir)
	}()

	err = os.Chdir(config.RootDir)
	if err != nil {
		errFunc(err)
	}

	postDirName := strings.Join(strings.Fields(strings.ToLower(strings.Join(args, " "))), "-")
	postPath := filepath.Join("posts", postDirName, "index.md")

	output, err := exec.Command("hugo", "new", postPath).Output()
	if err != nil {
		errFunc(err)
	}

	fmt.Print(string(output))
}
