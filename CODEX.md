# CODEX.md

Guidance for Codex when working in this repository.

## Project Overview
- Standalone Mudlet package for Achaea name tracking.
- Packaged source of truth is under `src/` (scripts/aliases/triggers).
- Target namespace: `agnosticdb`.

## Build System (Muddler)
- Work only in `src/` JSON + Lua files; never edit built artifacts.
- `mfile` version drives `@VERSION@`/`@PKGNAME@` replacements in code.
- Each object folder needs a manifest JSON: `scripts.json`, `aliases.json`, `triggers.json`, etc.

## Workflow Reminders
- Keep structure shallow and logical.
- Prefer the Mudlet DB for people data; use small Lua tables only for config.
- Default to using the Achaea API for lookups, with caching/backoff.
- Use `cecho` tags for colored output; avoid mixing `decho`-style tags.
- Make aliases responsive with confirmation output when they do not already emit results.
- Explain the reasoning behind code changes in responses.
- Commit and push changes unless the user asks otherwise.
