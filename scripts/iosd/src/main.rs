use clap::Parser;
use iosd::{Commands::*, Runnable};

fn main() {
    let cli = iosd::Cli::parse();
    match cli.command {
        NukeDerivedData(arguments) => arguments.run(),
    }
}
