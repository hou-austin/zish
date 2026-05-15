# Principles

Zish has three core product priorities: performance, ease of use, and visual usefulness. Safety and recoverability remain baseline requirements for any installer behavior that touches user files.

## Priority Order

When implementation choices conflict, use this order:

1. Preserve user data and make changes recoverable.
2. Keep shell startup and prompt rendering fast.
3. Make setup and maintenance easy to understand.
4. Make the terminal experience visually useful and good looking.

This order does not make visual quality optional. It means the project should not trade away safety or speed for decoration.

## Performance

Performance is part of the product, especially because shell code runs constantly.

Rules:

- Do not perform network calls during shell startup.
- Do not run package-manager commands during shell startup.
- Avoid repeated filesystem scans on every prompt render.
- Prefer lazy loading for optional plugins and expensive integrations.
- Cache expensive detection when the result is stable enough to cache.
- Keep prompt work synchronous only when it is cheap and predictable.
- Measure startup impact when adding new shell modules.

Targets:

- Managed startup overhead should stay small enough to feel instant on normal machines.
- Prompt rendering should not visibly block typing.
- Installer work may be slower, but it must show progress for long operations.

## Ease of Use

The common path should be obvious and safe.

Rules:

- Prefer one clear setup entrypoint.
- Make dry-run output match real install planning.
- Show what will change before changing it.
- Use readable names for themes, plugins, backups, and state files.
- Keep local overrides simple and documented.
- Provide useful errors with next actions.
- Make re-run, update, repair, and rollback first-class workflows.

Good ease of use means a user can install, inspect, update, and recover without reading installer source code.

## Visual Usefulness

Zish should look good because the shell is a daily interface. Visual design must help users scan state quickly.

Rules:

- Prompt themes should expose useful state such as directory, Git status, command status, and environment context.
- Installer output should be structured, readable, and calm.
- Color should encode meaning consistently.
- Themes should degrade gracefully when fonts, colors, or optional commands are unavailable.
- Avoid decoration that slows startup, hides important state, or makes copy/paste harder.
- Keep output legible in light and dark terminals when practical.

Visual polish should support speed and clarity. The best theme is attractive because it communicates well.

## Review Checklist

Before merging future implementation work, ask:

- Does this preserve and back up user-owned state?
- Does this add shell startup or prompt latency?
- Can a user understand the install plan?
- Can a user recover from a failed or unwanted change?
- Does the output or prompt make important state easier to see?
- Does the design still work on Linux, macOS, and WSL?
