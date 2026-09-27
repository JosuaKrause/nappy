priority: now

# frosty-stork — The player indicators fit inside their image bounds · filed 2026-09-26

The player reports that the icons above the player look cut off and proposes larger bounds in
[Merry hare](../../playtests/2026-09-26-merry-hare.md). Inspect the warning marks and baby-state
icons through their source images, atlas bake and runtime draw. Preserve their size, position,
colors, flashing, meaning and separation from the player's other cues.

The player identifies the bottom of the triple-wave symbol in `ui.png` and explicitly requests
a new PR. Source-image and atlas bounds are the target; viewport-edge behavior is outside it.

The orchestrator places this bounded investigation in `now` for the player's current request;
that priority is a proposal, not a change to the order of unrelated work.
