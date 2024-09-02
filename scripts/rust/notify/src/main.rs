use clap::Parser;
use notify::Cli;

fn main() {
    let cli = Cli::parse();
    cli.run();
}
