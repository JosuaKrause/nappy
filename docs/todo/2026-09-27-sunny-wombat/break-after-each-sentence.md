**The marks' task line at the bottom left breaks at a sentence end like every other screen text**:
`Hud._refresh_resistance()` wraps both its lines (the ordinary one and the debug one) through
`SentenceLines.break_for_label(line, _resistance_label)`, and `$Root/Meters/Resistance` in
`hud.tscn` gets a `custom_minimum_size.x` so the helper has a width to measure. It waits for PR
#414, which changes the same function. The rest of the entry is built (PR #419,
[its record](../../decisions/2026-09-27-sunny-wombat.md)).

**Proposed, not asked for:** the task line is included at all, so a two-sentence mark too wide for
its line breaks between its sentences.
