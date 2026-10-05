# plush-moose — Every task has a red arrow, on the closest by walking distance · 2026-10-05

Filed from [busy-quail](../playtests/2026-10-04-busy-quail.md) (inbox #562): "task day 13 has a bug
there is no red arrow?", then "yeah let's just always do arrows"; and on day 11's mast (inbox #561):
"let it point to the closest one first. the red arrow (in general) might switch if another closest
one comes close ... closest here always means path closeness not crow closeness".

**Built.** Every task draws the red arrow, day 6's man shouting and day 13's roadblock included.
Where more than one place answers a task — every live man shouting on day 6, every live roadblock on
day 13, and on day 11 the two masts the task names, the one near the mark and the one rigged onto
her route — the arrow points at the one closest by walking distance and switches as another
becomes closer. A task with one place keeps its arrow on it. On day 11 the task's contact follows the
arrow, so touching either of the two masts completes it; no other mast answers.

Walking distance is a breadth-first walk over the director's own walkable ground, four-connected,
over the tiles the day's obstruction leaves open (the ground every task placement is proved
reachable over), one tile per step; a target counts as reached within its touch reach and a tile.
It runs twice a second (`ResistanceDirector.ARROW_RETARGET_SECONDS`), stops four tiles past the first
target it reaches and gives up at 8000 tiles (`ARROW_SEARCH_TILES`), falling back then to the
straight-line nearest. The arrow keeps its target unless another is at least four tiles of walking
closer (`ARROW_HOLD_TILES`).

**Chosen while building, open to overturn:**

- The hold before switching is a distance margin (four tiles of walking), not a time hold.
- A step costs one tile whatever the ground: the game has no weighted path cost.
- With no walk reaching any target, the arrow points at the straight-line nearest.
- Days 6 and 13 choose among the instances of the row that are live (streamed in) around her.

Not measured: the walk's cost per call on a real day, and the switching in a played run (the tests
and one still of day 13's arrow cover it).
