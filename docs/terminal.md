# Terminal

Terminal setup covers host UI settings that influence how the shell looks but are not fully controlled by Zsh.

## Font

The Blue Owl Starship theme targets `JetBrainsMono Nerd Font Mono` for Nerd Font prompt rendering. The installer attempts to install the JetBrainsMono Nerd Font automatically where that is safe:

- macOS with Homebrew: `brew install --cask font-jetbrains-mono-nerd-font`
- Linux desktop shells: download JetBrainsMono from Nerd Fonts into the user font directory when `curl` and `unzip` are available.
- WSL: report a host setup note, because Windows Terminal must use a font installed on Windows.

Installing the font is not enough by itself. The active terminal profile must use `JetBrainsMono Nerd Font Mono` or another JetBrainsMono Nerd Font family. This is a terminal emulator setting, not a shell startup setting.

The installer auto-configures the font only for macOS Terminal when setup is run from that app. Other terminal apps have separate preference stores and should be configured by their native settings UI:

- Apple Terminal: configured automatically when `TERM_PROGRAM=Apple_Terminal`.
- iTerm2, Ghostty, WezTerm, Alacritty, Kitty, VS Code, and other macOS/Linux terminals: set the profile font to `JetBrainsMono Nerd Font Mono`.
- Windows Terminal for WSL: set `profiles.defaults.font.face` to `JetBrainsMono Nerd Font Mono` on the Windows host.

Set `ZISH_CONFIGURE_TERMINAL_FONT=0` to skip automatic Apple Terminal font configuration.

## Appearance

The Blue Owl Starship powerline uses terminal-background cutouts. Zish detects system light/dark appearance on macOS and GNOME desktops, selects the matching Starship config for the managed theme, and sets a matching cutout RGB value.

If the terminal profile does not follow the system appearance, set `ZISH_SYSTEM_APPEARANCE=light` or `ZISH_SYSTEM_APPEARANCE=dark` in `config/local.zsh`. If the profile uses a custom background color, set `ZISH_TERMINAL_BACKGROUND_RGB` to the exact `R;G;B` value, or override `ZISH_TERMINAL_LIGHT_BACKGROUND_RGB` and `ZISH_TERMINAL_DARK_BACKGROUND_RGB`.

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
