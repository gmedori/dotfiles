package cmd

import (
	"fmt"
	"os"
	"os/exec"
	"strings"

	"github.com/spf13/cobra"
)

// RootCmd represents the base command when called without any subcommands
var RootCmd = &cobra.Command{
	Use:   "chapter-splitter",
	Short: "A CLI utility for splitting MKV files on chapters. Requires mkvmerge to be installed.",
	// Uncomment the following line if your bare application
	// has an action associated with it:
	Run: run,
}

// Execute adds all child commands to the root command and sets flags appropriately.
// This is called by main.main(). It only needs to happen once to the rootCmd.
func Execute() {
	if err := RootCmd.Execute(); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}

func init() {
	// Here you will define your flags and configuration settings.
	// Cobra supports persistent flags, which, if defined here,
	// will be global for your application.

	RootCmd.Flags().StringVarP(&inputFile, "input", "i", "", "the input MKV file to split. this flag is required.")
	RootCmd.Flags().StringVarP(&outputFormat, "output", "o", "output-%02d", "output format. use %n to denote where to put the episode number.")
	RootCmd.Flags().IntVarP(&firstChapter, "first-chapter", "f", 1, "The chapter at which to start splitting.")
	RootCmd.Flags().IntVarP(&chapterStep, "step", "s", 1, "The number of chapters to include before the next split.")
	RootCmd.Flags().IntVarP(&numEpisodes, "num-episodes", "n", 1, "The number of episodes to make.")
	RootCmd.Flags().IntVarP(&startingEpisodeNumber, "start-episode-num", "e", 1, "The episode number to start with when labeling the output files.")

	cobra.MarkFlagRequired(RootCmd.Flags(), "input")
}

var (
	inputFile             string
	outputFormat          string
	firstChapter          int
	chapterStep           int
	numEpisodes           int
	startingEpisodeNumber int
)

func run(cmd *cobra.Command, args []string) {
	if _, err := exec.LookPath("mkvmerge"); err != nil {
		fmt.Println("dependency mkvmerge not found in PATH. aborting...")
		os.Exit(1)
	}

	if _, err := os.Stat(inputFile); err != nil {
		if os.IsNotExist(err) {
			fmt.Printf("%s does not exist\n", inputFile)
			os.Exit(1)
		}
	}

	chapterSplits := make([]string, 0)
	for i := firstChapter; len(chapterSplits) < numEpisodes; i += chapterStep {
		chapterSplits = append(chapterSplits, fmt.Sprint(i))
	}

	chapters := strings.Join(chapterSplits, ",")

	mkvmerge := exec.Command("mkvmerge", "-o", "output-%03d.mkv", "--split", fmt.Sprintf("chapters:%s", chapters), inputFile)
	mkvmerge.Stdout = os.Stdout
	mkvmerge.Stderr = os.Stderr
	err := mkvmerge.Run()
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	for i := 1; i <= numEpisodes; i++ {
		episodeNumber := startingEpisodeNumber + i - 1
		format := strings.Replace(outputFormat, "%n", fmt.Sprintf("%02d", episodeNumber), 1)
		err = os.Rename(fmt.Sprintf("output-%03d.mkv", i), format)
		if err != nil {
			fmt.Printf("error renaming %v to %v: %v\n", fmt.Sprintf("output-%03d.mkv", i), format, err)
			os.Exit(1)
		}
	}
}
