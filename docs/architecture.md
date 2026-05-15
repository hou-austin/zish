# Architecture

Zish is organized around a small set of domains: installer, migration, platform support, configuration, tools, themes, plugins, and testing. Each domain should have a clear contract so platform-specific behavior and user-state changes remain easy to audit.

The architecture should be judged against the project priorities in `docs/principles.md`: performance, ease of use, and visual usefulness.

## Project Domains

| Domain | Responsibility |
| --- | --- |
| Installer | User interface, planning, dependency setup, apply flow, verification. |
| Migration | Inventory, backups, restore manifests, managed block updates, rollback. |
| Platforms | OS, WSL, package manager, filesystem, and shell path detection. |
| Configuration | Zsh startup file strategy and managed configuration modules. |
| Tools | Modern CLI dependency installation, aliases, and config files. |
| Themes | Prompt assets, theme metadata, theme selection, prompt initialization. |
| Plugins | Plugin manifests, dependency resolution, load order, updates. |
| Testing | Automated and manual verification across install scenarios. |

## Decision Invariants

- Safety and recoverability are non-negotiable for any user-path mutation.
- Performance should be designed in early, measured, and protected by tests where practical.
- Ease of use should come from good defaults, clear plans, and reversible actions.
- Visual polish should make shell state easier to scan, not just add decoration.

## Proposed Runtime Layout

```text
bin/
|-- zish              # Future CLI
`-- install           # Future install entrypoint, if kept separate

lib/
|-- installer/        # Future planning and apply orchestration
|-- migration/        # Future backups, manifests, restore helpers
|-- platform/         # Future OS, WSL, package manager, path detection
|-- setup/            # Current setup helpers
`-- shell/            # Future shared shell helpers

config/
|-- init.zsh          # Main managed source entrypoint
|-- tools.zsh         # Modern CLI integration
|-- bat.conf
|-- ripgreprc
|-- env.zsh           # Safe environment defaults
|-- aliases.zsh
|-- completion.zsh
`-- local.example.zsh

themes/
|-- <theme>/
|   |-- starship.toml
|   `-- theme.toml

plugins/
|-- plugins.toml
`-- local/

tests/
|-- fixtures/
|-- integration/
`-- unit/
```

This layout is a target, not current implementation.

## Installer Phases

The installer should be built around one planner and one applier:

1. Discovery: detect platform, shell, package manager, repo root, home directory, and existing target paths.
2. Inventory: inspect files and directories that may be read, backed up, linked, or modified.
3. Plan: produce a structured list of actions with risk levels and reasons.
4. Confirmation: present the plan to the user unless running in an explicitly non-interactive approved mode.
5. Backup: copy every affected existing path into a timestamped backup location and write a manifest.
6. Apply: create directories, install dependencies, write managed files, update source blocks, and create symlinks.
7. Verify: start Zsh in a controlled mode and check that managed files load without errors.
8. Record: write install state so re-runs, updates, and rollbacks are deterministic.

Dry-run and real install should share phases 1 through 3. Dry-run should not use a separate approximation.

## State Model

Future state should be structured data, preferably JSON or TOML, and should record:

- Zish repo path used for the install.
- Platform detection result.
- Installer version or commit if available.
- Files and directories changed.
- Backup manifest path.
- Managed source block markers and target files.
- Selected theme.
- Enabled plugins and pinned revisions where relevant.

State should be useful for update, repair, doctor, and rollback commands.

## Managed vs User-Owned Files

A file is managed only when Zish created it, symlinked it, or owns a clearly marked block inside it. Everything else is user-owned and must be treated conservatively.

Preferred strategies:

- Use managed blocks for common startup files such as `~/.zshrc`.
- Use symlinks only when the target is safe to replace or already managed.
- Keep user-local overrides in separate files that are loaded after managed defaults.

## Failure Handling

Failures should stop before partial state becomes ambiguous. If a phase fails after backups exist, the installer should report:

- What completed.
- What did not run.
- Where backups and manifests were written.
- Whether automatic rollback is available.

The installer should avoid making best-effort edits after a high-risk failure.
