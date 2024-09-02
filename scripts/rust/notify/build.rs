/// NOTE: Copy this file into the project root of any command line tool that uses clap to
/// automatically generate the fish completion file for it. The project root is the same directory
/// that the Cargo.toml file resides in.
use clap::CommandFactory;
use clap_complete::{generate_to, shells::Fish};
use std::env;
use std::io::Error;
use std::path::Path;

include!("src/lib.rs");

fn main() -> Result<(), Error> {
    let outdir = env::var_os("CARGO_MANIFEST_DIR")
        .expect("Unable to find CARGO_MANIFEST_DIR environment variable");

    let manifest_path = Path::new(&outdir);
    let binary_name = manifest_path
        .components()
        .last()
        .map(|c| c.as_os_str())
        .and_then(|c| c.to_str())
        .unwrap_or_else(|| panic!("Could not deterimine binary name from path: {:?}", outdir));

    let mut cmd = Cli::command();
    let path = generate_to(
        Fish,
        &mut cmd,       // We need to specify what generator to use
        binary_name,    // We need to specify the bin name manually
        outdir.clone(), // We need to specify where to write to
    )?;

    println!("cargo:warning=completion file is generated: {path:?}");

    Ok(())
}
