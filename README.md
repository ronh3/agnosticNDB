# agnosticDB

Standalone name database for Mudlet + Achaea. This is a clean-room rewrite intended to be packaged with Muddler.

## Summary
- Achaea-only, API-first name database with local caching/backoff.
- Honors capture for extra fields not provided by the API (race/ranks/army rank/title).
- Highlights names anywhere in output based on politics/enemy status, with optional personal-enemy gating.
- Config UI with clickable color/style controls + API/honors timing toggles.
- QWP/QWHOM views plus composition reports (with and without honors refresh).
- In-game list ingestion (citizens/hwho/cwho/enemies) + class tracking from combat lines.
- Import/export for sharing or backup.

## Getting Started
1) Install the package in Mudlet (via Muddler or the packaged ZIP).
2) Run `adb` to open help and confirm the package is loaded.
3) Run `adb fetch` to seed online names, or `adb fetch <name>` to start with a single character.
4) Use `adb whois <name>` to see stored data and `adb stats` for overall totals.
5) Customize highlights and timing in `adb config`.

## Command Reference

### Core
- `adb`: show help.
- `adb status`: system status overview.
- `adb theme <name>`: set UI theme (auto/custom/city).
- `adb theme list`: list available themes.
- `adb theme set <key> <color>`: set custom theme palette keys (accent/border/text/muted).
- `adb theme preview`: show built-in theme samples.
- `adb queue cancel`: stop and clear the pending API queue.
- `adb config`: open configuration UI (colors, toggles, timing).
- `adb config set <key> <value>`: set a config value.
- `adb config toggle <key>`: toggle a config value.
  - Example: `adb config toggle api.announce_changes_only` (only announce when data changes)
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
- `adb whois <name> [short]`: show stored data (fetches if missing). Use `short` for compact output.
- `adb fetch [name]`: fetch a person, or fetch the online list and queue updates.
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

### Highlights
- `adb highlights on|off`: toggle highlights.
- `adb highlights reload`: rebuild highlight triggers.
- `adb highlights clear`: remove all highlight triggers.

### QWP (Online Lists)
- `qwp`: online list grouped by city.
- `qwpr`: city + race.
- `qwpc`: city + class (Elemental/Dragon shows race instead).
- `qwprc`: city + race/class.
- `qwpcr`: city + class/race.
- `qwpa`: city + army rank (only shows people with an army rank).
- `qwp rank <n>`: city list filtered to army rank >= n.
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

## Notes on Updates
- `last_checked` tracks when a character was last queried.
- `last_updated` tracks when their stored data actually changed (used by `adb recent`).
- Enable `api.announce_changes_only` to suppress queue output if nothing changed.

## Themes
agnosticDB supports built-in themes (one per city + Rogue) and custom palettes.
- Use `adb theme list` to view options.
- Use `adb theme <city>` (e.g., `adb theme mhaldor`) or `adb theme auto`.
- Use `adb theme set <key> <color>` to set custom palette keys, then `adb theme custom`.
Auto city themes only apply when no explicit theme/custom selection is set.

## Build
- Work only in `src/`.
- Build with `muddle` from repo root.

## License
MIT. See `LICENSE`.
