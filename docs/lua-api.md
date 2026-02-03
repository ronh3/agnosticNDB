# Lua API

## Getter Helpers
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

## Core Modules

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
