use clap::Parser;
use chapter_splitter::Cli;

fn main() {
    let cli = Cli::parse();
    cli.run();
}
