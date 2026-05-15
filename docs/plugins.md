# Plugins

Plugins add shell behavior such as completions, aliases, functions, key bindings, and integrations. The plugin system should be explicit about sources, load order, and update behavior.

The current implementation loads package-managed Zsh plugins from `config/plugins.zsh`. It does not clone remote plugin repositories during shell startup.

## Managed Plugins

| Plugin | Purpose | Default |
| --- | --- | --- |
| `zsh-autosuggestions` | Inline fish-style suggestions from history and completions. | Enabled when installed. |
| `zsh-syntax-highlighting` | Real-time command-line highlighting. | Enabled when installed and loaded last. |

`install.sh` checks for both plugin packages and installs them through the detected package manager when package installation is allowed and the package name is known.

Current package-manager mapping:

| Manager | Packages |
| --- | --- |
| Homebrew | `zsh-autosuggestions`, `zsh-syntax-highlighting` |
| apt | `zsh-autosuggestions`, `zsh-syntax-highlighting` |
| dnf | `zsh-autosuggestions`, `zsh-syntax-highlighting` |
| pacman | `zsh-autosuggestions`, `zsh-syntax-highlighting` |
| zypper | `zsh-autosuggestions`, `zsh-syntax-highlighting` |
| apk | `zsh-autosuggestions`, `zsh-syntax-highlighting` |

Users can opt out before plugins load:

```sh
export ZISH_DISABLE_ZSH_AUTOSUGGESTIONS=1
export ZISH_DISABLE_ZSH_SYNTAX_HIGHLIGHTING=1
```

## Plugin Manifest

Planned manifest:

```text
plugins/plugins.toml
```

Each plugin entry should describe:

- Name.
- Source type: local, git, package, or builtin.
- Source URL or package name when relevant.
- Revision, tag, or version pin when available.
- Load file or directory.
- Dependencies.
- Whether it is enabled by default.
- Platform constraints.

## Source Types

| Type | Behavior |
| --- | --- |
| local | Load from this repository. |
| git | Clone or update a remote plugin into the data directory. |
| package | Require a package-manager dependency. |
| builtin | Use a Zsh feature or module without external files. |

## Load Order

Plugin load order should be deterministic:

1. Core Zsh options and completion setup.
2. Dependency plugins.
3. User-selected plugins in manifest order.
4. Theme.
5. Local overrides.

Plugins should not silently reorder themselves at runtime.

Current managed load order is:

1. `config/tools.zsh`
2. `config/terminal.zsh`
3. `config/starship.zsh`
4. `config/local.d/*.zsh`
5. `zsh-autosuggestions`
6. `zsh-syntax-highlighting`

`zsh-syntax-highlighting` is sourced as the final managed plugin because its upstream installation guidance requires it to be loaded at the end of `.zshrc`.

## Updates

Update behavior should be explicit. Remote plugins should support pinned revisions so a normal install remains reproducible. A future `zish update` command may refresh plugins, but it should show the proposed changes before applying them.

## Platform Constraints

Plugins may declare supported platforms. The installer should skip or warn for incompatible plugins instead of failing the whole setup unless the plugin is required.

## Failure Behavior

A plugin failure should not make the shell unusable. The loader should report the plugin name and error path, then continue when safe.

## Existing Plugin Managers

If the user already uses Oh My Zsh, zinit, antigen, zplug, or another plugin manager, the installer should not delete it automatically. It should identify likely overlap and offer a migration plan.

If an existing `.zshrc` already mentions `zsh-syntax-highlighting`, the current installer inserts the Zish managed block before that line so the user's existing syntax-highlighting setup can remain the last item in the file.

## Sources

- zsh-autosuggestions: https://github.com/zsh-users/zsh-autosuggestions
- zsh-syntax-highlighting: https://github.com/zsh-users/zsh-syntax-highlighting
