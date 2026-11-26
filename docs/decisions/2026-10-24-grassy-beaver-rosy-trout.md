# grassy-beaver — Day two's open walk and dead end · 2026-11-26

The item day-two (day 2 teaches the dead end and passes day 1's park; how day 1's car losses are
answered), built from the design's section for it (`.claude/briefs/designs/grassy-beaver.md`, not
committed). Its file is deleted; what it said that still holds is kept below.

## What the player said

The dead end on day 2: "dead end in day 2 sounds good as well" (curly-moose #819), answering the
proposal that turning back at a dead end (c) and timing traffic move to day 2. Timing: "yeller is
also a moving obstacle. -- also we can teach multiple things in a day if we make things progressively
harder. we could teach the yeller on day 1 but after the other lessons" (minty-dolphin #834), read as
the yeller teaching (e) on day 1 after the other lessons (`hand-crafted-day-one.md`), so day 2 has
no timing lesson of its own. The path past day 1's park: "spoiled actually teaches the lesson. there
should be a path that touches the first day's park so the player learns this lesson (since they are
free to go to it again)" (minty-dolphin #834).

**Traffic stays on every day**, apart from day 1's car-free start (`car-free-start.md`,
minty-dolphin #867). Asked "how do you plan to do traffic timing on day 2 only? you don't want any
traffic on day 1?" (curly-moose #819), and told the proposal was that day 1's route asks for no
lethal timing test, the player: "traffic crossings are already only where cars are stopped -- the
issue comes from players who just run across the street" (curly-moose #832). **Read as:** day 1's
losses to cars come from a player crossing the carriageway away from a crossing, so what day 1 lacks
is the lesson that a street is crossed at its crossings; the player's later guess at the commonest
day-1 mistake, "figuring out the controls and getting hit by a car" (minty-dolphin #867), adds the
car-free start. **The crossing bubble is day 1's**: asked on the board whether day 1 gets a thought
bubble for running across the street, pointing at the nearest crossing, the player: "yes"
(minty-dolphin #834); `car-free-start.md` has when it shows.

## What was built

**Day 1's walk to the tutorial park stays open on day 2**, where she settled in that park on day 1.
`DaySpec.leaves_the_tutorial_walk_open()` is true on day 2 alone; at dawn `City` asks the run's
calendar whether one of the blocks she settled in this act lies in the tutorial park
(`TutorialRoute.has_its_park_among()`, by the block's anchor, so any block of a calm zone counts)
and hands the route in the day's `DayStreets` (`tutorial_walk_left_open()`). `ClosurePlanner`
refuses the route's lesson streets as closure candidates and `SealPlanner` seals none of them
(`TutorialRoute.lesson_streets()`); `DayPlanner` hands the route to the seals. The park itself is
spoiled and off day 2's tree as any used area is, so the same walk ends at the park spoiled. Both
changes only leave streets open, so every reachability guarantee stays kept (the **city** skill's
monotonic exception); the seal planner's rolls for the other streets shift with the streets it skips,
so day 2's other seals are drawn afresh, under the same rule.

**The dead end is measured, not built.** The design's pick: measure over seeds how often a side street
at the doorstep street's junctions is off day 2's tree (and so sealed), and build one into the tree
only if that is rare. `tests/probes/grassy_beaver_day_two.gd` plans day 2 after she settled in the
tutorial park (the park spent, the map repainted, the tree grown with no tutorial route) over seeds 1
to 30, on 2026-11-26:

| Measured (30 cities, all with a tutorial route) | Count |
|---|---|
| cities with at least one sealed side street at the doorstep's junctions, day 1's walk aside | 30 |
| sealed side streets there in all | 54 |
| cities whose tutorial park day 2's tree leaves off | 30 |
| lesson streets off day 2's tree (of 150) | 102 |
| of them sealed without the walk handed in | 102 |
| of them closed without the walk handed in | 2 |
| seals or closures on the walk with it handed in | 0 |

So every city already has a dead end at her doorstep on day 2 and nothing is built for it. A sealed
street counts whatever its seal; one soft pair in a dozen or so is thinned to one body
(`SealPlanner.SEAL_THINNING_FRACTION`), which leaves one sidewalk open, and the probe does not tell
those apart.

**The closures were not in the design.** It named the seal planner alone; the probe found day 2's one
closure on the walk in 2 of 30 cities, which would close the walk the design keeps open, so the
closure planner refuses those streets too.

## Choices and readings

- **A path, not a route** (the design's open point 1, its pick): day 1's own walk left unsealed. A
  branch of day 2's tree past the park would cost a forced waypoint in the tree's growth and make the
  walk a cost-free route, which the shut-park rule (PLAYTEST-140 8) argues against. So the walk has
  no kerb tint, and the off-route placement may stand rows on it as on any street off the tree,
  wall-role rows included (`RowGround`, the lethal ones pulled two cells or more off a route).
  Nothing measured how often a row stands on the walk.
- **Which park is "the first day's"** (open point 2): read as the calm area she settled in on day 1
  (`SettledState`), the one spoiled. **Only the tutorial park's walk is left open.** The design says
  "the streets of day 1's tree branch to the calm area she settled in on day 1 (usually the tutorial
  route)"; day 1's tree is not kept past its day and cannot be grown again on day 2 (the park is off
  day 2's growable areas and the map is repainted), so where she settled in another calm area nothing
  is left open. Open to the player's correction.
- **What a dead end is**: a street sealed across both sidewalks, the orchestrator's reading of the
  README's lesson (c); curly-moose #819 lists the lesson and does not define the word.
- **The turn-back bubble** is the item thought-bubbles'.
