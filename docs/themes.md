# Themes and Palette

## Themes
agnosticDB supports built-in themes (cities + classes) and custom palettes.

Common commands:
- `adb theme list`: view options.
- `adb theme <name>`: apply a theme (e.g., `adb theme mhaldor`).
- `adb theme auto`: use auto city themes.
- `adb theme preview`: preview built-in theme samples.

## Custom Palette
- `adb theme set <key> <color>`: set custom palette keys (`accent`, `border`, `text`, `muted`).
- `adb theme custom`: apply the current custom palette.
- `adb theme save <name>`: store the custom palette as a named theme.
- `adb theme delete <name>`: remove a saved theme.

Auto city themes only apply when no explicit theme/custom selection is set.
