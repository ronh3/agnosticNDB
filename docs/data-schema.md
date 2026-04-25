# Data Schema

## Data Stored Per Person
- Name, current class, city, house, normalized base race.
- Current form (`Dragon` / `Elemental` / blank), remembered elemental type, and title.
- Enemy city/house markers and IFF (ally/enemy/auto).
- Notes, immortal flag, last checked time, last updated time, source.
- Per-class specializations in the separate `class_specs` table.

## Field Defaults
The Mudlet DB tables are `people` and `class_specs`. Defaults indicate "unknown" unless otherwise noted.

| Field | Type | Unknown / Default |
| --- | --- | --- |
| `name` | string | required |
| `class` | string | `""` |
| `city` | string | `""` |
| `house` | string | `""` |
| `race` | string | `""` |
| `current_form` | string | `""` (`Dragon` / `Elemental`) |
| `elemental_type` | string | `""` (`Air` / `Earth` / `Fire` / `Water`) |
| `title` | string | `""` |
| `notes` | string | `""` |
| `iff` | string | `"auto"` (`"enemy"`/`"ally"`/`"auto"`) |
| `enemy_city` | string | `""` |
| `enemy_house` | string | `""` |
| `city_rank` | integer | `-1` |
| `xp_rank` | integer | `-1` |
| `army_rank` | integer | `-1` |
| `level` | integer | `-1` |
| `immortal` | integer | `0` or `1` |
| `last_checked` | integer | `0` (epoch seconds) |
| `last_updated` | integer | `0` (epoch seconds) |
| `source` | string | `""` (examples: `api`, `api_list`, `citizens_list`) |

## `class_specs`

| Field | Type | Unknown / Default |
| --- | --- | --- |
| `name` | string | required |
| `class` | string | required |
| `specialization` | string | `""` |
| `last_updated` | integer | `0` |
| `source` | string | `""` |

## Notes on Updates
- `last_checked` tracks when a character was last queried.
- `last_updated` tracks when their stored data actually changed (used by `adb recent`).
- `race` is normalized to the base race only. Transformed states are tracked in `current_form`.
- `elemental_type` is remembered separately so a known subtype can survive reverting out of elemental form.
- Enable `api.announce_changes_only` to suppress queue output if nothing changed.

## Legacy Cleanup
- `people.specialization` is no longer part of the people table. Load-time migration moves its value into `class_specs`.
- `people.elemental_lord_type` is no longer part of the people table. Load-time migration maps it to `elemental_type` and `current_form`.
- `people.dragon` is no longer part of the people table. Load-time migration maps it to `current_form = "Dragon"`.
- After migration, the people table is rebuilt without those legacy columns.
