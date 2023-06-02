package cmd

import (
	"fmt"
	"os"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/spf13/cobra"
)

var rootCmd = &cobra.Command{
	Use:   "iosd",
	Short: "A brief description of your application",
	Long: `A longer description that spans multiple lines and likely contains
examples and usage of using your application. For example:

Cobra is a CLI library for Go that empowers applications.
This application is a tool to generate the needed files
to quickly create a Cobra application.`,
	// Uncomment the following line if your bare application
	// has an action associated with it:
	Run: func(cmd *cobra.Command, args []string) {
		p := tea.NewProgram(newRootModel())
		if err := p.Start(); err != nil {
			fmt.Printf("Error: %v\n", err)
			os.Exit(1)
		}
	},
}

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

	// rootCmd.PersistentFlags().StringVar(&cfgFile, "config", "", "config file (default is $HOME/.iosd.yaml)")

	// Cobra also supports local flags, which will only run
	// when this action is called directly.
	// rootCmd.Flags().BoolP("toggle", "t", false, "Help message for toggle")
}

// No Arg Application

type rootModel struct {
	cursor int
}

func newRootModel() rootModel {
	return rootModel{
		cursor: 0,
	}
}

func (r rootModel) Init() tea.Cmd {
	return nil
}

func (r rootModel) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "ctrl+c", "q":
			return r, tea.Quit
		case "up", "k":
			if r.cursor > 0 {
				r.cursor--
			}
		case "down", "j":
			if r.cursor < len(SelectableCommands(rootCmd))-1 {
				r.cursor++
			}
		case "enter", " ":
			r.ExecuteSelection(r.cursor)
			return r, tea.Quit
		}
	}
	return r, nil
}

func (r rootModel) View() string {
	s := "What would you like to do?\n\n"

	for i, subcommand := range SelectableCommands(rootCmd) {
		cursor := " "
		if i == r.cursor {
			cursor = ">"
		}
		s += fmt.Sprintf("%s %s\n", cursor, subcommand.Name())
	}

	s += "\nPress ctrl+c/q to quit.\n\n"

	return s
}

func (r rootModel) ExecuteSelection(index int) {
	subcommands := SelectableCommands(rootCmd)
	if index >= 0 && index < len(subcommands) {
		subcommands[index].Run(rootCmd, nil)
	}
}
