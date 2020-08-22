package cmd

import (
	"fmt"
	"os"
	"path"

	"github.com/mitchellh/go-homedir"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

var (
	cfgFile     string
	blogRootDir string
)

// TechTechGooseCmd represents the base command when called without any subcommands
var TechTechGooseCmd = &cobra.Command{
	Use:   "ttg",
	Short: "A CLI utility for managing the Tech Tech Goose blog.",
}

// Execute adds all child commands to the root command and sets flags appropriately.
// This is called by main.main(). It only needs to happen once to the rootCmd.
func Execute() {
	if err := TechTechGooseCmd.Execute(); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
	fmt.Printf("blogRootDir=%v\n", blogRootDir)
}

func init() {
	cobra.OnInitialize(initConfig)

	TechTechGooseCmd.PersistentFlags().StringVar(&cfgFile, "config", "", "config file (default is $HOME/.config/.ttg.yaml)")
	TechTechGooseCmd.PersistentFlags().StringVarP(&blogRootDir, "root", "r", "", "The blog's root directory.")
	viper.BindPFlag("root", TechTechGooseCmd.PersistentFlags().Lookup("root"))
}

// initConfig reads in config file and ENV variables if set.
func initConfig() {
	if cfgFile != "" {
		// Use config file from the flag.
		viper.SetConfigFile(cfgFile)
	} else {
		// Find home directory.
		home, err := homedir.Dir()
		if err != nil {
			fmt.Println(err)
			os.Exit(1)
		}

		configDir := path.Join(home, ".config")

		// Search config in config directory with name ".ttg" (without extension).
		viper.AddConfigPath(configDir)
		viper.SetConfigName(".ttg")
	}

	viper.AutomaticEnv() // read in environment variables that match

	// If a config file is found, read it in.
	if err := viper.ReadInConfig(); err == nil {
		blogRootDir = viper.GetString("root")
	}
}
