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
- Honors capture (single + queued online) with throttle.
- QWP views (city groups with class/race/army rank variants).
- In-game list ingestion (citizens/hwho/cwho/enemies).

## Data Sources
- Primary: `https://api.achaea.com/characters/<Name>.json`
- Online list: `https://api.achaea.com/characters.json`
- Honors: race/title/city rank/xp rank/army rank (and class/city/house if missing).
- In-game lists: citizens/hwho/cwho tables and city/house enemies lists.

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

## Open Questions
- Mudlet version floor for HTTP and DB features.
- API rate limiting strategy and backoff thresholds.
- Export/import format and sharing workflow.
- How to merge remote data with local overrides (notes/IFF).
