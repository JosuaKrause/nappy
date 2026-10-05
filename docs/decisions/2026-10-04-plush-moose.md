# plush-moose — Every task has a red arrow, on the closest by walking distance · 2026-10-05

Filed from [busy-quail](../playtests/2026-10-04-busy-quail.md) (inbox #562): "task day 13 has a bug
there is no red arrow?", then "yeah let's just always do arrows"; and on day 11's mast (inbox #561):
"let it point to the closest one first. the red arrow (in general) might switch if another closest
one comes close ... closest here always means path closeness not crow closeness".

**Built.** Every task draws the red arrow, day 6's man shouting and day 13's roadblock included.
Where more than one place answers a task — every live man shouting on day 6, every live roadblock on
day 13, and every live mast on day 11 (the player, choosing between the two masts the day sets up
and any live mast: "I go with 2 for the masts. why limit artificially to two arbitrary masts", inbox
#599 in [olive-hedgehog](../playtests/2026-10-05-olive-hedgehog.md)) — the arrow points at the one
closest by walking distance and switches when another is at least four tiles of walking closer. A
task with one place keeps its arrow on it. On day 11 touching any live mast completes the task and
silences and scars that mast; a live mast is one `_place_at_a_mast()` could offer (placed,
unsilenced, off the home block, with legal reachable ground beside its foot).

Walking distance comes from distance fields swept out from the targets over the walkable city
(`src/resistance/arrow_field.gd`): one from every target at once, labelling each tile with its
nearest, and one from the arrowed target alone, for the hold. They are rebuilt, a thousand tiles a
frame, only when the targets or what blocks her change (closures, seals, and bodies put down after
dawn, through `CityMap.obstruction_version`); a tick is a lookup at her tile, and asking where the
arrow points never moves anything. There is no cap and no straight-line fallback: from a tile with
no walk to any target the arrow keeps its target.

**Measured** (`tests/probes/plush_moose_arrow_cost.gd`, three seeds, ten positions each, a debug
build on a shared machine):

| day (targets) | the old 2Hz walk | a tick now | a sweep slice | positions with no walking length, before → now |
|--|--|--|--|--|
| 6 (2) | mean 10.7, worst 24.6ms | 0.04 / 0.06ms | 0.73 / 1.1ms | 1/30 → 0/30 |
| 11 (every live mast) | 13.5 / 24.6ms (two masts) | 0.43 / 0.62ms | 0.79 / 1.8ms | 7/30 → 0/30 |
| 13 (14–20) | 5.7 / 14.8ms | 0.14 / 0.19ms | 0.75 / 1.4ms | 0/30 → 0/30 |

**Chosen while building, open to overturn:**

- The switching margin is a distance (four tiles of walking closer), not a time hold; the first
  choice of a task has no hold.
- A step costs one tile whatever the ground: the game has no weighted path cost.
- A man shouting is measured to the stretch of sidewalk he paces; the arrow's tip follows the man.
- Days 6 and 13 choose among the live (streamed-in) instances of the row; mobile rows and a door's own
  bodies do not block the walk.
- Until the first sweep finishes (at most about 38 frames) the arrow stays on the target the
  contact was placed on.

Not verified: a picture of day 11 with several masts (a scene cannot yet author a mast the day
counts); the day-11 test covers several masts answering.
