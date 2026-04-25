# Integration Notes

## Requirements
- Mudlet 4.20.1 or newer, with DB API enabled and temp trigger support.
- Achaea GMCP for best results (e.g., prompt-based capture behavior).

## Optional Dependencies
- JSON decoding uses `json`, `yajl`, or `dkjson` (first available).
- Import/export requires `yajl` for encoding/decoding.
- QWHOM area grouping uses mapper APIs (`mmp`). Without a mapper, areas show as "Unknown Area".

## Network Usage
- API fetching uses `getHTTP` when available.
- Falls back to `downloadFile` if `getHTTP` is unavailable.
- Failure paths trigger backoff delays.

## Supported Runtime
- Mudlet 4.20.1 is the minimum supported runtime and the CI verification target.
- Newer Mudlet versions are expected to work when they preserve the DB, trigger, timer, HTTP/download, and profile-path APIs used by the package.
