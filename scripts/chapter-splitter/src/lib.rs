use clap::Parser;
use std::process::Command;

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
    first_chapter: u32,

    /// The number of chapters to include in each video
    #[arg(short = 's', long = "step")]
    chapter_step: u32,

    /// The number of videos to make
    #[arg(short, long)]
    number_of_episodes: u32,

    /// The episode number to start with when labeling the output files
    #[arg(short = 'e', long)]
    starting_episode_number: u32,
}

impl Cli {
    pub fn run(&self) {
        match Command::new("hjklhjkl").spawn() {
            Ok(_) => println!("Tada! 🎉 It worked"),
            Err(e) => {
                if let std::io::ErrorKind::NotFound = e.kind() {
                    println!("mkvmerge was not found in the PATH");
                } else {
                    println!("An unknown error occurred trying to execute mkvmerge.")
                }
            }
        }
    }
}
