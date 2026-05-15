# Configuration

Zish configuration should be layered, readable, and safe to source repeatedly. Shell startup performance matters because this code runs every time an interactive shell starts.

## Zsh Startup Files

Zsh reads different files depending on invocation mode:

| File | Purpose |
| --- | --- |
| `~/.zshenv` | Every Zsh invocation. Keep minimal. |
| `~/.zprofile` | Login shells before `~/.zshrc`. |
| `~/.zshrc` | Interactive shells. Primary managed hook. |
| `~/.zlogin` | Login shells after `~/.zshrc`. |
| `~/.zlogout` | Login shell exit. |

Zish should primarily hook through `~/.zshrc` and avoid heavy work in `~/.zshenv`.

The current repository entrypoint is `config/init.zsh`. The future installer should create or update a managed block in `~/.zshrc` that sources the installed copy of that file.

## Managed Entrypoint

The managed entrypoint should live in the selected config directory, likely:

```text
${XDG_CONFIG_HOME:-$HOME/.config}/zish/init.zsh
```

The installer may create a managed block in `~/.zshrc` that sources this file. The entrypoint should load modules in a predictable order:

1. Environment defaults safe for interactive shells.
2. Completion setup.
3. Aliases and functions.
4. Plugins.
5. User-local prompt and tool preferences.
6. Modern CLI tool integration.
7. Prompt integration and theme.
8. User-local interactive overrides.

The current implementation loads `config/local.zsh` before `config/tools.zsh` and `config/starship.zsh` so users can set prompt and tool preferences locally. It then loads files in `config/local.d/*.zsh` after Starship for normal interactive overrides.

Current managed module order:

1. `config/local.zsh`
2. `config/tools.zsh`
3. `config/terminal.zsh`
4. `config/starship.zsh`
5. `config/local.d/*.zsh`
6. `config/plugins.zsh`

`config/plugins.zsh` is last so `zsh-syntax-highlighting` can be sourced at the end of the managed startup path.

## Local Overrides

Machine-specific or private settings should live outside tracked files. Recommended names:

```text
~/.config/zish/local.zsh
~/.config/zish/local.d/*.zsh
```

Use `local.zsh` for prompt selection and machine-local environment settings that must exist before prompt initialization. Use `local.d/*.zsh` for aliases, functions, and other interactive overrides that can load after managed defaults.

The tracked example is `config/local.example.zsh`. Real local override files are ignored by Git.

## Secrets

Do not commit secrets. Configuration should provide examples for environment variables, but the actual values should live in local overrides, a credential manager, or another private mechanism.

## Interactive Guard

Interactive-only behavior should be guarded:

```sh
case $- in
  *i*) ;;
  *) return ;;
esac
```

The exact guard may differ inside Zsh-specific files, but non-interactive shells should avoid prompt, completion, and plugin work.

## Performance Rules

- Avoid network calls during shell startup.
- Avoid package-manager calls during shell startup.
- Cache expensive detection where practical.
- Load optional plugins only when enabled.
- Keep completion initialization predictable and measurable.
- Keep Starship modules focused on built-in modules unless a custom command is clearly worth the prompt latency.

## Compatibility

Zish-managed `.zsh` files may use Zsh features. Installer scripts should be explicit about whether they require POSIX shell, Bash, or Zsh.
