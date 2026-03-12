# Mudlet Behavior Tests

These specs run inside a real Mudlet instance in GitHub Actions.

## Active Coverage

- `agnosticdb_db_spec.lua`
  Confirms DB upsert/get behavior, `last_updated` stability for unchanged writes, and derived enemy logic.
- `agnosticdb_api_spec.lua`
  Confirms API list parsing, per-character fetch ingestion, and cache short-circuit behavior using stubbed HTTP responses.
- `agnosticdb_honors_spec.lua`
  Confirms the honors module entry points exist and that a direct honors capture updates core parsed fields such as class, city, house, and ranks.
- `agnosticdb_ingestion_spec.lua`
  Confirms stable `finish_capture()` ingestion paths for citizens lists and personal enemy replacement.
- `agnosticdb_transfer_spec.lua`
  Confirms import/export entry points with explicit handling for environments where JSON support is unavailable.
- `agnosticdb_ui_spec.lua`
  Confirms the help and status views render key sections without throwing.

## Quarantined Specs

These are currently parked as `.disabled` files because the first CI versions were not yet stable enough for the Mudlet-backed suite:

Re-enable quarantined specs one file at a time, and only after the rewritten version passes CI.

## Design Rules

- Prefer public module entry points and stored state over testing internal helper behavior.
- Keep assertions on stable contracts: row changes, queue state, returned status values, and documented side effects.
- Treat optional runtime features as optional in tests too. If a module can return `json_unavailable` or similar, assert that contract instead of assuming the capability exists in CI.
- Avoid exact UI formatting assertions unless the output text is the contract being tested. Prefer checking for one or two anchor strings.
- Be careful with Mudlet globals like triggers, prompt state, and profile paths. Stub only the globals a spec actually needs, and restore them fully in `after_each`.
- When a spec starts failing in CI and the failure is not immediately diagnosable, quarantine it by renaming it to `.disabled` rather than keeping the whole suite red.

## Reintroduction Order

- Expand `agnosticdb_honors_spec.lua` last, since honors capture/queue flow is the most timing-sensitive.

## Future Additions

- qwp/qwhom rendering
- queue progress, backoff, and cancel behavior
- config import/export and merge precedence
- city/house enemy capture semantics
