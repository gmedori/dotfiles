use clap::Parser;
use std::{process, io};

/// A command line utility for splitting chapters in a long MKV file into individual videos.
#[derive(Debug, Parser)]
#[command(name = "chapter-splitter", author, about, long_about = None)]
pub struct Cli {
    /// The input MKV file to split
    #[arg(short, long = "input")]
    input_file: String,

    /// The format of the output files. Use %n to indicate where to place the number.
    #[arg(short, long = "output")]
    output_file_format: String,

    /// The chapter number to begin splitting on, 1-indexed. Any chapters before chapter this are ignored.
    #[arg(short, long)]
    first_chapter: usize,

    /// The number of chapters to include in each video
    #[arg(short = 's', long = "step")]
    chapter_step: usize,

    /// The number of videos to make
    #[arg(short, long)]
    number_of_episodes: usize,

    /// The episode number to start with when labeling the output files
    #[arg(short = 'e', long)]
    starting_episode_number: usize,
}

impl Cli {
    pub fn run(&self) {
        Self::abort_if_file_does_not_exist(&self.input_file);
        
        let mut chapter_splits = Vec::new();
        let mut i = self.first_chapter;
        while chapter_splits.len() < self.number_of_episodes {
            chapter_splits.push(i.to_string());
            i += self.chapter_step;
        }

        let chapters = chapter_splits.join(",");

        let mkvmerge_output_format = "output-%03d.mkv";
        let mut binding = process::Command::new("mkvmerge");
        let mkvmerge = binding
            .arg("-o")
            .arg(mkvmerge_output_format)
            .arg("--split")
            .arg(format!("chapters:{}", chapters))
            .arg(&self.input_file)
            ;

        match mkvmerge.status() {
            Ok(_) => {
                println!("✅ Successfully ran mkvmerge. Renaming...");

            }
            Err(e) => {
                if let io::ErrorKind::NotFound = e.kind() {
                    println!("❌ mkvmerge was not found in the PATH");
                } else {
                    println!("❌ An unknown error occurred trying to execute mkvmerge.")
                }
                process::exit(1);
            }
        }

        let mut rename_failure_occurred = false;
        for i in 1..=self.number_of_episodes {
            let episode_number = self.starting_episode_number + i - 1;
            let formatted_number = match self.number_of_episodes {
                1..=100 => format!("{:02}", episode_number),
                _ => format!("{:04}", episode_number),
            };
            let intermediate_title = format!("output-{:03}.mkv", i);
            let episode_title = self.output_file_format.replace("%n", &formatted_number);
            match std::fs::rename(intermediate_title.clone(), episode_title.clone()) {
                Ok(_) => { /* do nothing */ },
                Err(e) => {
                    rename_failure_occurred = true;
                    println!("❌ Failed to rename {} to {}. {}.", intermediate_title, episode_title, e);
                },
            }
        }

        if !rename_failure_occurred {
            println!("✅ Successfully renamed all files.")
        }

    }

    fn abort_if_file_does_not_exist(file_name: &str) {
        if !std::path::Path::new(&file_name).exists() {
            println!("Could not find file: {}", file_name);
            process::exit(1);
        }
    }
}
