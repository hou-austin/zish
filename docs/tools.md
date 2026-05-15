# Tools

Zish includes first-class integration for modern command-line tools that improve speed, readability, and day-to-day shell ergonomics.

## Managed Tools

| Tool | Command | Purpose |
| --- | --- | --- |
| eza | `eza` | Readable `ls` replacement with icons, Git status, trees, and directory grouping. |
| bat | `bat` or `batcat` | `cat` replacement with syntax highlighting, paging, and Git-aware decorations. |
| ripgrep | `rg` | Fast recursive search that respects ignore files by default. |
| difftastic | `difft` | Syntax-aware structural diffs, especially useful with Git. |
| fzf | `fzf` | Fuzzy finder shell integration, including completion and key bindings when available. |
| zoxide | `zoxide` | Smart directory jumper initialized as the default `cd` replacement. |
| atuin | `atuin` | Shell history search and optional sync integration. |

## Setup Behavior

`install.sh` checks for these tools during setup. When package installation is allowed, it installs missing tools through the detected package manager when the package name is known.

If an existing `.zshrc` already initializes `fzf`, `zoxide`, or `atuin`, the installer reports that in the setup plan and writes the matching Zish opt-out variable into the managed block. This preserves the user's existing integration and avoids loading the same tool integration twice.

Current package-manager mapping:

| Manager | Packages |
| --- | --- |
| Homebrew | `eza`, `bat`, `ripgrep`, `difftastic`, `fzf`, `zoxide`, `atuin` |
| apt | `eza`, `bat`, `ripgrep`, `fzf`, `zoxide`, `atuin` |
| dnf | `eza`, `bat`, `ripgrep`, `difftastic`, `fzf`, `zoxide`, `atuin` |
| pacman | `eza`, `bat`, `ripgrep`, `difftastic`, `fzf`, `zoxide`, `atuin` |
| zypper | `eza`, `bat`, `ripgrep`, `difftastic`, `fzf`, `zoxide` |
| apk | `eza`, `bat`, `ripgrep`, `fzf`, `zoxide`, `atuin` |

Unsupported tools are reported in the setup plan instead of hidden.

## Shell Configuration

`config/tools.zsh` loads only for interactive Zsh sessions.

If a user's existing `.zshrc` already defines aliases for `ls`, `ll`, `la`, `lt`, or `cat`, the setup plan reports that. Because the managed Zish block is appended to `.zshrc`, Zish aliases load later and may override earlier aliases unless the user opts out.

When `eza` exists:

```sh
ls -> eza --group-directories-first --icons=auto
ll -> eza --long --group --git --group-directories-first --icons=auto
la -> eza --long --all --group --git --group-directories-first --icons=auto
lt -> eza --tree --level=2 --group-directories-first --icons=auto
```

When `bat` or Debian-style `batcat` exists:

```sh
cat -> bat --paging=never --style=plain
bathelp -> bat --plain --language=help
```

When `ripgrep` exists, Zish sets `RIPGREP_CONFIG_PATH` to `config/ripgreprc` unless the user already set it.

When `difftastic` exists, Zish sets `GIT_EXTERNAL_DIFF=difft` unless the user already set it. This makes `git diff` use difftastic in managed interactive shells without writing global Git config.

When `fzf` exists, Zish loads its Zsh integration for interactive terminal sessions. Newer `fzf` builds use `fzf --zsh`; older package layouts fall back to packaged completion and key-binding files when present.

When `zoxide` exists, Zish initializes it with `--cmd cd`, making smart directory jumping the default `cd` behavior in managed interactive shells. Set `ZISH_ZOXIDE_CMD` before `config/tools.zsh` loads to use a different command name.

When `atuin` exists, Zish loads `atuin init zsh` so Atuin can provide its history search and shell integration.

## Config Files

- `config/bat.conf`: default `bat` style, theme, paging, and wrapping.
- `config/ripgreprc`: default `ripgrep` smart-case, hidden-file search, and `.git` exclusion.

## Opt-Outs

Users can set these in `config/local.zsh` before `config/tools.zsh` loads:

```sh
export ZISH_DISABLE_EZA_ALIASES=1
export ZISH_DISABLE_BAT_ALIASES=1
export ZISH_DISABLE_BAT_CONFIG=1
export ZISH_DISABLE_RIPGREP_CONFIG=1
export ZISH_DISABLE_DIFFTASTIC_GIT=1
export ZISH_DISABLE_FZF_INTEGRATION=1
export ZISH_DISABLE_ZOXIDE_INTEGRATION=1
export ZISH_DISABLE_ATUIN_INTEGRATION=1
```

## Sources

- eza installation: https://github.com/eza-community/eza/blob/main/INSTALL.md
- bat installation and `batcat` note: https://github.com/sharkdp/bat
- ripgrep installation: https://ripgrep.dev/docs/getting-started/
- difftastic installation: https://difftastic.wilfred.me.uk/installation
- fzf installation: https://junegunn.github.io/fzf/installation/
- zoxide installation: https://zoxide.org/download/
- Atuin installation: https://docs.atuin.sh/cli/guide/installation/
