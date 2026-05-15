# Plugins

Plugins add shell behavior such as completions, aliases, functions, key bindings, and integrations. The plugin system should be explicit about sources, load order, and update behavior.

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

## Updates

Update behavior should be explicit. Remote plugins should support pinned revisions so a normal install remains reproducible. A future `zish update` command may refresh plugins, but it should show the proposed changes before applying them.

## Platform Constraints

Plugins may declare supported platforms. The installer should skip or warn for incompatible plugins instead of failing the whole setup unless the plugin is required.

## Failure Behavior

A plugin failure should not make the shell unusable. The loader should report the plugin name and error path, then continue when safe.

## Existing Plugin Managers

If the user already uses Oh My Zsh, zinit, antigen, zplug, or another plugin manager, the installer should not delete it automatically. It should identify likely overlap and offer a migration plan.
