# feathery-hare — The chalk mark stands one tile into its alley · 2026-10-11

[azure-puffin](../playtests/2026-10-10-azure-puffin.md), point 3, inbox #664:

> let's move the chalk mark one tile into the alley so I actually have to enter the alley to
> activate it

**The mouth is chosen as before; the mark stands one tile further in.** The player's earlier "Mouth
only (Recommended)" ([quiet-yak](../playtests/2026-10-03-quiet-yak.md)) still decides which alley end
a mark belongs to; `ResistanceDirector.mark_tile_of(mouth)` puts the mark one step in from it along the
alley's long axis, and where a courtyard passage is one tile long, on the courtyard tile just past it
(proposed at filing, open to the player's correction). Its centre is 48px in and `ContactPoint.REACH`
is 36px, so she reads it only with her centre at least 12px inside the alley; standing on the
pavement at the mouth, or with her centre on the street edge, she does not. Reachability
([downy-otter](2026-09-27-downy-otter.md)), legal ground, relocation and the avoidance of a run's
used alleys are asked of the mark's own tile (`_mark_tiles()`, `is_mark_tile()`).

**The mark's guard moves in with it**, by the tile the mark stands in (`_depth_of_the_mark()`, capped
at one tile), so he stands as far from the mark as before and
[M213](2026-09-26-M213.md)'s 176px floor and quiet-yak's "Two-thirds wins" hold as they did;
`_alley_ends()` reads a courtyard tile beside a passage mouth, so a courtyard mark's guard still
stands at the court's inner end.

**The task scenes follow.** The nine scene recipes' pinned marks (`scene-recipes/task-06` to
`task-13`, `11-two-masts` included) stand one tile in, each walk turning into the alley and out, and
the ticks follow the detour; day 7's walk takes a short extra leg south to reach its van, day 10's
`near` bound goes from 480 to 520, and day 13's ticks are retuned since its task completes sooner.
`docs/MECHANICS.md`, `docs/SCENE_RECIPES.md` and `docs/NARRATIVE.md` say where the mark stands.

`tests/test_scene_recipe_task.gd` holds that a walk from inside the alley reads the mark and one from
the pavement at the mouth does not, that the guard is as far from a mark one tile in as from one on
the mouth, and that a pin on the mouth or mid-alley is refused; `tests/test_resistance.gd` sweeps the
new tile. Stills: [chalk-in-alley-2026-10-11](../evidence/chalk-in-alley-2026-10-11/), the mark seen
from the street and her reading it inside the alley.

*Chosen where the entry was silent, open to overturn:* the guard's extra offset is capped at one tile
so other callers' points behave as before; an older save's used alleys are recorded by their mouth
tiles, so in that run those alleys are not avoided once; the scenes' targets and tick bounds as above.
