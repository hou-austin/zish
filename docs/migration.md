# Migration

Migration is the highest-risk part of Zish. It must preserve existing shell behavior while introducing managed Zish hooks in a way that can be audited, updated, and rolled back.

## Paths to Inventory

The installer should inspect these common Zsh paths before applying changes:

```text
~/.zshenv
~/.zprofile
~/.zshrc
~/.zlogin
~/.zlogout
~/.oh-my-zsh/
~/.zinit/
~/.antigen/
~/.zplug/
~/.local/share/zish/
~/.local/state/zish/
~/.config/zish/
```

On macOS, platform-specific state and cache locations may also be relevant. See `docs/platforms.md`.

## Ownership Rules

Treat a path as user-owned unless one of these is true:

- It is a symlink created by Zish and recorded in state.
- It contains a Zish managed block with known markers.
- It exists under a Zish-managed directory.
- It is listed in the install state as created by Zish.

User-owned files may be read and backed up, but they should not be overwritten.

## Managed Blocks

When modifying an existing startup file such as `~/.zshrc`, prefer a managed source block:

```sh
# >>> zish managed block >>>
if [ -f "$HOME/.config/zish/init.zsh" ]; then
  source "$HOME/.config/zish/init.zsh"
fi
# <<< zish managed block <<<
```

The exact path may change once the installer layout is implemented. The markers should remain stable so re-runs can update the block instead of appending another copy.

## Backup Manifest

Every install run that changes files should create a manifest. The manifest should include:

- Timestamp.
- Platform.
- Repo path.
- Installer version or commit if available.
- Original path.
- Backup path.
- Action performed.
- File type before and after.
- Hash before and after when practical.

Use structured data. Do not rely on prose logs as the only rollback source.

Login-shell changes should also be recorded in the manifest with the affected user, previous shell, new shell, and action. The previous shell value is the rollback reference because the shell database is managed by the operating system rather than by a user-owned file in the repository.

## Backup Location

Default backup locations should follow platform conventions:

- Linux and WSL: `$XDG_STATE_HOME/zish/backups` or `~/.local/state/zish/backups`.
- macOS: `~/Library/Application Support/zish/backups` unless the user has opted into XDG paths.

The installer should allow `--backup-dir <path>` for explicit control.

## Atomicity

Prefer atomic writes:

1. Write new content to a temporary file in the same directory.
2. Preserve permissions where appropriate.
3. Rename the temporary file into place.
4. Record the result.

For symlinks, create a temporary symlink and rename it into place when the platform supports that safely.

## Rollback Rules

Rollback should:

- Use a specific backup manifest.
- Refuse to overwrite files that changed after the backup unless the user explicitly approves.
- Remove managed blocks cleanly.
- Restore symlinks as symlinks, directories as directories, and regular files as files.
- Restore the previous login shell with `chsh` when a manifest records a Zish login-shell change and the previous shell is still valid.
- Report manual steps when automatic restore is unsafe.

## Migration Scenarios

### Existing unmanaged `~/.zshrc`

Back up the file, insert or update one managed block, and leave user content intact.

### Existing managed `~/.zshrc`

Update the managed block in place after backing up the file. Do not append a second block.

### Existing plugin manager

Detect common plugin manager directories and config lines. Do not delete them automatically. The installer may warn about duplicate plugin loading and suggest a migration plan.

### Broken symlink

Back up the symlink itself, record its target, and replace it only after confirmation.

### WSL path crossing

Avoid writing managed shell files into `/mnt/c`, `/mnt/d`, or other Windows-mounted paths unless the user explicitly chose that location.
