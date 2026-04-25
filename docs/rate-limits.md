# API Rate Limiting and Backoff

Configuration lives under `agnosticdb.conf.api` and is editable with `adb config`.

## Settings
- `enabled`: toggle API usage.
- `min_refresh_hours`: minimum age before a cached record is refreshed. Default: `24`.
- `min_interval_seconds`: minimum delay between normal API requests in the queue. Default for 1.0: `0`.
- `backoff_seconds`: delay applied after API/HTTP failures. Default: `30`.
- `timeout_seconds`: per-request timeout for the queue. Default: `15`.
- `announce_changes_only`: suppress queue output if nothing changed. Default: `false`.

## Behavior
- The queue respects both `min_interval_seconds` and `backoff_seconds`.
- A failure (API/HTTP/decode/download) applies the backoff delay.
- Cached entries can be returned immediately if `min_refresh_hours` has not elapsed.
- `min_interval_seconds = 0` is intentional: normal queued requests are not artificially delayed unless the user opts in.
