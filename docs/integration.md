# Integration Notes

## Requirements
- Mudlet with DB API enabled and temp trigger support.
- Achaea GMCP for best results (e.g., prompt-based capture behavior).

## Optional Dependencies
- JSON decoding uses `json`, `yajl`, or `dkjson` (first available).
- Import/export requires `yajl` for encoding/decoding.
- QWHOM area grouping uses mapper APIs (`mmp`). Without a mapper, areas show as "Unknown Area".

## Network Usage
- API fetching uses `getHTTP` when available.
- Falls back to `downloadFile` if `getHTTP` is unavailable.
- Failure paths trigger backoff delays.
