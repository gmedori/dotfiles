use clap::{Parser, Subcommand};

mod nuke_derived_data;

/// The root level command that `clap` will parse. Currently there are no global flags; it only
/// takes subcommands.
#[derive(Debug, Parser)]
#[command(name = "iosd", author, version, about, long_about = None)]
pub struct Cli {
    #[command(subcommand)]
    pub command: Commands,
}

/// A comprehensive list of the subcommands beneath iosd. Each operation is designed to make
/// something tedious a little easier to deal with.
#[derive(Debug, Subcommand)]
pub enum Commands {
    /// Forcefully deletes the derived data directory where Xcode stores many intermediate
    /// products.
    NukeDerivedData(nuke_derived_data::Arguments),
}

pub trait Runnable {
    fn run(&self);
}
