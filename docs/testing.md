# Testing

Zish needs tests because installer bugs can damage a user's shell environment. The test strategy should cover pure logic, filesystem migration, and shell startup behavior.

## Test Layers

| Layer | Purpose |
| --- | --- |
| Unit | Platform detection, path planning, manifest parsing, managed block edits. |
| Integration | Fresh install, re-run, migration, rollback, plugin install, theme selection. |
| Shell | Verify Zsh startup and module loading. |
| Platform | Linux, macOS, and WSL behavior where practical. |

## Suggested Tools

Potential tools:

- `shellcheck` for shell scripts.
- `shfmt` for formatting shell scripts if style is standardized.
- `bats` for shell integration tests.
- Container fixtures for Linux distributions.
- Temporary home directories for migration tests.

The exact stack can change, but tests should be runnable from one documented command.

## Required Scenarios

Installer tests should eventually cover:

- Empty home directory.
- Existing unmanaged `~/.zshrc`.
- Existing managed `~/.zshrc`.
- Existing broken symlink.
- Existing plugin manager files.
- Dry-run with no writes.
- Non-interactive install with approval.
- Non-interactive install without approval.
- Dependency missing and package installation disabled.
- Rollback after successful install.
- Missing modern CLI tools with package installation enabled.
- Missing modern CLI tools with `--no-package-install`.

## Priority Checks

Tests and manual verification should protect the core priorities from `docs/principles.md`.

Performance checks:

- Measure shell startup before and after new managed modules when practical.
- Verify prompt rendering does not run network or package-manager commands.
- Confirm dry-run planning does not perform apply-phase writes.

Ease-of-use checks:

- Confirm install plans name each path, action, and reason.
- Confirm failures include a next action and backup location when relevant.
- Confirm re-running setup does not duplicate managed blocks.

Visual usefulness checks:

- Verify installer output is readable without color.
- Verify themes degrade when optional commands or glyph fonts are missing.
- Verify prompt state remains legible in narrow terminals.

## Filesystem Fixtures

Migration tests should run against temporary homes, not the developer's real home directory. Tests should create fixture homes with known files, run the planner or installer against them, and assert exact resulting files and manifests.

## Shell Verification

Startup verification should run Zsh in a controlled environment. It should avoid loading the developer's real startup files unless that is the test subject.

Examples of useful checks:

- Managed entrypoint exists.
- Managed block appears once.
- `zsh` exits successfully.
- Selected theme file can be sourced.
- Enabled plugin files can be sourced.
- `starship print-config` succeeds for the selected Starship config.
- `starship prompt` renders without configuration errors.
- `config/tools.zsh` loads in an interactive Zsh session.
- `install.sh --dry-run` reports missing tool packages without writing files.
- `bootstrap.sh --help` works without network access.
- `bootstrap.sh` refuses to overwrite a non-Git checkout path.

## Manual Verification

Until automated coverage exists, implementation changes should document:

- Platform tested.
- Command run.
- Starting shell file state.
- Files changed.
- Backup location.
- Result of re-running the installer.

Manual verification is not a replacement for tests, but it is better than undocumented installer changes.
