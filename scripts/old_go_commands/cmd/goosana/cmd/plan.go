/*
Copyright © 2022 Gustavo Poscidonio <mail@gustavo.sh>
*/
package cmd

import (
	"fmt"
	"os"
	"strings"
	"time"

	"github.com/atotto/clipboard"
	"github.com/charmbracelet/bubbles/table"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"github.com/gposcidonio/scripts/asana"
	"github.com/spf13/cobra"
	"golang.org/x/term"
)

var planCmdFlags = struct {
	useTaskPaperFormat *bool
}{}

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

	planCmdFlags.useTaskPaperFormat = planCmd.Flags().BoolP("taskpaper", "t", false, "Determines whether to use taskpaper format for the output.")

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
			tasksToProcess := make([]asana.AsanaTask, 0)
			for i, task := range m.tasks {
				if m.selectedRows[i] {
					tasksToProcess = append(tasksToProcess, task)
				}
			}
			outputString := buildOutputString(tasksToProcess, *planCmdFlags.useTaskPaperFormat)
			_ = clipboard.WriteAll(outputString)
			fmt.Print(outputString)
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

		var style = styleForTask(task)
		rowName = style.SetString(rowName).String()
		dueDate := style.SetString(task.DueDate).String()
		rows = append(rows, table.Row{rowName, dueDate})
	}
	m.table.SetRows(rows)
}

func (m *planModel) toggleRowSelection(n int) {
	m.selectedRows[n] = !m.selectedRows[n]
}

func newTable(tasks []asana.AsanaTask) table.Model {
	termWidth, _, _ := term.GetSize(int(os.Stdin.Fd()))
	columns := []table.Column{
		{Title: "Name", Width: termWidth - 20 - 6},
		{Title: "Due Date", Width: 20},
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
		Background(lipgloss.Color("#4c4b4a")).
		Bold(false)

	t.SetStyles(s)

	return t
}

// App Logic

func buildOutputString(tasks []asana.AsanaTask, useTaskPaperFormat bool) string {
	if useTaskPaperFormat {
		return buildTaskpaperOutputString(tasks)
	} else {
		return buildMarkdownOutputString(tasks)
	}
}

func buildMarkdownOutputString(tasks []asana.AsanaTask) string {
	builder := strings.Builder{}
	for _, task := range tasks {
		markdownTitle := strings.ReplaceAll(task.Text, "[", "\\[")
		markdownTitle = strings.ReplaceAll(markdownTitle, "]", "\\]")
		makrdownURL := fmt.Sprintf("https://app.asana.com/0/0/%v", task.ID)
		builder.WriteString(fmt.Sprintf("- [ ] [%v](%v)\n", markdownTitle, makrdownURL))
	}
	return builder.String()
}

func buildTaskpaperOutputString(tasks []asana.AsanaTask) string {
	builder := strings.Builder{}
	for _, task := range tasks {
		taskLine := fmt.Sprintf("- %v @tags(asana)", task.Text)
		notesText := fmt.Sprintf("\thttps://app.asana.com/0/0/%v", task.ID)
		builder.WriteString(fmt.Sprintf("%v\n%v\n", taskLine, notesText))
	}
	return builder.String()
}

func styleForTask(t asana.AsanaTask) lipgloss.Style {
	foregroundColor := lipgloss.NewStyle().Foreground(lipgloss.Color("7"))
	taskDueDate, err := time.Parse("2006-01-02", t.DueDate)
	if err != nil {
		return foregroundColor
	}

	if taskDueDate.Before(time.Now()) {
		foregroundColor = foregroundColor.Foreground(lipgloss.Color("1"))
	} else if taskDueDate.Before(time.Now().AddDate(0, 0, 1)) {
		foregroundColor = foregroundColor.Foreground(lipgloss.Color("2"))
	}

	return foregroundColor
}
