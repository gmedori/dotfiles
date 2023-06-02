use clap::Parser;
use iosd;

fn main() {
    let cli = iosd::Cli::parse();
    match cli.command {
        iosd::Commands::NukeDerivedData(arguments) => { arguments.run() }
    }
}
