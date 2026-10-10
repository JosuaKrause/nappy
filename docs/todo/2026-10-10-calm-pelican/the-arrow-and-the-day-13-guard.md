# Day 13's arrow and the task's waiting guard agree

**Medium · from the re-review of PR #588 (plush-moose, every task has a
red arrow, on the closest target by walking distance).** [Feathery-badger](../../decisions/2026-10-04-feathery-badger.md)
keeps a guard around day 13's seeded roadblock ("Every guarded target (Recommended)"), placed in
`ResistanceDirector._begin_step()` and never moved, but the arrow chooses among every live roadblock
(`_arrow_candidates()`; 14 to 20 on day 13 by the cost probe), so it can point her at one with no
guard. How often was not measured. The comment above `_follow_her_between_look_alikes()` still says
the guard "is not moved when she picks another".

**The guard moves to the roadblock she approaches** (inbox #650 in [mossy-beaver](../../playtests/2026-10-10-mossy-beaver.md)):
"move the task's waiting guard to the roadblock the player approaches". Move or re-place
`_task_guard` on the roadblock she is walking up to, always, and rewrite the comment above
`_follow_her_between_look_alikes()` to say so.

The player, asked which roadblock the arrow points at (inbox #651 in [lilac-marmot](../../playtests/2026-10-10-lilac-marmot.md)):

> Let's point it to any roadblock and just move the guard always to any roadblock she approaches. We can move the guard around offscreen as much as we want. If we need to move multiple times so be it

So the arrow keeps [plush-moose](../../decisions/2026-10-04-plush-moose.md)'s closest-by-walking
choice among every live roadblock, and the guard moves, off screen, to the roadblock she approaches
each time she changes target, however often.

*Proposed, not asked for:* a move is made only while both where the guard stands and where he goes
are out of her view, so he never pops in or out on screen. The case it leaves open, her turning
toward a roadblock in view while the guard is in view too, keeps him where he is until one of the
two leaves the view; the plainer alternative is moving him regardless once he is off screen, and
the player's "offscreen" does not choose between them.

**And the day's own roadblock is placed close by.** Asked whether day 13's roadblock gets a second,
route-drawn copy from a rigged bag (olive-badger's [the-other-forced-cases](../2026-09-27-olive-badger/the-other-forced-cases.md)),
the player: "yeah let's not rig the roadblock let's place one properly and guide to that -- just
make sure it's closeby". Today the task's roadblock is spawned live on the 576px circle
(`ResistanceDirector.NEAR_THE_MARK`) round where she read the mark. **Read as, open to
correction:** "properly" means it is placed under every placement rule a planned row is, still
close to where she reads the mark. The arrow chooses among every live roadblock, which the close
one normally is. Measure how often the arrow's pick is the task's own roadblock, with a probe like
`tests/probes/plush_moose_arrow_cost.gd`, and report it.

**Low, same area:** no picture shows day 11 with several masts answering, since a scene recipe
cannot give an authored loudspeaker a mast id; let a recipe give one a `mast_id` and capture day 11
with the arrow moving between two masts. And reflow the `TASK_ARROW` comment in `src/palette.gd`,
which leaves one word alone on a line.
