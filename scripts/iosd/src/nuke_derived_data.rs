use clap::Args;
use std::process::{exit, Command};
use text_io::read;

/// Arguments for command `nuke-derived-data`
#[derive(Debug, Args)]
pub struct Arguments;

impl super::Runnable for Arguments {
    fn run(&self) {
        let derived_data_directory = self.get_derived_data_directory();
        println!(
            "Are you sure you want to delete the DerivedData directory?
{}

Anything except 'yes' will abort.",
            derived_data_directory,
        );
        let input: String = read!("{}\n");
        if input == "yes" {
            println!("Nuking...");
            match std::fs::remove_dir_all(derived_data_directory.clone()) {
                Ok(_) => {
                    println!("Successfully nuked {}", derived_data_directory);
                }
                Err(error) => panic!("Couldn't remove directory: {}", error),
            }
        } else {
            println!("Aborting...");
            exit(1);
        }
    }
}

impl Arguments {
    /// Retrieves the derived data directory, prioritizing a custom directory that has been set
    /// using user defaults. This function runs the command `defaults read com.apple.dt.Xcode
    /// IDECustomDerivedDataLocation`
    fn get_derived_data_directory(&self) -> String {
        let mut command = Command::new("defaults");
        let command = command.args(["read", "com.apple.dt.Xcode", "IDECustomDerivedDataLocation"]);

        let custom_location = command.output();
        let default_location = shellexpand::env("$HOME/Library/Developer/Xcode/DerivedData")
            .unwrap()
            .to_string();

        match custom_location {
            Ok(location) => {
                let custom_location = String::from_utf8(location.stdout)
                    .expect("Failed to parse output of command as utf8 string.");
                if custom_location.trim().is_empty() {
                    default_location
                } else {
                    custom_location
                }
            }
            Err(_) => default_location,
        }
    }
}
