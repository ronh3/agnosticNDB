# Import / Export Formats

## People export (`adb export`)
Default file path: `getMudletHomeDir()/agnosticdb/exports/agnosticdb-export-YYYYMMDD-HHMMSS.json`.

Schema (version 2):
```json
{
  "version": 2,
  "exported_at": 1700000000,
  "people": [
    {
      "name": "Example",
      "class": "Bard",
      "city": "Cyrene",
      "current_form": "Elemental",
      "elemental_type": "Fire",
      "iff": "auto",
      "last_checked": 1700000000,
      "class_specs": [
        {
          "class": "Bard",
          "specialization": "Songcalling",
          "last_updated": 1700000000,
          "source": "honors"
        }
      ]
    }
  ]
}
```

Version 2 is the current people export contract. It emits only current-schema people fields plus per-class `class_specs`.

People import remains compatibility-oriented:
- Current version 2 exports are accepted.
- Older keyed records are accepted.
- Legacy `elemental_lord_type` imports are mapped to `elemental_type`.
- Legacy transformed race/class observations are normalized into `current_form`, `race`, and `class_specs` where possible.
- Omitted fields preserve existing stored data; explicit default values such as `""` and `-1` clear existing values.

## Config export (`adb config export`)
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
