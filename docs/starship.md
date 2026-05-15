# Starship

Zish uses Starship as the initial prompt engine. Starship gives the project a cross-platform prompt surface while keeping most shell-specific logic out of Zsh startup files.

## Current Integration

Runtime files:

- `config/init.zsh`: interactive Zsh entrypoint.
- `config/terminal.zsh`: terminal appearance detection and prompt cutout background defaults.
- `config/starship.zsh`: Starship detection, appearance-aware `STARSHIP_CONFIG` selection, and `starship init zsh`.
- `themes/blue-owl-starship/starship.toml`: active Starship theme.
- `themes/blue-owl-starship/starship-light.toml`: light-appearance Starship variant.
- `themes/blue-owl-starship/theme.toml`: theme metadata.

`config/starship.zsh` sets `STARSHIP_CONFIG` only when the user has not already set it. This lets local overrides or external tooling choose a different Starship configuration without editing managed files.

For the managed `blue-owl-starship` theme, Zish selects the dark or light Starship config from the detected system appearance. It also refreshes that choice before prompts with a short cache window, so changing system appearance can update new prompt renders without running detection commands every prompt.

If Starship was already initialized earlier in `.zshrc`, Zish still sets `STARSHIP_CONFIG` but skips a second `starship init zsh` call when the current shell already has Starship prompt functions loaded. The check must not rely on inherited environment variables alone, because `exec zsh` preserves variables such as `STARSHIP_SHELL` while starting a fresh shell without prompt functions.

## Theme Selection

The default theme is:

```sh
ZISH_THEME=blue-owl-starship
```

The selected Starship config resolves to:

```text
$ZISH_ROOT/themes/$ZISH_THEME/starship.toml
```

Users may override the exact file with:

```sh
ZISH_STARSHIP_CONFIG=/path/to/starship.toml
```

For repo-local development, copy `config/local.example.zsh` to `config/local.zsh` and set either variable there. Real local override files are ignored by Git.

## Blue Owl Port

`blue-owl-starship` is based on the Oh My Posh `blue-owl` theme. The port keeps the angular powerline-style shape and high-contrast palette, but uses Starship modules.

Intentional differences:

- User, hostname, and time are aligned on the first prompt line with Starship's fill module instead of native `right_format`, because native Zsh right prompts attach to the cursor line in a two-line prompt.
- No decorative marker before the aligned right section.
- No powerline separator between the user/hostname section and the time section.
- Color differences separate the aligned right-side sections.
- The path segment uses `themes/blue-owl-starship/render-path.sh` because Starship's built-in directory module cannot render the Oh My Posh-style spaced folder separators inside one colored block.
- The leading path diamond is rendered as a negative-space cutout cell: terminal-background foreground on a blue background. Zish detects light and dark system appearance for the default cutout color. Set `ZISH_TERMINAL_BACKGROUND_RGB` when the terminal background differs from the detected default.
- The left-side root/sudo marker is not enabled by default because the Starship sudo module adds measurable prompt latency when it renders nothing.

## Appearance Overrides

Zish detects macOS light/dark appearance with `defaults` and GNOME color-scheme preferences with `gsettings`. Other platforms default to the dark variant to preserve the original theme behavior.

Override detection when your terminal profile does not follow the system appearance:

```sh
ZISH_SYSTEM_APPEARANCE=light
```

Override the exact cutout colors when your terminal background differs from the defaults:

```sh
ZISH_TERMINAL_LIGHT_BACKGROUND_RGB="250;250;250"
ZISH_TERMINAL_DARK_BACKGROUND_RGB="19;23;29"
```

Set `ZISH_TERMINAL_BACKGROUND_RGB` to force one exact background color and skip automatic cutout switching.

## Performance Rules

- Prefer built-in Starship modules over custom shell commands.
- Avoid custom modules that run Git, package managers, network calls, or broad filesystem scans every prompt.
- Keep `command_timeout` low enough to prevent prompt stalls.
- Use `starship timings` when adding or changing modules.

## Validation Commands

```sh
TERM=xterm-256color STARSHIP_CONFIG="$PWD/themes/blue-owl-starship/starship.toml" starship print-config
TERM=xterm-256color STARSHIP_CONFIG="$PWD/themes/blue-owl-starship/starship.toml" starship prompt --path "$PWD" --status 0 --cmd-duration 1
TERM=xterm-256color STARSHIP_CONFIG="$PWD/themes/blue-owl-starship/starship.toml" starship timings --path "$PWD" --cmd-duration 1
```
