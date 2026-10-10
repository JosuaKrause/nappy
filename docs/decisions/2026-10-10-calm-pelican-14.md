# calm-pelican — Day 13's guard follows her to the roadblock she approaches, and the day's roadblock is placed by the day's rules · 2026-10-10


From the re-review of PR #588 (plush-moose, every task has a red arrow, on the closest target by
walking distance): [feathery-badger](2026-10-04-feathery-badger.md) kept a guard around day 13's
seeded roadblock, placed once and never moved, while the arrow chooses among every live roadblock,
so it could point her at one with no guard. The player (inbox #650 in
[mossy-beaver](../playtests/2026-10-10-mossy-beaver.md)): "move the task's waiting guard to the
roadblock the player approaches"; and (inbox #651 in
[lilac-marmot](../playtests/2026-10-10-lilac-marmot.md)):

> Let's point it to any roadblock and just move the guard always to any roadblock she approaches. We can move the guard around offscreen as much as we want. If we need to move multiple times so be it

**The guard follows her target.** Built in PR #659: on each of the arrow's choices (twice a
second), when the arrow points at a different roadblock from the one the guard stands over,
`ResistanceDirector._move_the_task_guard_to_her_target()` re-places him (`_roadblock_guard_spot()`, which
places the task's own guard too) on a tile in the band round that roadblock, 136px to 250px from
its body, outside his 140px trigger range of her and with a clear line to the roadblock's body
(the line his noticing uses since calm-pelican-12), alleys first, on a random stream of its own so
nothing else in the day shifts, however often she changes target. When the whole band is in her
view he goes to the ring just past it, out to 448px (`TASK_GUARD_FARTHEST`), and into the band once
a spot in it is out of view; a guard already in the next roadblock's band with a clear line to it
stays. The move is tried on the arrow's half-second clock and on the frame the arrow changes. The arrow
keeps plush-moose's closest-by-walking choice among every live roadblock; "the roadblock she
approaches" is the arrow's pick. *The filer's proposal, open to the player's alternative:* he
moves only while both where he stands and where he goes are out of her view, and otherwise waits
for the next choice, so he never pops in or out on screen; the alternative is moving him as soon as
he alone is off screen. *Chosen where the design was silent, open to overturn:* a guard who has
noticed her, or whose chase is over, is not moved. Walking from the mark to each of the four nearest
roadblocks in 12 cities with the camera leading her (`tests/probes/calm_pelican_day13_guard_walk.gd`),
he was in the band with a clear line at 45 of 45 arrivals, where the first build had 34 (9 over
the roadblock with no line, 2 at another roadblock 417px away). **What is left, and the player's to
judge:** he never moves while she can see him, so if he stays in view from the moment she turns
toward another roadblock until she reaches it, he is still at the old one; none of the probe's
walks did that, and only moving him in her view would close it. `tests/test_day13_guard.gd` holds
that he ends at the roadblock she approaches with a clear line to it, takes the ring and then the
band, and never moves while either end is in view; removing the clear-line rule or either view
check fails it.

**The day's own roadblock is placed by the day's rules, close by.** The player: "yeah let's not
rig the roadblock let's place one properly and guide to that -- just make sure it's closeby"
(inbox #650). *Read as, open to correction:* placed under every placement rule a planned row is,
still close to where she reads the mark. The road and crossing tiles where her paths first reach
the 576px circle round the mark (`ResistanceDirector.NEAR_THE_MARK`) are offered to the scheduler's
own acceptance through `WalkSiting.near_her()` (open ground, never a wall on a route, spacing, door
clearance, junctions and sidewalks, and never cutting her off from home or a calm area), and
`EventManager.queue_a_task_row()` adds it to the day's plan. *Open to overturn, the reading of
"closeby":* where every tile on the circle is refused, the ground half a block and then a whole
block further out is offered, and the old live spawn on the circle is the last fallback; the
circle alone found a site in only 6 of 12 cities. The task's roadblock keeps the plain catalogue
row, so its own soldiers do not hunt her at high heat. The one ground scan runs at dawn on day 13,
so reading the mark costs about 43ms on average, 155ms at worst in a debug build on a shared
machine, where it was 5ms.

Measured by `tests/probes/calm_pelican_day13_roadblock.gd` over 12 seeds, before and after, each
build starting with no alley remembered as read: placed under the day's rules in 0 and then 10 of
12 (seeds 99 and 314159 fall back to the edge spawn); its distance from the mark 577/588/601px and
then 584/598/859px (min, median, max); the arrow on the task's own roadblock from where she read
the mark in 10 and then 11 of 12, and at points on her way to it in 26 of 31 and then 27 of 29.
`tests/test_day13_guard.gd` holds over 4 cities that it joins the day's plan, stands between the
576px circle and the widest ring, out of her view, blocks a walker, and leaves her way home and to
a calm area open. A city
has 1 to 20 live roadblocks. The still of the guard moved beside the roadblock she approaches is in
[day13-guard-2026-10-10](../evidence/day13-guard-2026-10-10/README.md).

**The `TASK_ARROW` comment in `src/palette.gd`** is reflowed so no word stands alone on a line.
