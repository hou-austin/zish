# Installation

This document defines the installer interface. The current implementation is `install.sh`; future commands may expand the interface without changing the core concepts.

## Entry Points

Current commands:

```sh
./bootstrap.sh
./install.sh
./install.sh --dry-run
./install.sh --yes
./install.sh --no-package-install
```

Future commands:

```sh
./bin/zish doctor
./bin/zish update
./bin/zish rollback
```

The implementation should keep the same concepts: plan, apply, verify, update, and restore.

`install.sh` stages managed Zish files into a stable install directory, then writes the shell hook to source that installed copy. Running `install.sh` from a development checkout must not make `~/.zshrc` source the development checkout directly.

Default install path:

```text
$XDG_DATA_HOME/zish/current
```

When `XDG_DATA_HOME` is unset, this resolves to:

```text
$HOME/.local/share/zish/current
```

Override it with:

```sh
ZISH_INSTALL_DIR=/path/to/zish ./install.sh
```

## Curl Bootstrap

Once the repository is hosted, the intended one-line setup is:

```sh
curl -fsSL https://raw.githubusercontent.com/hou-austin/zish/main/bootstrap.sh | sh
```

Non-interactive setup can pass installer flags after `sh -s --`:

```sh
curl -fsSL https://raw.githubusercontent.com/hou-austin/zish/main/bootstrap.sh | sh -s -- --yes
```

The bootstrap script:

1. Requires `git`.
2. Clones or updates the repo.
3. Runs `install.sh` from the checkout.

Interactive confirmation reads from `/dev/tty`, so the prompt still works when bootstrap is run through `curl | sh`.

Environment overrides:

| Variable | Purpose |
| --- | --- |
| `ZISH_REPO_URL` | Git URL to clone. |
| `ZISH_BRANCH` | Branch to checkout. |
| `ZISH_DIR` | Local checkout path. |
| `ZISH_INSTALL_DIR` | Runtime install path sourced by the managed shell hook. |

Default checkout path:

```text
$HOME/.local/share/zish/repo
```

Default runtime install path:

```text
$HOME/.local/share/zish/current
```

## Setup Modes

| Mode | Behavior |
| --- | --- |
| Interactive | Detect system state, show a plan, ask before applying changes. |
| Dry-run | Show the exact plan without changing files. |
| Non-interactive | Apply without prompts only when explicit approval is provided with a flag such as `--yes`. |
| No package install | Configure files but skip package manager changes. |
| Repair | Rebuild managed links and source blocks without replacing user-owned content. |

## Required Installer Properties

- Idempotent: a second run should not duplicate managed blocks or reinstall unchanged assets unnecessarily.
- Conservative: existing files must be backed up before modification.
- Inspectable: the plan should show each path, action, and reason.
- Recoverable: backup manifests should make rollback possible.
- Platform-aware: Linux, macOS, and WSL should use explicit platform branches where behavior differs.

## Planned Interactive Flow

1. Print detected platform, shell path, package manager, and repo path.
2. Check required commands such as `zsh` and `git`.
3. Check Starship availability when the selected prompt theme requires it.
4. Check modern CLI tool availability: `eza`, `bat`, `ripgrep`, `difftastic`, `fzf`, `zoxide`, and `atuin`.
5. Check JetBrainsMono Nerd Font availability and terminal profile configuration support.
6. Inventory existing shell paths.
7. Show proposed changes, including backups and managed source blocks.
8. Ask for confirmation.
9. Apply changes.
10. Run verification.
11. Print next steps.

## Planned Flags

| Flag | Purpose |
| --- | --- |
| `--dry-run` | Build and print the plan without writing files. |
| `--yes` | Approve the generated plan in non-interactive environments. |
| `--no-package-install` | Do not install packages through Homebrew, apt, dnf, pacman, zypper, or other managers. |
| `--backup-dir <path>` | Override the default backup location. |
| `--theme <name>` | Select a theme during setup. |
| `--plugin <name>` | Enable a plugin during setup. |
| `--minimal` | Install core configuration only. |
| `--verbose` | Show detailed decisions and command output. |

Flags should be additive and predictable. Avoid flags that silently change migration safety rules.

## Dependency Installation

Dependency installation should be optional and visible in the plan. The installer may suggest package-manager commands, but it should not run them unless the mode allows package installation.

Common dependencies:

- `zsh`
- `starship`
- `JetBrainsMono Nerd Font`
- `eza`
- `bat`
- `ripgrep`
- `difftastic`
- `fzf`
- `zoxide`
- `atuin`
- `zsh-autosuggestions`
- `zsh-syntax-highlighting`
- `git`
- `curl` or another fetch tool if remote plugin installation is supported
- Other optional plugin dependencies when selected

## Success Criteria

An install is successful when:

- Existing affected paths have backups or are confirmed to be already managed.
- Managed startup hooks are present exactly once.
- Selected theme and plugins are installed or intentionally skipped.
- Zsh starts and sources the managed entrypoint without errors.
- Starship can parse the selected theme when a Starship theme is enabled.
- Managed tool configuration loads without errors.
- Install state and backup manifest are written.

## Uninstall and Rollback

Rollback should use the manifest from a specific install run. It should restore changed files where safe, remove managed blocks, and report anything that changed after the backup was created.

Uninstall should remove Zish-managed hooks and state without deleting user-local files unless explicitly requested.
