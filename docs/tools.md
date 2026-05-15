# Tools

Zish includes first-class integration for modern command-line tools that improve speed, readability, and day-to-day shell ergonomics.

## Managed Tools

| Tool | Command | Purpose |
| --- | --- | --- |
| eza | `eza` | Readable `ls` replacement with icons, Git status, trees, and directory grouping. |
| bat | `bat` or `batcat` | `cat` replacement with syntax highlighting, paging, and Git-aware decorations. |
| ripgrep | `rg` | Fast recursive search that respects ignore files by default. |
| difftastic | `difft` | Syntax-aware structural diffs, especially useful with Git. |

## Setup Behavior

`install.sh` checks for these tools during setup. When package installation is allowed, it installs missing tools through the detected package manager when the package name is known.

Current package-manager mapping:

| Manager | Packages |
| --- | --- |
| Homebrew | `eza`, `bat`, `ripgrep`, `difftastic` |
| apt | `eza`, `bat`, `ripgrep` |
| dnf | `eza`, `bat`, `ripgrep`, `difftastic` |
| pacman | `eza`, `bat`, `ripgrep`, `difftastic` |
| zypper | `eza`, `bat`, `ripgrep`, `difftastic` |
| apk | `eza`, `bat`, `ripgrep` |

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
```

## Sources

- eza installation: https://github.com/eza-community/eza/blob/main/INSTALL.md
- bat installation and `batcat` note: https://github.com/sharkdp/bat
- ripgrep installation: https://ripgrep.dev/docs/getting-started/
- difftastic installation: https://difftastic.wilfred.me.uk/installation
