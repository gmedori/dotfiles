package cmd

import (
	"fmt"
	"os"
	"time"

	"github.com/spf13/cobra"
)

var dateRangesWithTitlesConfig struct {
	prefix       string
	startDateStr string
	frequency    time.Duration
	period       time.Duration
	count        int
}

// dateRangesWithTitlesCmd represents the dateRangesWithTitles command
var dateRangesWithTitlesCmd = &cobra.Command{
	Use:   "dateRangesWithTitles",
	Short: "Outputs a series of titles, each associated with a date range.",
	Long:  ``,
	Run: func(cmd *cobra.Command, args []string) {
		err := cmd.ParseFlags(args)
		if err != nil {
			fmt.Fprintf(os.Stderr, "An error occurred. Aborting...\n%v\n", err)
			os.Exit(1)
		}
		handleDateRangeWithTitlesCommand(cmd)
	},
}

func handleDateRangeWithTitlesCommand(cmd *cobra.Command) {
	cfg := dateRangesWithTitlesConfig
	dt, err := time.Parse("2006-01-02", cfg.startDateStr)
	if err != nil {
		fmt.Fprintf(os.Stderr, "An error ocurred. Aborting...\n%v\n", err)
		os.Exit(1)
	}

	for i := 0; i < cfg.count; i++ {
		startDate := dt.Add(time.Duration(i) * cfg.frequency)
		endDate := startDate.Add(cfg.period)
		fmt.Printf("%v%v:%v:%v\n", cfg.prefix, i+1, startDate.Format("2006-01-02"), endDate.Format("2006-01-02"))
	}
}

func init() {
	AutogenCmd.AddCommand(dateRangesWithTitlesCmd)

	// Here you will define your flags and configuration settings.

	// Cobra supports Persistent Flags which will work for this command
	// and all subcommands, e.g.:
	// dateRangesWithTitlesCmd.PersistentFlags().String("foo", "", "A help for foo")

	// Cobra supports local flags which will only run when this command
	// is called directly, e.g.:
	cfg := &dateRangesWithTitlesConfig
	command := dateRangesWithTitlesCmd

	command.Flags().StringVar(&cfg.prefix, "prefix", "", "String prefix format for the title. Use %%v to indicate where the number should go.")
	command.Flags().StringVar(&cfg.startDateStr, "startDate", "", "An ISO-8601 formatted date string indicating the start date.")
	command.Flags().DurationVarP(&cfg.frequency, "frequency", "f", 7*24*time.Hour, "A duration string indicating the frequency at which the date ranges repeat.")
	command.Flags().DurationVarP(&cfg.period, "period", "p", 4*24*time.Hour, "A duration string indicating the length of time between the start and end of the date range")
	command.Flags().IntVarP(&cfg.count, "count", "n", 0, "The number of periods to list in")

	command.MarkFlagRequired("prefix")
	command.MarkFlagRequired("startDate")
	command.MarkFlagRequired("count")
}
