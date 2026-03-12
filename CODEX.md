# CODEX.md

Guidance for Codex when working in this repository.

## Project Overview
- Standalone Mudlet package for Achaea name tracking.
- Packaged source of truth is under `src/` (scripts/aliases/triggers).
- Target namespace: `agnosticdb`.

## Build System (Muddler)
- Work only in `src/` JSON + Lua files; never edit built artifacts.
- `mfile` version drives `@VERSION@`/`@PKGNAME@` replacements in code.
- Keep `mfile.title` synced manually to `agnosticDB-<version> (Achaea Name Database)` whenever `mfile.version` changes.
- Each object folder needs a manifest JSON: `scripts.json`, `aliases.json`, `triggers.json`, etc.

## Workflow Reminders
- Keep structure shallow and logical.
- Prefer the Mudlet DB for people data; use small Lua tables only for config.
- Default to using the Achaea API for lookups, with caching/backoff.
- Use `cecho` tags for colored output; avoid mixing `decho`-style tags.
- Make aliases responsive with confirmation output when they do not already emit results.
- Explain the reasoning behind code changes in responses.
- Commit and push changes unless the user asks otherwise.
- Keep `README.md` and `agnosticdb.ui.show_help()` in sync when commands or features change.
- Maintain the config UI look/feel (config theme + sectioned layout) for new menus.

## Testing Guidance
- GitHub Actions is the source of truth for behavioral tests in this repo; do not rely on host-side `busted` execution as a pass/fail signal.
- Keep Mudlet specs focused on stable runtime contracts and avoid overfitting to exact output formatting or optional runtime capabilities.
- If a capability is optional at runtime, such as JSON support, write specs to accept the module's documented fallback behavior.
- Re-enable quarantined specs one at a time after a green CI run, not in batches.
- If a new spec makes the suite red and the failure is not immediately diagnosable, quarantine that spec with a `.disabled` suffix and document why in `tests/README.md`.
