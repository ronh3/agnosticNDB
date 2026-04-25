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
- Manual/local fields win unless a command explicitly edits them. API and honors refreshes should not clear notes, IFF, or enemy markers by omission.
- Remote sources update only the fields they actually know. Missing API/honors data means "no change"; explicit import defaults such as `""` or `-1` mean "clear this field".
- Class specializations are stored per class in `class_specs`; the legacy `people.specialization` column is migrated at load time and removed from the table.
- Transformed state is stored as `current_form` plus `elemental_type`; legacy `people.dragon` and `people.elemental_lord_type` are migrated at load time and removed from the table.

## Import / Export Contract
- People export schema version is `2`.
- Config export schema version is `1`.
- People imports accept current schema exports plus legacy/keyed records for compatibility.
- Importing merges onto existing people. Omitted fields preserve existing data; explicit default values clear existing data.
- Import may map legacy fields into the current model, but exports should only emit current-schema fields.

## API Queue Policy
- The 1.0 default for `api.min_interval_seconds` is `0`.
- Users can raise `api.min_interval_seconds` locally if Achaea API behavior or personal preference requires spacing requests.
- Failed requests still apply `api.backoff_seconds`; this is separate from the normal minimum interval.

## Runtime Compatibility
- Minimum supported Mudlet version: 4.20.1.
- CI verifies package load and behavioral tests against Mudlet 4.20.1.
- Required Mudlet capabilities include DB access, aliases/triggers, temp timers/triggers, profile paths, HTTP/download APIs, and colored echo output.

## Future Work
- Consider a lightweight wiki or `docs/` folder (install, workflows, troubleshooting, FAQ).

## Test Strategy
- Run behavioral coverage inside a real Mudlet instance in GitHub Actions.
- Favor a small stable suite over a larger brittle suite that blocks releases.
- Test public module behavior, persisted DB state, and documented fallback paths.
- Treat optional runtime facilities, especially JSON support, as environment-dependent and test both available and unavailable paths where relevant.
- Quarantine unstable specs instead of leaving the primary CI red; reintroduce them incrementally once they are proven in CI.
