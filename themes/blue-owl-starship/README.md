# Blue Owl Starship

This theme is a Starship port of the Oh My Posh `blue-owl` theme. It keeps the high-contrast blue, green, yellow, purple, and navy palette and the angular powerline-inspired prompt shape, while using Starship modules and configuration.

## Intentional Differences

- The first prompt line uses Starship's fill module to align user, hostname, and time to the right.
- The aligned right section does not include the decorative leading marker from the original Oh My Posh theme.
- The aligned right section does not include an outline separator between the user/hostname section and the time section.
- The user/hostname and time sections are separated by background and foreground color differences.
- The path segment uses a tiny local renderer so the prompt can keep Blue Owl's `home / ... / leaf` spacing inside the blue block.
- Git status is represented with Starship's built-in Git modules instead of Oh My Posh templates.
- The original left-side root marker is not enabled by default because Starship's sudo module adds measurable prompt latency even when it renders nothing.

## Requirements

- Zsh.
- Starship.
- `MesloLGM Nerd Font Mono` configured in the terminal for prompt symbols and spacing.

## Usage

Zish sets `STARSHIP_CONFIG` to this theme from `config/starship.zsh` when `STARSHIP_CONFIG` is not already set.

Manual test:

```sh
STARSHIP_CONFIG="$PWD/themes/blue-owl-starship/starship.toml" starship prompt
```
