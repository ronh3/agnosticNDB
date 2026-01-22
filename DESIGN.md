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

## Data Sources
- Primary: `https://api.achaea.com/characters/<Name>.json`
- Secondary (optional): in-game lists (cwho/hwho/citizens/qw), honors as fallback.

## Modules (planned)
- `Db`: schema, queries, migrations.
- `Api`: fetch, cache, backoff.
- `Iff`: ally/enemy/auto and derived logic.
- `Highlights`: trigger creation and ignore list.
- `Politics`: city relations + UI bindings.
- `Notes`: CRUD for per-person notes.
- `Ui`: alias/menu entry points.

## Open Questions
- Mudlet version floor for HTTP and DB features.
- API rate limiting strategy and backoff thresholds.
