# Terminal

Terminal setup covers host UI settings that influence how the shell looks but are not fully controlled by Zsh.

## Font

The Blue Owl Starship theme targets `MesloLGM Nerd Font Mono`, matching the Oh My Posh recommendation for Nerd Font prompt rendering. The installer attempts to install the Meslo LGM Nerd Font automatically where that is safe:

- macOS with Homebrew: `brew install --cask font-meslo-lg-nerd-font`
- Linux desktop shells: download Meslo from Nerd Fonts into the user font directory when `curl` and `unzip` are available.
- WSL: report a host setup note, because Windows Terminal must use a font installed on Windows.

Installing the font is not enough by itself. The active terminal profile must use `MesloLGM Nerd Font Mono` or another Meslo LGM Nerd Font family. This is a terminal emulator setting, not a shell startup setting.

The installer auto-configures the font only for macOS Terminal when setup is run from that app. Other terminal apps have separate preference stores and should be configured by their native settings UI:

- Apple Terminal: configured automatically when `TERM_PROGRAM=Apple_Terminal`.
- iTerm2, Ghostty, WezTerm, Alacritty, Kitty, VS Code, and other macOS/Linux terminals: set the profile font to `MesloLGM Nerd Font Mono`.
- Windows Terminal for WSL: set `profiles.defaults.font.face` to `MesloLGM Nerd Font Mono` on the Windows host.

Set `ZISH_CONFIGURE_TERMINAL_FONT=0` to skip automatic Apple Terminal font configuration.

## Cursor

Zish defaults the interactive cursor to a steady underline so the second prompt line resembles the Blue Owl reference. This uses the common DECSCUSR escape sequence and is ignored by terminals that do not support it.

Local overrides:

```zsh
export ZISH_CURSOR_STYLE=underline
export ZISH_CURSOR_STYLE=beam
export ZISH_CURSOR_STYLE=block
export ZISH_CURSOR_STYLE=none
```

Supported values are `underline`, `beam`, `block`, `blinking_underline`, `blinking_beam`, `blinking_block`, and `none`.
