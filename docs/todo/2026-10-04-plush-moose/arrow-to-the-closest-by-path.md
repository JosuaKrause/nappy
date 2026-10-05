**Every task's red arrow points at the closest target by walking distance, and re-targets.** Days 6
and 13 get an arrow; on any day with more than one instance that completes the task (day 6's men
shouting, day 11's masts, day 13's roadblocks), the arrow points at the one closest along a walkable
path from her and switches when another becomes closer. *Proposed, not asked for:* the path distance
from the city's own pathing at a few hertz rather than every frame, and a short hold before switching
so it does not flicker between two near-equal targets. Update `docs/NARRATIVE.md`'s task table and
the busy-raven scenes' "no arrow" assertions; test a switch as she walks.
