# agnosticDB 1.0.0 Release Notes

Released: 2026-05-05

agnosticDB 1.0.0 is the first stable release of the standalone Mudlet package for tracking Achaea characters through API refreshes, honors capture, in-game list ingestion, highlighting, reports, and script-facing helper APIs.

## Highlights

- Standalone Mudlet/Muddler package with persistent character storage.
- Public API ingestion for online lists, single-name fetches, quick refreshes, and full known-name update queues.
- Honors capture and queued honors refresh workflows with silent command dispatch to avoid client echo clutter.
- In-game list ingestion for `cwho`, enemies, citizens, class tables, house tables, and related confirmations.
- Framed UI reports for status, stats, recent updates, composition, qwp/qwhom output, queue state, and command feedback.
- Configurable highlights, city/enemy/IFF handling, ignore lists, and import/export for both database and configuration.
- Built-in city, class, style, element, and contrast themes, plus custom palettes and saved custom themes.
- `agnosticdb.theme.changed` Mudlet event for external UI integrations when the active theme changes.
- Lua helper API for other scripts to read stored person fields without depending on internal table layout.

## Notable Commands

- `adb`: compact jump menu.
- `adb help`: full command reference.
- `adb status`: package, DB, queue, and config status.
- `adb whois <name>`: stored person lookup with fetch fallback.
- `adb refresh`, `adb quick`, `adb update`: online and known-name refresh workflows.
- `adb honors <name>`, `adb honors online`, `adb honors all`: honors ingestion workflows.
- `qwp [opts]`: online list grouped by city, class, race, army, or rank.
- `qwhom [area]`: who-list grouping by area when mapper support is available.
- `adb config`, `adb theme list`, `adb highlights on|off`: main user configuration surfaces.

## Compatibility

- Target Mudlet version: 4.20.1 or newer.
- Build system: Muddler 1.1.0.
- No external Mudlet package dependencies are required.
- Mapper-aware qwhom grouping uses `mmp` APIs when present; without a mapper, entries fall back to "Unknown Area".

## Validation

- Local Lua syntax check passed.
- Local JSON metadata validation passed.
- Local `muddle` build passed and produced `build/agnosticDB.mpackage`.
- GitHub Actions Mudlet behavioral suite passed on the release candidate before the 1.0.0 bump.

## Upgrade Notes

- Existing agnosticDB data is stored in the Mudlet profile DB and should be preserved by package upgrade.
- Use `adb export` before upgrading if you want an explicit database backup.
- Use `adb config export` before upgrading if you want an explicit configuration backup.
- After installing, run `adb status` and `adb dbcheck` to confirm the package loaded and schema checks pass.

## Known Limits

- qwhom location grouping is only as precise as the mapper data available to Mudlet.
- Honors and API data can differ temporarily from in-game state until the next capture or refresh.
- The public API queue is intentionally throttled/configurable; large refreshes may take time depending on user settings.
