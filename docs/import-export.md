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
