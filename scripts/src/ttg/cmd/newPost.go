package cmd

import (
	"fmt"
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
	postName := properTitle(strings.Join(args, " "))
	fmt.Printf("Creating Project %v\n", postName)
}

func properTitle(input string) string {
	words := strings.Split(input, " ")
	smallwords := " a an on the to "

	for index, word := range words {
		if strings.Contains(smallwords, " "+word+" ") && word != string(word[0]) {
			words[index] = word
		} else {
			words[index] = strings.Title(word)
		}
	}

	return strings.Join(words, " ")
}
