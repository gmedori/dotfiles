use clap::CommandFactory;
use clap_complete::{generate_to, shells::Fish};
use std::env;
use std::io::Error;

include!("src/lib.rs");

fn main() -> Result<(), Error> {
    let outdir = match env::var_os("CARGO_MANIFEST_DIR") {
        None => return Ok(()),
        Some(outdir) => outdir,
    };

    let mut cmd = Cli::command();
    let path = generate_to(
        Fish,
        &mut cmd, // We need to specify what generator to use
        "iosd",   // We need to specify the bin name manually
        outdir,   // We need to specify where to write to
    )?;

    println!("cargo:warning=completion file is generated: {path:?}");

    Ok(())
}
