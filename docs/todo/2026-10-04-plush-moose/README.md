priority: now

# plush-moose — Every task has a red arrow to the closest by walking distance · filed 2026-10-04

[busy-quail](../../playtests/2026-10-04-busy-quail.md) files inbox #562. Playing the day-13 scene:

> task day 13 has a bug there is no red arrow?

Told the arrow is absent by design for the "any instance" tasks (day 6's man shouting, day 13's
roadblock), the player chose "Arrow on days 6 and 13", then:

> yeah let's just always do arrows

And on how the arrow chooses, about day 11's mast (inbox #561, filed with olive-badger in PR #565):
"let it point to the closest one first. the red arrow (in general) might switch if another closest one
comes close (eg if the player chooses to ignore the task the red arrow keeps jumping to the closest ones
on the other route) -- closest here always means path closeness not crow closeness".

**Asked for:** every task has a red arrow, the "any instance" ones included; where more than one
target answers, it points at the closest by walking distance and switches as another becomes closer
along her path.

**What exists.** `docs/NARRATIVE.md`'s task table gives each day's arrow ("red", or "any instance" for
days 6 and 13, which draw none); the arrow points at one chosen target. Day 11's arrow points at the
mast near the mark.
