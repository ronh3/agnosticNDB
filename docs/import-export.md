# Import / Export Formats

## People export (`adb export`)
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
