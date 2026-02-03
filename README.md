# agnosticDB

Standalone name database for Mudlet + Achaea. This is a clean-room rewrite intended to be packaged with Muddler.

## Summary
- Achaea-only, API-first name database with local caching/backoff.
- Honors capture for extra fields not provided by the API (race/ranks/army rank/title).
- Highlights names anywhere in output based on politics/enemy status, with optional personal-enemy gating.
- Config UI with clickable color/style controls, quiet mode, and API/honors timing toggles.
- QWP/QWHOM views plus composition reports (with and without honors refresh).
- In-game list ingestion (citizens/hwho/cwho/enemies) + class tracking from combat lines.
- Import/export for sharing or backup.

## Getting Started
1) Install the package in Mudlet (via Muddler or the packaged ZIP).
2) Run `adb` to open help and confirm the package is loaded.
3) Run `adb refresh` to seed online names, or `adb fetch <name>` to start with a single character.
4) Use `adb whois <name>` to see stored data and `adb stats` for overall totals.
5) Customize highlights and timing in `adb config`.

## Command Reference

### Core
- `adb`: show help.
- `adb status`: system status overview.
- `adb theme <name>`: set UI theme (auto/custom/city or saved custom theme).
- `adb theme save <name>`: save the current custom palette as a named theme.
- `adb theme delete <name>`: delete a saved custom theme.
- `adb theme list`: list available themes.
- `adb theme set <key> <color>`: set custom theme palette keys (accent/border/text/muted).
- `adb theme preview`: show built-in theme samples.
- `adb queue cancel`: stop and clear the pending API queue.
- `adb config`: open configuration UI (colors, toggles, timing).
- `adb config set <key> <value>`: set a config value.
- `adb config toggle <key>`: toggle a config value.
  - Example: `adb config toggle api.announce_changes_only` (only announce when data changes)
- `adb config export [path]`: export configuration to JSON.
- `adb config import <path>`: import configuration from JSON.
- `adb politics`: show politics menu (city relations + highlight toggle).

### Notes + IFF
- `adb note <name> <notes>`: set notes for a person.
- `adb note <name>`: show notes.
- `adb note clear <name>`: clear notes for one person.
- `adb note clear all`: clear notes for everyone.
- `adb iff <name> enemy|ally|auto`: set IFF for a person.
- `adb ignore <name>`: toggle highlight ignore for a name.
- `adb elord <name> <type>`: set elemental lord type (air/earth/fire/water/clear).

### Lookup + Updates
- `adb whois <name> [short|raw]`: show stored data (fetches if missing). Use `short` for compact output or `raw` for full fields.
- `adb fetch <name>`: fetch a person (force refresh).
- `adb refresh`: force refresh all online names.
- `adb quick`: fetch online list and only queue new names.
- `adb update`: refresh all known names.
- `adb forget <name>`: remove a person from the database.

### Honors
- `adb honors <name>`: capture honors output and ingest fields.
- `adb honors online`: queue honors for all online names (throttled; default 2s).
- `adb honors online <city>`: queue honors for online names in a city.
- `adb honors all`: queue honors for every name in the database.

### Reports & Lists
- `adb stats`: counts by class/city/race/spec/elemental/dragon.
- `adb recent [n]`: show most recently updated people (default 20).
- `adb list class|city|race <value>`: list people by a field.
- `adb list enemy`: list people marked as enemies.
- `adb list xprank <= <n>`: list people with XP rank at or below a threshold.
- `adb find <text>`: find people by name substring.

### Highlights
- `adb highlights on|off`: toggle highlights.
- `adb highlights reload`: rebuild highlight triggers.
- `adb highlights clear`: remove all highlight triggers.

### QWP (Online Lists)
- `qwp [opts]`: online list grouped by city.
  - Options: `c|class`, `r|race`, `rc|race+class`, `cr|class+race`, `a|army`, `rank <n>`.
  - Examples: `qwp c`, `qwp rc`, `qwp a`, `qwp rank 3`, `qwp c rank 3`.
- `qwhom [area]`: who list grouped by area/location (mapper required).

### Composition / Enemies
- `adb comp <city>`: composition for a city (honors refresh before report).
- `adb qcomp [city]`: composition for a city (no honors refresh). With no city, lists all cities.
- `adb enemies`: capture your personal enemy list from game output.
- `adb enemy <city>`: enemy all online members of a city.

### Maintenance + Testing
- `adb dbcheck`: check database schema health.
- `adb dbreset`: reset database (drops people table).
- `adb export [path]`: export DB to JSON (default path in profile dir).
- `adb import <path>`: import DB from JSON.
- `adbtest`: run the self-test.

## In-Game List Capture
These triggers ingest data when you run the corresponding in-game commands:
- City enemies list: lines starting with `Enemies of the City of <city>:` update `enemy_city`.
- House enemies list: lines starting with `Enemies of the <house>:` update `enemy_house`.
- Personal enemies list: `You have the following enemies:` updates IFF to `enemy`.
- Enemy add/remove confirmations keep personal enemies in sync.
- Active citizens list: lines starting with `The following are ACTIVE citizens of <city>:` update city for listed names.
- CWHO table: header line `Citizen Rank CT Class` updates class for listed names.
- HWHO table: header line `Member Rank HTell HNTell Probation Class` updates class for listed names.
- Honors output: `HONORS for <name>` parses race/title/ranks/army rank/etc.
- Class tracking: combat messages update class/spec/race/elemental lord type.

## Data Stored Per Person
- Name, class, specialization, city, house, race.
- Title, city rank, XP rank, level, army rank, elemental lord type.
- Enemy city/house markers and IFF (ally/enemy/auto).
- Notes, immortal/dragon flags, last checked time, last updated time, source.

## Data Schema Details
The Mudlet DB table is `people`. Defaults indicate "unknown" unless otherwise noted.

| Field | Type | Unknown / Default |
| --- | --- | --- |
| `name` | string | required |
| `class` | string | `""` |
| `specialization` | string | `""` |
| `city` | string | `""` |
| `house` | string | `""` |
| `race` | string | `""` |
| `title` | string | `""` |
| `notes` | string | `""` |
| `iff` | string | `"auto"` (`"enemy"`/`"ally"`/`"auto"`) |
| `enemy_city` | string | `""` |
| `enemy_house` | string | `""` |
| `city_rank` | integer | `-1` |
| `xp_rank` | integer | `-1` |
| `army_rank` | integer | `-1` |
| `level` | integer | `-1` |
| `elemental_lord_type` | string | `""` |
| `immortal` | integer | `0` or `1` |
| `dragon` | integer | `0` or `1` |
| `last_checked` | integer | `0` (epoch seconds) |
| `last_updated` | integer | `0` (epoch seconds) |
| `source` | string | `""` (examples: `api`, `api_list`, `citizens_list`) |

## Lua API: Getter Helpers
Use these helpers to pull stored info for a person. Each returns `nil` if the value is missing or unknown.
- `agnosticdb.getPerson(name)`: full person record (table) or `nil`.
- `agnosticdb.getClass(name)`: class.
- `agnosticdb.getSpecialization(name)`: specialization.
- `agnosticdb.getCity(name)`: city.
- `agnosticdb.getHouse(name)`: house.
- `agnosticdb.getRace(name)`: race.
- `agnosticdb.getCityColor(name)`: city highlight color (based on config, with rogues for none).
- `agnosticdb.getElementalLordType(name)`: elemental lord type.
- `agnosticdb.getLevel(name)`: level.
- `agnosticdb.getTitle(name)`: title.
- `agnosticdb.getXpRank(name)`: XP rank.
- `agnosticdb.getCityRank(name)`: city rank.
- `agnosticdb.getArmyRank(name)`: army rank.
- `agnosticdb.getIff(name)`: IFF (ally/enemy/auto).
- `agnosticdb.getEnemyCity(name)`: enemy city marker.
- `agnosticdb.getEnemyHouse(name)`: enemy house marker.
- `agnosticdb.getNotes(name)`: notes.
- `agnosticdb.getLastChecked(name)`: last checked timestamp (epoch seconds).
- `agnosticdb.getSource(name)`: last update source.

## Lua API: Core Modules
These are the primary programmatic entry points (advanced use).

### Database
- `agnosticdb.db.ensure()`: initialize/verify DB access (returns boolean).
- `agnosticdb.db.init()`: initialize the DB and schema.
- `agnosticdb.db.check()`: schema health check.
- `agnosticdb.db.reset()`: drop/recreate `people`.
- `agnosticdb.db.get_person(name)`: fetch a row.
- `agnosticdb.db.upsert_person(fields)`: insert/update a row.
- `agnosticdb.db.delete_person(name)`: remove a row.
- `agnosticdb.db.normalize_name(name)`: normalize capitalization.

### API Queue
- `agnosticdb.api.fetch(name, on_done, opts)`: queue a single fetch. `opts.force=true` bypasses cache.
- `agnosticdb.api.fetch_online(on_done, opts)`: fetch online list + queue all names.
- `agnosticdb.api.fetch_online_new(on_done, opts)`: fetch online list + queue unknown names.
- `agnosticdb.api.update_all(on_done, opts)`: queue all known names.
- `agnosticdb.api.fetch_list(on_done)`: fetch online names list only.
- `agnosticdb.api.queue_fetches(names, opts)`: queue a list of names.
- `agnosticdb.api.seed_names(names, source)`: insert names without fetching.
- `agnosticdb.api.estimate_queue_seconds(extra)`: ETA helper.
- `agnosticdb.api.cancel_queue()`: clear the queue.
- `agnosticdb.api.url_for(name)`: API URL builder.

`on_done` callbacks receive `(person_or_payload, status)`; common statuses include
`ok`, `unchanged`, `cached`, `api_disabled`, `invalid_name`, `pruned`, `api_error`,
`decode_failed`, `download_error`, and `timeout`.

### Honors
- `agnosticdb.honors.capture(name, on_finish, opts)`: capture one honors output.
- `agnosticdb.honors.queue_names(names, on_done, opts)`: queue honors for names.
- `agnosticdb.honors.run_queue()`: process queue (normally called for you).
- `agnosticdb.honors.cancel_queue()`: stop queue + clear state.

### Highlights
- `agnosticdb.highlights.reload()`, `agnosticdb.highlights.clear()`.
- `agnosticdb.highlights.update(person)`, `agnosticdb.highlights.remove(name)`.
- `agnosticdb.highlights.toggle(enabled)`.
- `agnosticdb.highlights.ignore(name)`, `agnosticdb.highlights.unignore(name)`, `agnosticdb.highlights.is_ignored(name)`.

### IFF
- `agnosticdb.iff.set(name, status)`: set `enemy|ally|auto`.
- `agnosticdb.iff.is_enemy(name)`: true/false based on IFF + politics.

### Import/Export (People + Config)
- `agnosticdb.transfer.exportData(path)` / `agnosticdb.transfer.importData(path)`.
- `agnosticdb.config.export_settings(path)` / `agnosticdb.config.import_settings(path)`.

## Rate Limiting + Backoff (API)
These live under `agnosticdb.conf.api` and are editable in `adb config`:
- `enabled`: toggle API usage.
- `min_refresh_hours`: minimum age before a cached record is refreshed.
- `min_interval_seconds`: minimum delay between API requests in the queue.
- `backoff_seconds`: delay applied after API/HTTP failures.
- `timeout_seconds`: per-request timeout for the queue.
- `announce_changes_only`: suppress queue output if nothing changed.

The queue respects both `min_interval_seconds` and `backoff_seconds` and will delay requests when either applies.

## Import/Export Formats

### People export (`adb export`)
Default file path: `getMudletHomeDir()/agnosticdb/exports/agnosticdb-export-YYYYMMDD-HHMMSS.json`.

Schema (version 1):
```json
{
  "version": 1,
  "exported_at": 1700000000,
  "people": [
    {
      "name": "Example",
      "class": "Bard",
      "city": "Cyrene",
      "iff": "auto",
      "last_checked": 1700000000
    }
  ]
}
```

### Config export (`adb config export`)
Default file path: `getMudletHomeDir()/agnosticdb/agnosticdb_config.json`.

Schema (version 1):
```json
{
  "version": 1,
  "exported_at": 1700000000,
  "config": {
    "api": { "enabled": true, "min_refresh_hours": 24 },
    "honors": { "delay_seconds": 2 },
    "theme": { "name": "", "auto_city": true },
    "highlights_enabled": true
  }
}
```

## Honors Parsing Notes
- Honors parsing is line-based and relies on standard Achaea honors text.
- Class detection is limited to the known class list plus `"Dragon"` and `"Color Dragon"`.
- City detection matches against the politics city list; `(hidden)` honors entries keep the existing city.
- House detection is best-effort from lines containing `House` or `in the <House>`.
- Race detection comes from the parenthetical line (handles `male`/`female` prefixes).
- Ranks are extracted from `ranked <n>` lines; army rank is parsed from `(<n>) in the army of`.

## Integration Notes
- Requires Mudlet with the DB API enabled and temp trigger support.
- API fetching uses `getHTTP` (preferred) or `downloadFile` as a fallback.
- JSON decoding uses `json`, `yajl`, or `dkjson` (first available).
- Import/export requires `yajl` for encoding/decoding.
- QWHOM area grouping uses mapper APIs (`mmp`) when available; without a mapper it falls back to "Unknown Area".

## Notes on Updates
- `last_checked` tracks when a character was last queried.
- `last_updated` tracks when their stored data actually changed (used by `adb recent`).
- Enable `api.announce_changes_only` to suppress queue output if nothing changed.

## Themes
agnosticDB supports built-in themes (cities + classes) and custom palettes.
- Use `adb theme list` to view options.
- Use `adb theme <city>` (e.g., `adb theme mhaldor`) or `adb theme auto`.
- Use `adb theme set <key> <color>` to set custom palette keys, then `adb theme custom`.
- Use `adb theme save <name>` to store the current custom palette as a named theme.
Auto city themes only apply when no explicit theme/custom selection is set.

## Build
- Work only in `src/`.
- Build with `muddle` from repo root.

## License
MIT. See `LICENSE`.
