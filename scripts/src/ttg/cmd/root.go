package cmd

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/mitchellh/go-homedir"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

// config defines the configuration file $HOME/.config/ttg.yaml
type ttgConfig struct {
	RootDir string `mapstructure:"root"`
}

var (
	config ttgConfig

	cfgFile string
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
}

func init() {
	cobra.OnInitialize(initConfig)

	TechTechGooseCmd.PersistentFlags().StringVar(&cfgFile, "config", "", "config file (default is $HOME/.config/.ttg.yaml)")
	TechTechGooseCmd.PersistentFlags().StringVarP(&config.RootDir, "root", "r", "", "The blog's root directory.")
	viper.BindPFlag("root", TechTechGooseCmd.PersistentFlags().Lookup("root"))
}

// initConfig reads in config file and ENV variables if set.
func initConfig() {
	home, err := homedir.Dir()
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	if cfgFile != "" {
		// Use config file from the flag.
		viper.SetConfigFile(cfgFile)
	} else {
		// Find home directory.

		configDir := filepath.Join(home, ".config")

		// Search config in config directory with name ".ttg" (without extension).
		viper.AddConfigPath(configDir)
		viper.SetConfigName("ttg")
	}

	// If a config file is found, read it in.
	err = viper.ReadInConfig()

	if err != nil {
		fmt.Printf("Unable to read config file at %v: %v\n", viper.ConfigFileUsed(), err)
		os.Exit(1)
	}

	err = viper.Unmarshal(&config)
	if err != nil {
		fmt.Printf("Unable to decode config file: %v\n", err)
	}

	// Process config values
	if config.RootDir == "~" {
		// In case of "~", which won't be caught by the "else if"
		config.RootDir = home
	} else if strings.HasPrefix(config.RootDir, "~/") {
		// Use strings.HasPrefix so we don't match paths like
		// "/something/~/something/"
		config.RootDir = filepath.Join(home, config.RootDir[2:])
	}
}
