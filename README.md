# agnosticDB

Standalone name database for Mudlet + Achaea. Clean-room rewrite intended for Muddler packaging.

## Quick Start
1) Install the package in Mudlet.
2) Run `adb` to confirm load.
3) Run `adb refresh` (or `adb fetch <name>`).
4) Use `adb whois <name>` or `adb stats`.
5) Customize highlights and timing in `adb config`.

## Common Commands
- `adb`: help.
- `adb whois <name>`: show stored data (fetch if needed).
- `adb fetch <name>` / `adb refresh`: fetch one or all online.
- `adb quick`: fetch online list and queue new names only.
- `adb config`: open config UI.
- `adb highlights on|off`: toggle highlights.
- `adb honors <name>`: capture honors.
- `adb stats`: summary counts.

## Docs
- `docs/index.md`: documentation hub.
- `docs/commands.md`: full command reference.
- `docs/data-schema.md`: DB fields, defaults, and semantics.
- `docs/lua-api.md`: getter helpers and module APIs.
- `docs/rate-limits.md`: API queue/backoff behavior.
- `docs/import-export.md`: JSON formats and paths.
- `docs/honors.md`: honors parsing notes.
- `docs/themes.md`: themes and palette usage.
- `docs/integration.md`: Mudlet requirements and dependencies.

## Build
- Work only in `src/`.
- Build with `muddle` from repo root.

## License
MIT. See `LICENSE`.
