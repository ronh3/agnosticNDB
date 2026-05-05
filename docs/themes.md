# Themes and Palette

## Themes
agnosticDB supports built-in themes (cities, classes, styles, elements, and contrast themes) plus custom palettes.

Common commands:
- `adb theme list`: view options.
- `adb theme <name>`: apply a theme (e.g., `adb theme mhaldor`).
- `adb theme auto`: use auto city themes.
- `adb theme preview`: preview built-in theme samples.

Additional built-in theme keys:
- Styles: `neon`, `cyberpunk`, `vaporwave`, `steampunk`, `solarpunk`, `voidpunk`.
- Elements: `fire`, `ice`, `electric`, `earth`, `water`, `void`.
- Contrast: `dark`, `light`.

## Custom Palette
- `adb theme set <key> <color>`: set custom palette keys (`accent`, `border`, `text`, `muted`).
- `adb theme custom`: apply the current custom palette.
- `adb theme save <name>`: store the custom palette as a named theme.
- `adb theme delete <name>`: remove a saved theme.

Auto city themes only apply when no explicit theme/custom selection is set.

## Theme Change Event
Successful theme changes raise Mudlet event `agnosticdb.theme.changed`.

Payload fields:
- `event`: always `agnosticdb.theme.changed`.
- `reason`: `set`, `save`, `delete`, or `palette`.
- `name`: resolved active theme key.
- `label`: display label for the active theme.
- `auto_city`: true when auto city theming is active.
- `tags`: current `accent`, `border`, `text`, `muted`, and `reset` cecho tags.
