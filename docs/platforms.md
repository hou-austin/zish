# Platforms

Zish targets Linux, macOS, and Windows through WSL. Native Windows outside WSL is out of scope.

## Platform Detection

Detection should identify:

- Operating system family.
- Whether the environment is WSL.
- Distribution or macOS version when useful.
- Current shell and available Zsh path.
- Package manager.
- Home, config, cache, and state directories.

Do not infer WSL only from path shape. Prefer kernel or environment signals such as `/proc/version`, `/proc/sys/kernel/osrelease`, or WSL-specific environment variables, while keeping detection testable.

## Linux

Linux should follow XDG conventions where practical:

| Purpose | Default |
| --- | --- |
| Config | `${XDG_CONFIG_HOME:-$HOME/.config}/zish` |
| State | `${XDG_STATE_HOME:-$HOME/.local/state}/zish` |
| Cache | `${XDG_CACHE_HOME:-$HOME/.cache}/zish` |
| Data | `${XDG_DATA_HOME:-$HOME/.local/share}/zish` |

Potential package managers:

- `apt`
- `dnf`
- `yum`
- `pacman`
- `zypper`
- `apk`

The installer should detect package managers, not assume one from distro name alone.

The current setup helper knows package names for Homebrew, apt, dnf, pacman, zypper, and apk. Some tools are not available through every manager in the current mapping; for example, `difftastic` is intentionally not installed through apt or apk by the current setup script, and `atuin` is intentionally not installed through zypper.

## macOS

macOS should support Homebrew when package installation is allowed. Homebrew may be installed at different prefixes:

- Apple Silicon: `/opt/homebrew`
- Intel: `/usr/local`

Recommended defaults:

| Purpose | Default |
| --- | --- |
| Config | `$HOME/.config/zish` |
| State | `$HOME/Library/Application Support/zish` |
| Cache | `$HOME/Library/Caches/zish` |
| Data | `$HOME/Library/Application Support/zish/data` |

Using `$HOME/.config/zish` for config keeps shell startup paths consistent with Linux.

## WSL

WSL should be treated as Linux for shell behavior and package installation, with extra rules:

- Prefer Linux home paths under `/home/<user>`.
- Avoid managed files under `/mnt/c`, `/mnt/d`, or other Windows-mounted paths unless explicitly requested.
- Be careful with executable bits on Windows-mounted filesystems.
- Avoid assuming Windows tools are available.
- Detect the Linux distribution and package manager inside WSL.

Zish should not configure PowerShell, CMD, or native Windows Terminal settings unless a future explicit domain is added.

## Shell Path

The installer should find a usable `zsh` with:

```sh
command -v zsh
```

If `zsh` is missing, the installer should propose a package manager action when package installation is allowed. Changing the user's login shell with `chsh` should require explicit confirmation.

On Linux and WSL, installation should make Zsh the user's login shell when the current login shell is not already Zsh. The generated setup plan must show the current shell and target shell before applying the change. Interactive installs use the normal plan confirmation; non-interactive installs require `--yes`.

The login-shell change should run after managed files are installed and verified. If `chsh` is rejected by PAM, local account policy, or missing privileges, setup should not undo the completed shell configuration. It should report the manual `chsh` command, include a `sudo chsh` variant when `sudo` exists, and record that manual follow-up in the manifest.

The target shell should be discovered with `command -v zsh`, but the installer should prefer a usable Zsh path that is present in `/etc/shells` when that file exists. If Zsh is not available until package installation completes, the installer may defer target path resolution until after packages are installed. If the resolved Zsh path is not listed in `/etc/shells`, the installer should stop and report the manual `/etc/shells` and `chsh` steps instead of guessing.

## Package Manager Safety

Package-manager actions should:

- Appear in dry-run output.
- Require approval unless non-interactive mode explicitly allows them.
- Avoid upgrading unrelated packages.
- Clearly separate required dependencies from optional plugin dependencies.
- Report tools that cannot be installed through the detected package manager.

## Path Handling

All path logic should quote paths and support spaces. Avoid assuming `$HOME` has no spaces. Do not normalize paths in a way that crosses filesystem boundaries or resolves user-intended symlinks without recording that decision.
