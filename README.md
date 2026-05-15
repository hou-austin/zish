# Zish

Zish is a multiplatform Zsh setup repository for Linux, macOS, and Windows through WSL. It is intended to carry shell themes, plugins, and configuration, plus an installer that can set up the full environment while migrating existing shell files reliably.

Current status: initial documentation, a setup entrypoint, Zsh configuration modules, Starship prompt assets, and modern CLI tool integration. Migration manifests, automated tests, plugins, and broader shell modules still need to be implemented against the contracts in `docs/`.

## Goals

- Provide a repeatable Zsh setup for Linux, macOS, and WSL.
- Keep themes, plugins, and configuration in one inspectable repository.
- Make installation safe by inventorying, backing up, and migrating existing shell paths before writing managed files.
- Support interactive setup first, with dry-run and non-interactive modes for automation.
- Keep platform-specific behavior explicit instead of hiding it in ad hoc conditionals.

## Core Priorities

Zish should feel fast, obvious, and worth looking at every day.

- Performance: shell startup and prompt rendering must stay fast, measurable, and free of avoidable blocking work.
- Ease of use: installation, updates, rollback, and configuration should be clear enough to run without reading implementation code.
- Visual usefulness: prompts, themes, and installer output should be attractive, readable, and information-dense without becoming noisy.

See [docs/principles.md](docs/principles.md) for the decision rules behind these priorities.

## Non-goals

- Native Windows shell support outside WSL.
- Managing every dotfile on the machine.
- Replacing the system package manager.
- Silently overwriting unmanaged user files.

## Intended Layout

```text
.
|-- README.md
|-- AGENTS.md
|-- bootstrap.sh
|-- install.sh
|-- docs/
|   |-- architecture.md
|   |-- configuration.md
|   |-- installation.md
|   |-- migration.md
|   |-- platforms.md
|   |-- principles.md
|   |-- plugins.md
|   |-- starship.md
|   |-- testing.md
|   |-- themes.md
|   `-- tools.md
|-- bin/              # Future CLI and installer entrypoints
|-- lib/              # Installer helper libraries
|-- config/           # Zsh configuration modules
|-- themes/           # Prompt themes
|-- plugins/          # Future local plugin definitions or vendored plugins
`-- tests/            # Future automated install and shell behavior tests
```

## Current Shell Assets

- [bootstrap.sh](bootstrap.sh): curl-friendly clone/update wrapper.
- [install.sh](install.sh): current setup entrypoint.
- [config/init.zsh](config/init.zsh): managed interactive Zsh entrypoint.
- [config/tools.zsh](config/tools.zsh): modern CLI integration for `eza`, `bat`, `ripgrep`, and `difftastic`.
- [config/bat.conf](config/bat.conf): default `bat` display settings.
- [config/ripgreprc](config/ripgreprc): default `ripgrep` behavior.
- [config/starship.zsh](config/starship.zsh): Starship initialization and theme selection.
- [config/local.example.zsh](config/local.example.zsh): example machine-local prompt settings.
- [themes/blue-owl-starship](themes/blue-owl-starship): Starship port of the Oh My Posh `blue-owl` theme.

## Supported Platforms

| Platform | Target | Notes |
| --- | --- | --- |
| Linux | Primary | Support common package managers where practical. |
| macOS | Primary | Prefer Homebrew when package installation is needed. |
| Windows through WSL | Primary | Treat the WSL distribution as Linux, while being careful with Windows-mounted paths. |
| Native Windows | Unsupported | Use WSL instead. |

See [docs/platforms.md](docs/platforms.md) for the platform contract.

## One-Line Setup

Once this repo is published, setup can be run with:

```sh
curl -fsSL https://raw.githubusercontent.com/austinhou/zish/main/bootstrap.sh | sh
```

For non-interactive setup:

```sh
curl -fsSL https://raw.githubusercontent.com/austinhou/zish/main/bootstrap.sh | sh -s -- --yes
```

The bootstrap script clones or updates the repo, then runs `install.sh`.

## Planned Install Flow

The future installer should follow this order:

1. Detect platform, shell, package manager, and important filesystem paths.
2. Inventory existing shell files and directories.
3. Produce a migration plan and show it to the user.
4. Back up every path that may be changed.
5. Install required dependencies when allowed.
6. Install or link Zish-managed configuration, themes, and plugins.
7. Verify that Zsh starts successfully.
8. Write install state so future runs can update or roll back safely.

The planned user interface is documented in [docs/installation.md](docs/installation.md).

## Safety Model

Zish must be conservative with existing shell state. It should never replace user-owned files without a restorable backup and a manifest that records exactly what changed. Repeated installs should be idempotent: a second run should update managed files without duplicating source blocks or losing user changes.

Migration details are defined in [docs/migration.md](docs/migration.md).

## Documentation Map

- [Architecture](docs/architecture.md): project domains, boundaries, and installer phases.
- [Installation](docs/installation.md): planned setup interface and install lifecycle.
- [Migration](docs/migration.md): backup, restore, and existing-path migration rules.
- [Platforms](docs/platforms.md): Linux, macOS, and WSL behavior.
- [Principles](docs/principles.md): core priorities and decision invariants.
- [Starship](docs/starship.md): prompt integration and theme porting rules.
- [Configuration](docs/configuration.md): Zsh config layering and local overrides.
- [Themes](docs/themes.md): theme packaging and prompt requirements.
- [Tools](docs/tools.md): modern CLI dependencies and shell integration.
- [Plugins](docs/plugins.md): plugin manifest, loading, and updates.
- [Testing](docs/testing.md): expected automated and manual verification.

## Contributing

Before changing installer behavior, read [AGENTS.md](AGENTS.md) and the relevant domain document. Installer changes should include tests or a documented manual verification path, especially when they touch migration, backups, shell startup, or platform detection.
