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
(`TutorialRoute.lesson_streets()`); `DayPlanner` hands the route to the seals and to the dawn
(`DawnContext.use_the_walk_left_open()`), and `SitingMaker` to the sitings made while she walks,
so the day's rows keep one sidewalk of each lesson street open past their bodies, as on a street of
her routes (`OneSidewalkOpenRule`, its `kept` streets). The park itself is spoiled and off day 2's
tree as any used area is, so the same walk ends at the park spoiled. Leaving the streets unsealed
and unclosed only removes obstruction, so every reachability guarantee stays kept (the **city**
skill's monotonic exception); the seal planner's rolls for the other streets shift with the streets
it skips, so day 2's other seals are drawn afresh, under the same rule. The rows' rule is checked
before each placement is accepted, never repaired after.

**`OneSidewalkOpenRule` reads a body where it stands** (`BodyStance.of_plan()`), on every day and
every street it asks: a sidewalk body stands on the middle of its pavement band, half a tile across
from the lane tile the draw chose, and the rule read it at the lane tile. Read there, a café's tables
on one sidewalk and a leaf blower on the other passed the rule and shut the street where the game
stood them. `EventPlan.body_at()` and the other disc readings are unchanged.

## What was measured

`tests/probes/grassy_beaver_day_two.gd` plans day 2 after she settled in the tutorial park (the park
spent, the map repainted, the tree grown with no tutorial route, the closures, holds and seals with
the walk handed in, then the dawn's rows on what stands, every unit drawn) over seeds 1 to 30, on
2026-11-26. A street is **shut** when neither of its sidewalks can be walked junction to junction
past the bodies on it, each where it stands and with the ground its catch shuts
(`RouteSidewalkRule.closes_a_walked_sidewalk_band()` over `WalkGround.held_by()`), a closed street
included; a precinct's paved street has no sidewalk band and is never counted.

**The dead end at the doorstep**, a side street at the doorstep street's two junctions, day 1's walk
aside, shut by the seals or a closure (the player's "both sidewalks are blocked"):

| Measured (30 cities, all with a tutorial route) | Count |
|---|---|
| cities with at least one dead end at the doorstep | 29 |
| cities with none (seed 17) | 1 |
| fewest in a city | 0 |
| dead ends there in all | 48 |
| of them a road closure | 0 |

**The walk left open:**

| Measured | Count |
|---|---|
| cities whose tutorial park day 2's tree leaves off | 30 |
| lesson streets off day 2's tree (of 150) | 102 |
| of them sealed without the walk handed in | 102 |
| of them closed without the walk handed in | 2 |
| seals or closures on the walk with it handed in | 0 |
| rows standing on a lesson street | 81, in 29 cities |
| lesson streets shut, rows and seals together | 0 |
| streets of her routes shut, for comparison | 0 of 2105 |

The rows on the walk, by role and row: wall rows (café tables 27, leaf blower 13, construction 8,
market stall 8, delivery van 7, ice-cream van 6), friction rows (the yeller 7,
the chatting mother 4) and one pigeon flock. **Before the rows' rule was handed the walk**, the same
probe found 10 lesson streets shut in 9 cities; with the walk handed in but each body read at the
lane tile it was drawn on, 7 in 6 cities; read where it stands, none.

**The closures were not in the design.** It named the seal planner alone; the probe found day 2's one
closure on the walk in 2 of 30 cities, which would close the walk the design keeps open, so the
closure planner refuses those streets too. **Nor were the rows**: the design's pick, a path rather
than a route, lets rows stand on the walk, and the probe found pairs of them shutting it, which
would turn the walk into a dead end of its own, so the rows keep a sidewalk there.

## One city of thirty has no dead end at the doorstep

**Seed 17 is settled: no dead end is built for it.** The design's rule builds a dead end into day 2's
tree only if one is rare at the doorstep. 29 cities of 30 have one, which by the player's own
definition (curly-moose #819) is not rare, so the rule says build nothing. Seed 17 still has dead
ends on day 2, just not at its doorstep, and the player asked only for the lesson on day 2. Day 2's
tree there leaves no side street at those junctions off it, or each one it leaves off carries a seal
that keeps a sidewalk open (a thinned pair or a car accident).

**The rule's reading change, measured.** Reading a body where it stands (`BodyStance.of_plan()`)
instead of at its lane tile changed 8 of about 25,800 placements on days 1 to 14. All 8 are refusals
on her route's streets that the old reading wrongly let through.

## Choices and readings

- **A path, not a route** (the design's open point 1, its pick): day 1's own walk left unsealed. A
  branch of day 2's tree past the park would cost a forced waypoint in the tree's growth and make the
  walk a cost-free route, which the shut-park rule (PLAYTEST-140 8) argues against. So the walk has
  no kerb tint, and the off-route placement may stand rows on it as on any street off the tree,
  wall-role rows included, short of shutting both sidewalks of one of its streets. **Read as:** a
  cost on the walk is not against the player's words, since every street she walks carries the
  day's events; a walk shut by rows would be, since it would no longer be a path she is "free to go
  to" (minty-dolphin #834).
- **Which park is "the first day's"** (open point 2): **only the tutorial park's walk is left
  open.** The player tied the lesson to the close park and the same path: asked for "one park
  relatively close" on day 1 (curly-moose #819, its second point), they answered "that also teaches
  day two to go somewhere else (player can just retry the same path again and will find the park
  blocked)" (curly-moose #819, its third point), and then asked for "a path that touches the first
  day's park" (minty-dolphin #834), answering the board's question built on that sentence. **Read
  as:** the close park is the tutorial park day 1 is built around, and the same path is the
  tutorial route. Day 1's tree has other branches from the first block, so she can settle in another
  calm area on day 1; then nothing is left open on day 2, and that park may lie behind seals like any
  used area. Nothing records which park she settled in, so how often is unknown. Open to the
  player's correction.
- **What a dead end is**: a street with both sidewalks shut, the player's own words for the
  README's lesson (c): "c) they should turn around when there is a deadend / both sidewalks are
  blocked" (curly-moose #819). A thinned soft pair leaves one sidewalk open and a car accident's
  gaps can be walked at a cost, so neither is one.
- **The turn-back bubble** is the item thought-bubbles'.
