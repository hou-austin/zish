# Starship

Zish uses Starship as the initial prompt engine. Starship gives the project a cross-platform prompt surface while keeping most shell-specific logic out of Zsh startup files.

## Current Integration

Runtime files:

- `config/init.zsh`: interactive Zsh entrypoint.
- `config/starship.zsh`: Starship detection, `STARSHIP_CONFIG` selection, and `starship init zsh`.
- `themes/blue-owl-starship/starship.toml`: active Starship theme.
- `themes/blue-owl-starship/theme.toml`: theme metadata.

`config/starship.zsh` sets `STARSHIP_CONFIG` only when the user has not already set it. This lets local overrides or external tooling choose a different Starship configuration without editing managed files.

If Starship was already initialized earlier in `.zshrc`, Zish still sets `STARSHIP_CONFIG` but skips a second `starship init zsh` call. This avoids duplicate Starship hooks while allowing the managed theme to affect future prompt renders.

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
- The left-side root/sudo marker is not enabled by default because the Starship sudo module adds measurable prompt latency when it renders nothing.

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
