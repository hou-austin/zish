# Repository Agent Guide

This file is for coding agents and contributors working in this repository.

## Mission

Zish is a multiplatform Zsh setup repository. Its core responsibility is to install and maintain shell configuration, themes, and plugins across Linux, macOS, and WSL without damaging existing user shell state.

When in doubt, preserve the user's environment first and make the change easy to inspect.

## Core Priorities

Use `docs/principles.md` as the decision filter for product and implementation choices.

- Performance is a feature. Avoid startup work that is slow, blocking, repeated, or hard to measure.
- Ease of use is a feature. Prefer clear defaults, readable plans, recoverable actions, and simple commands.
- Visual usefulness is a feature. Prompts and installer output should expose meaningful state with restraint and polish.

## Current Stage

The repository currently starts with documentation only. The installer, CLI, shell modules, manifests, themes, plugins, and tests should be implemented later against the contracts in `docs/`.

## Operating Rules

- Prefer small, reviewable changes scoped to one project domain.
- Do not overwrite or remove existing user files unless the user explicitly asks for that behavior.
- Installer work must be idempotent. Re-running setup should not duplicate blocks, lose user edits, or corrupt symlinks.
- Every destructive or potentially destructive action needs a backup and a manifest entry.
- Keep platform behavior explicit. Avoid platform-specific assumptions hidden inside generic helpers.
- Treat WSL as Linux with extra filesystem and interop constraints.
- Do not store secrets, tokens, machine-local credentials, or private keys in this repo.

## Documentation Responsibilities

Update documentation when behavior changes:

- Installer flow: `docs/installation.md`
- Backup, restore, or path migration: `docs/migration.md`
- Platform detection or package manager support: `docs/platforms.md`
- Core priorities or decision rules: `docs/principles.md`
- Starship prompt behavior: `docs/starship.md`
- Terminal font and cursor behavior: `docs/terminal.md`
- Zsh startup files or config layout: `docs/configuration.md`
- Modern CLI tool integration: `docs/tools.md`
- Prompt themes: `docs/themes.md`
- Plugins and load order: `docs/plugins.md`
- Test strategy or commands: `docs/testing.md`
- Cross-domain design changes: `docs/architecture.md`

## Installer Contract

Future installer code should follow these phases:

1. Discover platform and dependencies.
2. Inventory target paths.
3. Build a plan.
4. Back up affected paths.
5. Apply changes atomically where possible.
6. Verify Zsh startup.
7. Record install state.

Dry-run output should use the same planner as real installation. Do not maintain separate logic for preview and apply paths.

## Shell Configuration Contract

- Keep `~/.zshenv` minimal. It runs for every Zsh invocation.
- Put interactive shell behavior behind an interactive-shell guard.
- Use managed source blocks or symlinks that can be detected and updated safely.
- Preserve user-local overrides outside generated files.
- Shell modules should be readable and composable. Avoid one large startup file.

## Testing Expectations

Installer work should be covered by automated tests once the test harness exists. Until then, document manual verification steps in the relevant PR or change summary.

At minimum, risky changes should verify:

- Fresh install.
- Re-run after successful install.
- Existing unmanaged `~/.zshrc` migration.
- Existing managed install update.
- Failed dependency install or missing command behavior.
- macOS, Linux, and WSL path handling when relevant.

## Style

- Use POSIX shell only where portability requires it. Zsh-specific behavior belongs in `.zsh` files.
- Prefer structured manifests over parsing human text.
- Prefer clear state files over guessing from filesystem shape.
- Keep comments short and useful.
- Keep docs in ASCII unless a file already uses another character set.
