# Themes

Themes define the prompt and any supporting visual shell state. They should be easy to preview, enable, disable, and debug.

## Theme Layout

Planned layout:

```text
themes/
`-- <theme-name>/
    |-- starship.toml
    |-- theme.toml
    `-- README.md
```

For Starship-backed themes, `starship.toml` is the runtime file. Metadata and documentation support installer UI and previews.

Current theme:

- `themes/blue-owl-starship`: Starship port of the Oh My Posh `blue-owl` theme.

## Theme Metadata

`theme.toml` should describe:

- Name.
- Description.
- Author or source.
- Prompt engine such as Starship.
- Required fonts or glyph support.
- Required commands.
- Optional commands.
- Whether the theme supports async status.
- Preview image or text preview path, if available.

## Prompt Requirements

Themes should:

- Avoid network calls.
- Avoid slow commands on every prompt render.
- Prefer Starship built-in modules before custom prompt commands.
- Handle missing optional commands gracefully.
- Avoid changing unrelated shell options permanently.
- Namespace functions and variables.
- Provide a clear unload or reset path where practical.

## Selection

The selected theme should be recorded in install state or config state. Changing themes should update only the theme selection, not rewrite unrelated startup files.

## Fallback

If a selected theme cannot load, Zish should fall back to a simple prompt and show a concise warning. A broken theme should not prevent opening a shell.

## Previews

Theme previews should use deterministic sample context when possible:

- User and host.
- Current directory.
- Git branch.
- Exit status.
- Background job count.

Preview generation should not depend on the user's current repository state unless explicitly requested.
