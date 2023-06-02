/*
Copyright © 2022 NAME HERE <EMAIL ADDRESS>

*/
package cmd

import (
	"fmt"
	"os"
	"os/exec"

	"github.com/charmbracelet/bubbles/textinput"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/spf13/cobra"
)

// nukeDerivedDataCmd represents the nukeDerivedData command
var nukeDerivedDataCmd = &cobra.Command{
	Use:   "nukeDerivedData",
	Short: "Nuke Xcode's DerivedData directory.",
	Long: `Nuke Xcode's DerivedData directory, checking first if DerivedData is in a custom location.

	The custom location is determined by checking "defaults read com.apple.dt.Xcode.plist IDECustomDerivedDataLocation"`,
	Run: func(cmd *cobra.Command, args []string) {
		derivedDataPath := os.ExpandEnv("$HOME/Library/Developer/Xcode/DerivedData")

		output, err := exec.Command("defaults", "read", "com.apple.dt.Xcode", "IDECustomDerivedDataLocation").Output()
		if err == nil {
			derivedDataPath = string(output)
		}

		p := tea.NewProgram(newNukeDerivedDataModel(derivedDataPath))
		if err := p.Start(); err != nil {
			fmt.Printf("Error: %v\n", err)
			os.Exit(1)
		}

	},
}

func init() {
	rootCmd.AddCommand(nukeDerivedDataCmd)

	// Here you will define your flags and configuration settings.

	// Cobra supports Persistent Flags which will work for this command
	// and all subcommands, e.g.:
	// nukeDerivedDataCmd.PersistentFlags().String("foo", "", "A help for foo")

	// Cobra supports local flags which will only run when this command
	// is called directly, e.g.:
	// nukeDerivedDataCmd.Flags().BoolP("toggle", "t", false, "Help message for toggle")
}

// Bubble Tea App

type nukeDerivedDataModel struct {
	derivedDataPath string
	textInput       textinput.Model
	err             error
}

func newNukeDerivedDataModel(derivedDataPath string) nukeDerivedDataModel {
	ti := textinput.New()
	ti.Focus()
	return nukeDerivedDataModel{
		derivedDataPath: derivedDataPath,
		textInput:       ti,
		err:             nil,
	}
}

func (n nukeDerivedDataModel) Init() tea.Cmd {
	return textinput.Blink
}

func (n nukeDerivedDataModel) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "enter":
			if n.textInput.Value() == "yes" {
				n.NukeDerivedData()
			}
			return n, tea.Quit
		case "ctrl+c":
			return n, tea.Quit
		}
	case error:
		n.err = msg
		return n, nil
	}
	var cmd tea.Cmd
	n.textInput, cmd = n.textInput.Update(msg)
	return n, cmd
}

func (n nukeDerivedDataModel) View() string {
	return fmt.Sprintf(
		`Are you sure you'd like to delete the DerivedData directory? Anything except "yes" will no-op.
DerivedData path = %s

%s

(ctrl+c to quit)
		`,
		n.derivedDataPath,
		n.textInput.View(),
	)
}

func (n nukeDerivedDataModel) NukeDerivedData() {
	err := os.RemoveAll(n.derivedDataPath)
	if err != nil {
		fmt.Printf("Error: %v\n", err)
		os.Exit(1)
	}
	fmt.Printf("Deleted %v\n", n.derivedDataPath)
}
