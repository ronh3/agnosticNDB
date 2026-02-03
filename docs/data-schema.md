# Data Schema

## Data Stored Per Person
- Name, class, specialization, city, house, race.
- Title, city rank, XP rank, level, army rank, elemental lord type.
- Enemy city/house markers and IFF (ally/enemy/auto).
- Notes, immortal/dragon flags, last checked time, last updated time, source.

## Field Defaults
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

## Notes on Updates
- `last_checked` tracks when a character was last queried.
- `last_updated` tracks when their stored data actually changed (used by `adb recent`).
- Enable `api.announce_changes_only` to suppress queue output if nothing changed.
