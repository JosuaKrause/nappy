## M97 — Calm areas that hold is closed · 2026-09-23

*([PLAYTEST-126](../playtests/PLAYTEST-126.md), statements 3 to 6.)* Its three open items are closed
by the player: parks never touch by construction, so the item that asked for a seed showing two
parks side by side has nothing to find; a spoiled park that stays usable "is not a concern
anymore" and the player opens a new item if it recurs (the probe that measured it,
`tests/probes/m97_spoilage.gd`, stays); and the number of calm areas "is fine", so the re-check
of `MIN_CALM_BLOCKS` and `MIN_HOME_TO_PARK_TILES` is dropped. The player's "we just need to stop
spoiling parks after a few days so the pool refreshes" is how the scheduler already works: it
spoils the parks she has used **this act** (`GameState.settled_this_act()`), and the memory
resets at each act boundary (days 1, 4, 8 and 12), so no park stays spoiled past its act.
