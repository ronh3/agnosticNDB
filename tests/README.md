# Mudlet Behavior Tests

These specs run inside a real Mudlet instance in GitHub Actions.

## Active Coverage

- `agnosticdb_db_spec.lua`
  Confirms DB upsert/get behavior, per-class specialization storage, merge semantics for omitted versus explicit values, `last_updated` stability for unchanged writes, numeric-race cleanup, derived enemy logic, and load-time migration/removal of legacy people columns without losing current fields.
- `agnosticdb_api_spec.lua`
  Confirms API list parsing, backoff gating, per-character fetch ingestion, hidden-city merge preservation, cache short-circuit behavior, queue ETA math, queue cancellation, queue progress milestones, update-all queueing, and missing-only online refresh behavior using stubbed HTTP responses.
- `agnosticdb_config_spec.lua`
  Confirms config import/export entry points, partial import merge behavior, JSON-capability fallback behavior, and highlight reload on import.
- `agnosticdb_honors_spec.lua`
  Confirms the honors module entry points exist, that direct honors captures update parsed fields such as class, city, house, normalized race, current form, and ranks, that hidden captures preserve omitted stored fields, and that queue startup deduplicates names and queue cancellation clears state.
- `agnosticdb_highlights_spec.lua`
  Confirms generated highlight triggers use whole-name regex boundaries so names do not fire inside contractions or larger words.
- `agnosticdb_ingestion_spec.lua`
  Confirms stable `finish_capture()` ingestion paths for citizens lists, captured list-table class rows, including source-preservation behavior, plus direct helper and replacement behavior for personal, city, and house enemies.
- `agnosticdb_transfer_spec.lua`
  Confirms import/export entry points, export metadata shape for the new state model, current v2 import records with class specs, and import merge/clearing behavior, with explicit handling for environments where JSON support is unavailable.
- `agnosticdb_ui_spec.lua`
  Provides thin UI integration coverage for status, framed stats output, qwp command wiring, qwhom framed rendering, queue cancellation, recent updates, online refresh/update wrappers, ignore toggling, IFF, and elemental-type actions.
- `agnosticdb_qwhom_spec.lua`
  Confirms qwhom capture startup, queue-noise filtering, mapper and mapper-less grouping, dead-entry handling, finish cleanup, and filtered empty output through stable module-level seams.

## Design Rules

- Prefer public module entry points and stored state over testing internal helper behavior.
- Keep assertions on stable contracts: row changes, queue state, returned status values, and documented side effects.
- Treat optional runtime features as optional in tests too. If a module can return `json_unavailable` or similar, assert that contract instead of assuming the capability exists in CI.
- Avoid exact UI formatting assertions unless the output text is the contract being tested. Prefer checking for one or two anchor strings.
- Be careful with Mudlet globals like triggers, prompt state, and profile paths. Stub only the globals a spec actually needs, and restore them fully in `after_each`.
- When a spec starts failing in CI and the failure is not immediately diagnosable, quarantine it by renaming it to `.disabled` rather than keeping the whole suite red.

## Future Additions

- Broaden qwhom coverage only where a new stable runtime contract is introduced.
