# Mudlet Behavior Tests

These specs run inside a real Mudlet instance in GitHub Actions.

Current coverage:

- `agnosticdb_db_spec.lua`
  Confirms DB upsert/get behavior, `last_updated` stability for unchanged writes, and derived enemy logic.
- `agnosticdb_api_spec.lua`
  Confirms API list parsing, per-character fetch ingestion, and cache short-circuit behavior using stubbed HTTP responses.
- `agnosticdb_honors_spec.lua`
  Confirms honors parsing writes structured data and the honors queue deduplicates names, sends requests, and reports completion stats.
- `agnosticdb_transfer_spec.lua`
  Confirms export JSON generation and keyed import payload ingestion with highlight reloads.
- `agnosticdb_ingestion_spec.lua`
  Confirms citizens-list application, list-table class parsing, and personal-enemy capture replacement semantics.
- `agnosticdb_ui_spec.lua`
  Confirms the help and status views render key sections without throwing.

Good candidates for future additions:

- qwp/qwhom rendering
- queue progress, backoff, and cancel behavior
- config import/export and merge precedence
- city/house enemy capture semantics
