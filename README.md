# agnosticDB

Standalone name database for Mudlet + Achaea. This is a clean-room rewrite intended to be packaged with Muddler.

## Summary
- Achaea-only, API-first name database with local caching.
- Highlights names anywhere in output based on politics/enemy status.
- Honors capture for extra fields not provided by the API (race/ranks/army rank/title).
- QWP online list views with class/race/army rank variants.
- In-game list ingestion (citizens/hwho/cwho/enemies).

## Command Reference

### Core
- `adb`: show help.
- `adb politics`: show politics menu (city relations + highlight toggle).
- `adb stats`: counts by class and city.

### Notes + IFF
- `adb note <name> <notes>`: set notes for a person.
- `adb note <name>`: show notes.
- `adb note clear <name>`: clear notes for one person.
- `adb note clear all`: clear notes for everyone.
- `adb iff <name> enemy|ally|auto`: set IFF for a person.

### Lookup + Updates
- `adb whois <name>`: show stored data (fetches if missing).
- `adb fetch [name]`: fetch a person, or fetch the online list and queue updates.
- `adb refresh`: force refresh all online names.
- `adb quick`: fetch online list and only queue new names.
- `adb update`: refresh all known names.
- `adb list class|city|race <value>`: list people by a field.
- `adb list enemy`: list people marked as enemies.
- `adb ignore <name>`: toggle highlight ignore for a name.
- `adb forget <name>`: remove a person from the database.

### Honors
- `adb honors <name>`: capture honors output and ingest fields.
- `adb honors online`: queue honors for all online names (throttled; default 2s).

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

### Maintenance + Testing
- `adb dbcheck`: check database schema health.
- `adb dbreset`: reset database (drops people table).
- `adbtest`: run the self-test.

## In-Game List Capture
These triggers ingest data when you run the corresponding in-game commands:
- City enemies list: lines starting with `Enemies of the City of <city>:` update `enemy_city`.
- House enemies list: lines starting with `Enemies of the <house>:` update `enemy_house`.
- Active citizens list: lines starting with `The following are ACTIVE citizens of <city>:` update city for listed names.
- CWHO table: header line `Citizen Rank CT Class` updates class for listed names.
- HWHO table: header line `Member Rank HTell HNTell Probation Class` updates class for listed names.

## Data Stored Per Person
- Name, class, city, house, race.
- Title, city rank, XP rank, army rank.
- Enemy city/house markers and IFF.
- Notes, immortal/dragon flags, last checked time, source.

## Build
- Work only in `src/`.
- Build with `muddle` from repo root.

## License
MIT. See `LICENSE`.
