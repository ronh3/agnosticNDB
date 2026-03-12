# Mudlet Behavior Tests

These specs run inside a real Mudlet instance in GitHub Actions.

Current coverage:

- `agnosticdb_db_spec.lua`
  Confirms DB upsert/get behavior, `last_updated` stability for unchanged writes, and derived enemy logic.
- `agnosticdb_api_spec.lua`
  Confirms API list parsing, per-character fetch ingestion, and cache short-circuit behavior using stubbed HTTP responses.
- `agnosticdb_ui_spec.lua`
  Confirms the help and status views render key sections without throwing.

Good candidates for future additions:

- honors queue/capture behavior
- import/export round trips
- list/enemy ingestion from trigger-driven captures
- qwp/qwhom rendering
- queue progress, backoff, and cancel behavior
