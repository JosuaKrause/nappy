# olive-badger — Day 7's van gets a second instance on her street, from a rigged bag of 2 · 2026-10-10


[Olive-koala](../playtests/2026-09-27-olive-koala.md), statement 2, asked for what she meets on
her route to be drawn from a marble bag; the forced cases each get a rigged bag, its size chosen
per case. Asked whether day 7's van, day 10's neighbor and day 13's roadblock each get a second,
route-drawn instance (inbox #586 in [olive-hedgehog](../playtests/2026-10-05-olive-hedgehog.md)):
"each olive badger rigged bag should be 2 or 3. use your own judgement on how soon the events
should happen"; then (inbox #650 in [mossy-beaver](../playtests/2026-10-10-mossy-beaver.md)):
"yeah let's not rig the roadblock let's place one properly and guide to that -- just make sure it's
closeby" and "day 10's neighbor had its own route anyway, no? I guess that leaves only the van?"
So the roadblock stays unrigged (its placement is
[calm-pelican-14](2026-10-10-calm-pelican-14.md)'s), and the neighbor gets none, read as "I guess
that leaves only the van?", open to correction.

**Day 7's van gets a second instance from a rigged bag of 2.** Built in PR #659:
`Tuning.VAN_WITHIN_THE_NEXT = 2` (the filer's judgement, which the player asked for, inside their
"2 or 3"; open to overturn) rigs the bag when she reads the mark, the same way day 6's man
shouting and day 11's second mast are (`MarbleBag.rig()` through `EventDirector.rig_her_route()`).
The van at the mark stays the task; whether the route van also counts for the task, as day 6's
second man shouting does, is open and not built.

**Where it stands: on the street she is walking, just out of her sight.** Sited as the route rows
are, on a tile of its ground on her branch of the day's routes, the van was never placed: a van
blocks a sidewalk by its size alone, and "the far side of a street answers a van, and nothing
answers a van on the side the route is drawn down". Placed across the street from her branch it
was placed, but never seen: `tests/probes/calm_pelican_day7_van_met.gd` walks 12 cities the way
`--route mark,task,calm,home` does and found it in her 640x360 view on 0 of 12 walks (9 never
placed, mostly with her off the day's routes or near a route's end; 3 placed 1250px to 1800px
ahead on a route she then left). So `ahead_of()` hands a wall by its fit alone to
`WalkSiting.ahead_on_her_street()`, which puts it on the street she is walking, ahead of her and
within five tiles of her line, all of it just past the edge of her view and inside the streaming
radius, nearest first, under the same placement rules; it is in the world at once and never moves.
Out of view means its whole drawing (it reaches 56.5px up from its feet) outside the 640x360 view
grown by the camera's lead and a tile (`WalkSiting.could_be_in_her_view()`): measured against her
position alone, 77 of 357 sites a route offers would have been drawn in view, and 2 of 10 placed
vans were. Its tile is on none of the day's routes and cuts none of them, and her way home stays
open; when her own line is off the day's routes it may stand on the line she walks, as it did on 4
of 10 placed walks; asked whether to keep that or prefer the far side of her street, the player:
"it's fine" ([2026-10-10-curly-gecko](../playtests/2026-10-10-curly-gecko.md)).
In view on 8 of 12 walks, 1s to 6s after it is placed; of the four misses, one never drew the
marble, one drew it seconds before home, where nothing is placed within 400px, and two turned off
the street first.
*Open to overturn:* "on her route" read as the street she is walking, the nearest spot first, and
placed inside the streaming radius so it exists at once. The marble comes 13s to 79s into her walk,
usually on the way home: the bag's own pacing, unchanged.

`tests/test_day7_van.gd` holds over 3 cities that the van's marble is among the next 2 handed out
after the mark, that one van is placed ahead of her on her street out of view and reachable on
foot, that it is in the world at once and does not move, that walking on brings it into view, and
that the task's van is unchanged; without the new siting no van is placed and it fails.
`docs/EVENTS.md`'s list of the rigs that stand names it. Day 7's package scene runs on seed 12,
on which the bag her reading the mark rigs sends the scene's cat before the van. The still of the
van coming into view is a scene recreating one probe walk with the van authored where the siting
put it, not a played day: [day13-guard-2026-10-10](../evidence/day13-guard-2026-10-10/README.md).

The same probe, each walk starting with no alley remembered as read, found day 6's second man
shouting, placed by the unchanged route-band rule, in her view on only 1 of the same 12 walks.
