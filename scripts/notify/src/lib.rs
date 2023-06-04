use clap::{Parser, ValueEnum};
use std::process::Command;

#[derive(Debug, Parser)]
#[command(name = "notify", author, version, about, long_about = None)]
pub struct Cli {
    /// The message to display.
    #[arg()]
    message: Vec<String>,

    /// The title of the message.
    #[arg(short, long, default_value = "Notify")]
    title: String,

    /// An optional subtitle to include with the notification.
    #[arg(long)]
    subtitle: Option<String>,

    /// The sound to play when the notification is displayed.
    #[arg(short, long, default_value = "purr")]
    sound: Sound,
}

impl Cli {
    pub fn run(&self) {
        let message = self.message.join(" ");
        let mut command = format!("display notification \"{}\"", message);
        command += &format!(" with title \"{}\"", self.title);
        if let Some(subtitle) = &self.subtitle {
            command += &format!(" subtitle \"{}\"", subtitle);
        }
        command += &format!(" sound name \"{}\"", self.sound.as_str());

        println!("{}", command);

        let mut binding = Command::new("/usr/bin/osascript");
        let applescript = binding
            .arg("-e")
            .arg(&command);

        let _ = applescript.spawn();
    }
}

#[derive(Debug, Clone, ValueEnum)]
enum Sound {
    Basso,
    Blow,
    Bottle,
    Frog,
    Funk,
    Glass,
    Hero,
    Morse,
    Ping,
    Pop,
    Purr,
    Sosumi,
    Submarine,
    Tink,
}

impl Sound {
    fn as_str(&self) -> &'static str {
        match self {
            Sound::Basso => "basso",
            Sound::Blow => "blow",
            Sound::Bottle => "bottle",
            Sound::Frog => "frog",
            Sound::Funk => "funk",
            Sound::Glass => "glass",
            Sound::Hero => "hero",
            Sound::Morse => "morse",
            Sound::Ping => "ping",
            Sound::Pop => "pop",
            Sound::Purr => "purr",
            Sound::Sosumi => "sosumi",
            Sound::Submarine => "submarine",
            Sound::Tink => "tink",
        }
    }
}
