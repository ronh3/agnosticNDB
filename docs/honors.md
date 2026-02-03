# Honors Parsing

## Behavior
- Honors parsing is line-based and relies on standard Achaea honors text.
- The capture runs until the prompt arrives (or a prompt trigger fires).
- Parsed fields are merged into the DB record for the target name.

## What It Detects
- Class: known class list plus `Dragon` and `<Color> Dragon`.
- City: matches against the politics city list.
- House: best-effort from `House of <Name>` / `House <Name>` / `in the <House>`.
- Race: taken from the parenthetical line (handles `male`/`female` prefixes).
- Ranks: city and XP ranks parsed from `ranked <n>` lines.
- Army rank: parsed from `(<n>) in the army of`.
- Immortal/Dragon flags: if those words appear in honors text.

## Edge Cases
- `(hidden)` city entries keep the existing city if one is already stored.
- If the honors text format changes, some fields may fail to parse.
- City detection depends on the politics city list; missing entries will not match.

## Queueing
- Honors queue delay is controlled by `agnosticdb.conf.honors.delay_seconds`.
- Queueing is optional; use `adb honors <name>` for single captures.
