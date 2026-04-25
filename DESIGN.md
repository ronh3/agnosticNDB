# agnosticDB Design

## Scope
- Achaea-only, standalone Mudlet package.
- Clean-room implementation under MIT.

## Core Features
- People database (Mudlet DB) with cached API lookups.
- Highlights based on politics/enemy status + ignore list.
- IFF (ally/enemy/auto) with derived enemy checks.
- Notes per person.
- Politics UI for city relations and highlight settings.
- Config UI for API/honors timing, highlight styles, and quick toggles.
- Honors capture (single + queued online) with throttle.
- QWP/QWHOM views (city groups + mapper-based area views).
- Composition reports (city comp with/without honors refresh).
- Export/import for sharing/backup.
- In-game list ingestion (citizens/hwho/cwho/enemies).
- Class tracking triggers to infer class/spec/race from combat text.

## Data Sources
- Primary: `https://api.achaea.com/characters/<Name>.json`
- Online list: `https://api.achaea.com/characters.json`
- Honors: race/title/city rank/xp rank/army rank (and class/city/house if missing).
- In-game lists: citizens/hwho/cwho tables and city/house/personal enemies lists.
- Combat text: class/spec detection; elemental/dragon race detection.

## Modules
- `Db`: schema, queries, migrations.
- `Api`: fetch, cache, backoff.
- `Honors`: capture + parse honors output (queue/throttle support).
- `Iff`: ally/enemy/auto and derived logic.
- `Enemies`: capture city/house enemies lists.
- `Highlights`: trigger creation and ignore list.
- `Lists`: capture citizens/hwho/cwho tables.
- `Politics`: city relations + UI bindings.
- `Notes`: CRUD for per-person notes.
- `Ui`: alias/menu entry points.
- `ClassTracking`: class/spec/race updates from combat text.
- `Transfer`: import/export helpers.

## Config Flags
- `api.announce_changes_only`: when enabled, suppress queue completion output if nothing changed and mark API results as `unchanged`.

## Data Semantics
- `last_checked`: last time a character was queried or refreshed.
- `last_updated`: last time a character's stored data actually changed (used by `adb recent`).

## Runtime Compatibility
- Minimum supported Mudlet version: 4.20.1.
- CI verifies package load and behavioral tests against Mudlet 4.20.1.
- Required Mudlet capabilities include DB access, aliases/triggers, temp timers/triggers, profile paths, HTTP/download APIs, and colored echo output.

## Open Questions
- API rate limiting strategy and backoff thresholds.
- Export/import format and sharing workflow.
- How to merge remote data with local overrides (notes/IFF).

## Future Work
- Consider a lightweight wiki or `docs/` folder (install, workflows, troubleshooting, FAQ).

## Test Strategy
- Run behavioral coverage inside a real Mudlet instance in GitHub Actions.
- Favor a small stable suite over a larger brittle suite that blocks releases.
- Test public module behavior, persisted DB state, and documented fallback paths.
- Treat optional runtime facilities, especially JSON support, as environment-dependent and test both available and unavailable paths where relevant.
- Quarantine unstable specs instead of leaving the primary CI red; reintroduce them incrementally once they are proven in CI.
