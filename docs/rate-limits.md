# API Rate Limiting and Backoff

Configuration lives under `agnosticdb.conf.api` and is editable with `adb config`.

## Settings
- `enabled`: toggle API usage.
- `min_refresh_hours`: minimum age before a cached record is refreshed.
- `min_interval_seconds`: minimum delay between API requests in the queue.
- `backoff_seconds`: delay applied after API/HTTP failures.
- `timeout_seconds`: per-request timeout for the queue.
- `announce_changes_only`: suppress queue output if nothing changed.

## Behavior
- The queue respects both `min_interval_seconds` and `backoff_seconds`.
- A failure (API/HTTP/decode/download) applies the backoff delay.
- Cached entries can be returned immediately if `min_refresh_hours` has not elapsed.
