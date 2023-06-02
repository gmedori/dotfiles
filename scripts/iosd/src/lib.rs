use clap::{Parser, Subcommand};

mod nuke_derived_data;

#[derive(Debug, Parser)]
#[command(name = "iosd", author, version, about, long_about = None)]
pub struct Cli {
    #[command(subcommand)]
    pub command: Commands,
}

#[derive(Debug, Subcommand)]
pub enum Commands {
    /// Forcefully deletes the derived data directory where Xcode stores many intermediate
    /// products.
    NukeDerivedData(nuke_derived_data::Arguments),
}

