package cmd

import (
	"strings"

	"github.com/spf13/cobra"
)

func SelectableCommands(c *cobra.Command) (ret []*cobra.Command) {
	for _, command := range c.Commands() {
		if strings.Contains(command.Name(), "completion") {
			continue
		}
		ret = append(ret, command)
	}
	return
}
