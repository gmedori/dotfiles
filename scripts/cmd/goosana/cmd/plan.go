/*
Copyright © 2022 Gustavo Poscidonio <mail@gustavo.sh>
*/
package cmd

import (
	"fmt"
	"os"
	"strings"

	"github.com/atotto/clipboard"
	"github.com/charmbracelet/bubbles/table"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"github.com/gposcidonio/scripts/asana"
	"github.com/spf13/cobra"
	"golang.org/x/term"
)

// planCmd represents the plan command
var planCmd = &cobra.Command{
	Use:   "plan",
	Short: "Plan your day based on tasks overdue and due soon.",
	Long: `This command will list all overdue and due soon tasks,
allowing you to choose which tasks you want to work on.

Those tasks will then be copied to your clipboard as Markdown tasks.`,
	Run: func(cmd *cobra.Command, args []string) {
		client := asana.AsanaClient{APIKey: goosanaKey}
		tasks, _ := client.GetTasks(defaultWorkspaceID)
		t := newTable(tasks)
		m := &planModel{table: t, tasks: tasks, selectedRows: make([]bool, len(tasks))}
		for i := range m.selectedRows {
			m.selectedRows[i] = true
		}
		m.recomputeRows()
		if err := tea.NewProgram(m).Start(); err != nil {
			fmt.Println("Error running program:", err)
			os.Exit(1)
		}
	},
}

func init() {
	rootCmd.AddCommand(planCmd)

	// Here you will define your flags and configuration settings.

	// Cobra supports Persistent Flags which will work for this command
	// and all subcommands, e.g.:
	// planCmd.PersistentFlags().String("foo", "", "A help for foo")

	// Cobra supports local flags which will only run when this command
	// is called directly, e.g.:
	// planCmd.Flags().BoolP("toggle", "t", false, "Help message for toggle")
}

// BubbleTea application

// Styling
var baseStyle = lipgloss.NewStyle().
	BorderStyle(lipgloss.NormalBorder()).
	BorderForeground(lipgloss.Color("240"))

type planModel struct {
	table        table.Model
	tasks        []asana.AsanaTask
	selectedRows []bool
}

func (m *planModel) Init() tea.Cmd {
	return nil
}

func (m *planModel) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	var cmd tea.Cmd
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "q", "ctrl+c":
			return m, tea.Quit
		case "tab", "t":
			m.toggleRowSelection(m.table.Cursor())
			m.recomputeRows()
			m.table.UpdateViewport()
			return m, cmd
		case "enter":
			builder := strings.Builder{}
			for i, task := range m.tasks {
				if !m.selectedRows[i] {
					continue
				}
				markdownTitle := strings.ReplaceAll(task.Text, "[", "\\[")
				markdownTitle = strings.ReplaceAll(markdownTitle, "]", "\\]")
				makrdownURL := fmt.Sprintf("https://app.asana.com/0/0/%v", task.ID)
				builder.WriteString(fmt.Sprintf("- [ ] [%v](%v)\n", markdownTitle, makrdownURL))
			}
			_ = clipboard.WriteAll(builder.String())
			fmt.Print(builder.String())
			return m, tea.Quit
		}
	}
	m.table, cmd = m.table.Update(msg)
	return m, cmd
}

func (m *planModel) View() string {
	return baseStyle.Render(m.table.View()) + "\n"
}

func (m *planModel) recomputeRows() {
	rows := make([]table.Row, 0)
	for i, task := range m.tasks {
		var rowName string
		if m.selectedRows[i] {
			rowName = fmt.Sprintf("✅ %v", task.Text)
		} else {
			rowName = task.Text
		}
		rows = append(rows, table.Row{rowName, task.DueDate})
	}
	m.table.SetRows(rows)
}

func (m *planModel) toggleRowSelection(n int) {
	m.selectedRows[n] = !m.selectedRows[n]
}

func newTable(tasks []asana.AsanaTask) table.Model {
	termWidth, _, _ := term.GetSize(int(os.Stdin.Fd()))
	columns := []table.Column{
		{Title: "Name", Width: termWidth - 12 - 6},
		{Title: "Due Date", Width: 12},
	}

	rows := make([]table.Row, 0)
	for _, task := range tasks {
		rows = append(rows, table.Row{task.Text, task.DueDate})
	}

	t := table.New(
		table.WithColumns(columns),
		table.WithRows(rows),
		table.WithFocused(true),
		table.WithHeight(20),
	)

	s := table.DefaultStyles()
	s.Header = s.Header.
		Foreground(lipgloss.Color("1")).
		BorderStyle(lipgloss.NormalBorder()).
		BorderForeground(lipgloss.Color("8")).
		BorderBottom(true).
		Bold(false)

	s.Selected = s.Selected.
		Foreground(lipgloss.Color("7")).
		Background(lipgloss.Color("1")).
		Bold(false)

	t.SetStyles(s)

	return t
}
