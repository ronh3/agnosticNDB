# CODEX.md

Guidance for Codex and future agent sessions when working in this repository.

## Project Overview
- Standalone Mudlet package for Achaea name tracking.
- Packaged source of truth is under `src/` (scripts/aliases/triggers).
- Target namespace: `agnosticdb`.
- Treat this file as the durable agent continuity file.
- Keep this file lean. Put deep architecture in `DESIGN.md`, user-facing behavior in `README.md`, and active debugging or temporary notes elsewhere.

## Source Of Truth / Build System
- Work only in `src/` JSON + Lua files; never edit built artifacts.
- `mfile` version drives `@VERSION@`/`@PKGNAME@` replacements in code.
- Keep `mfile.title` synced manually to `agnosticDB-<version> (Achaea Name Database)` whenever `mfile.version` changes.
- Each object folder needs a manifest JSON: `scripts.json`, `aliases.json`, `triggers.json`, etc.
- Manifest names must stay aligned with the corresponding Lua/source filenames.
- Double-escape backslashes in Mudlet/Muddler JSON regex patterns, for example `"^\\d+$"`.
- Keep parent/child manifest wiring accurate when files are added, removed, renamed, or moved.
- Verify load-order-sensitive manifests manually instead of assuming generic sort order is safe.
- Build locally from repo root with `muddle`.

## Current Source Layout
- `src/scripts/` - ordered runtime modules, DB/API/config, UI, and feature logic.
- `src/aliases/` - shipped command surface and alias manifests.
- `src/triggers/` - capture triggers, class tracking, and qwhom wiring.
- `build/` - generated package output; never edit directly.
- Keep structure shallow and logical.

## Commands
- Startup reads:
  - `README.md`
  - `DESIGN.md`
  - `tests/README.md`
- Build:
  - `muddle`
- Test / smoke:
  - Prefer GitHub Actions Mudlet coverage as the source of truth.
  - If local checks are needed, use narrow static verification and file-level inspection rather than trusting host-side `busted`.
- Version checks:
  - `sed -n '1,40p' mfile`
- Debug / failure context:
  - `.github/workflows/main.yml`
  - `OUTPUT.md`

## Workflow Reminders
- Analyze first. Read the smallest set of files that define the behavior before proposing or making changes.
- For non-trivial work, pause for user approval before changing behavior, public APIs, gameplay logic, architecture, or other meaningful contracts.
- Small, mechanical, or clearly bounded fixes do not need a design discussion first; state the intent briefly and execute.
- Keep manifests, loaders, docs, and other adjacent wiring synchronized in the same change when behavior crosses layers.
- Prefer the Mudlet DB for people data; use small Lua tables only for config.
- Default to using the Achaea API for lookups, with caching/backoff.
- Use `cecho` tags for colored output; avoid mixing `decho`-style tags.
- Make aliases responsive with confirmation output when they do not already emit results.
- Explain the reasoning behind code changes in responses.
- Commit and push changes unless the user asks otherwise.
- Keep `README.md` and `agnosticdb.ui.show_help()` in sync when commands or features change.
- Maintain the config UI look/feel (config theme + sectioned layout) for new menus.
- Prefer coherent, minimal fixes over broad cleanup.
- If runtime verification is unavailable, say so explicitly and fall back to static checks.

## Agent Delegation
- Standing user instruction: Codex is explicitly authorized to spawn and coordinate subagents liberally at its discretion for repository exploration, independent codebase questions, bounded implementation slices, verification, and review.
- Prefer subagents when their work can run in parallel without blocking the immediate local task.
- Keep delegated tasks concrete and self-contained; avoid duplicate investigation and avoid overlapping write scopes.
- When delegating code edits, assign clear file or module ownership, then review and integrate the returned changes before finalizing.

## Versioning
- Treat `mfile.version` as the release version for the repo.
- Bump versions on every commit and every push unless the user explicitly asks otherwise.
- Keep version bumps monotonic.
- Keep `mfile.version` and `mfile.title` synchronized on every version change.
- Before committing or pushing, verify the authoritative and mirrored version fields are synchronized.
- Default expectation is verify, version, commit, and push completed work unless the user or repo-local rules say otherwise.

## Testing Guidance
- GitHub Actions is the source of truth for behavioral tests in this repo; do not rely on host-side `busted` execution as a pass/fail signal.
- Keep Mudlet specs focused on stable runtime contracts and avoid overfitting to exact output formatting or optional runtime capabilities.
- If a capability is optional at runtime, such as JSON support, write specs to accept the module's documented fallback behavior.
- Re-enable quarantined specs one at a time after a green CI run, not in batches.
- If a new spec makes the suite red and the failure is not immediately diagnosable, quarantine that spec with a `.disabled` suffix and document why in `tests/README.md`.

## Documentation Hygiene
- `CODEX.md` is for durable repo-specific agent rules and continuity only.
- `README.md` is for operator or user-facing behavior, commands, and package overview.
- `DESIGN.md` is for architecture, boundaries, and tradeoffs.
- Keep companion docs aligned when commands, aliases, triggers, manifests, APIs, load order, or visible behavior change.
- Do not store rolling session notes, active debug diaries, or long reference dumps in `CODEX.md`.

## Repo-Specific Notes
- Authoritative metadata/version file: `mfile`
- Namespace/module: `agnosticdb`
- Build command: `muddle`
- Primary smoke/test authority: GitHub Actions running Mudlet behavioral tests
- Mirrored version fields: `mfile.title`
- Hybrid live-source paths outside `src/`: none
- Special docs to read on startup: `README.md`, `DESIGN.md`, `tests/README.md`
- Push/branch policy overrides: none
- Testing authority overrides: CI Mudlet runtime is authoritative; host-side `busted` is not
- Other durable constraints:
  - Keep `mfile.title` in the form `agnosticDB-<version> (Achaea Name Database)`.
  - Keep `README.md` and `agnosticdb.ui.show_help()` synchronized when commands/features change.
  - Preserve the existing config UI theme and sectioned layout style.

# IMPORTANT: Re-read after context resets. Use this as the primary touchstone for Codex work here.
