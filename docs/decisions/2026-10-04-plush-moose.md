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

## Completion review fixes and evidence · 2026-10-08

The day-11 regression leaves both the contact and the arrow at the near mast, places her
beside a third eligible live mast, and drives the ordinary process/contact callbacks. It
checks that following her between masts moves the task to the one she touches, completes
the task and silences and scars that mast. Day 13's protest cue reads the same destination
as the red arrow, so both point at the selected roadblock. The accessor remains read-only.
The day-11, palette, narrative, probe and human-review wording now describes those rules;
the task-6 and task-13 scene table claims only that the target is arrowed at its assertion,
without claiming that the first closest-path sweep has finished then. Debug output is removed.

The [new day-6 evidence](../evidence/plush-moose-path-vs-crow-2026-10-08/README.md) retains
a recipe and still with both candidates visible. At the measured stable retarget, the
unselected man is 434.10 pixels away in a straight line and 26 walking tiles away; the
selected man is 589.27 pixels away in a straight line and 23 walking tiles away. This is
the disagreement the earlier pictures did not establish. The picture shows the selection;
the production path-field measurement supports the route-length claim. A separate
multiple-mast picture is not required by the final review; the live task regression covers
that behavior.

The GitHub update at a0be789d merges main 7f3f26dc automatically into a492b983. Main's
warning placement, whole-camera visibility and persistent Run controls remain alongside
the arrow selection. The author checks resistance director/contact behavior, the shared UI
and narrative rules after that merge. Import/boot, lint, the focused resistance and protest
suites, the companion recipe assertions and whitespace checks pass. Full-suite CI and an
independent review remain the merge gates.

The independent review then runs the exact live-mast test at b0dfe0bc: nine checks pass;
suppressing only the production `_follow_her_between_masts()` call fails four, covering
handoff, completion, silencing and the scar. Its clean measurement on the final day-6 recipe
selects the man 23 walking tiles away over the one 26 tiles away, even though the latter is
closer by crow distance. At the first retarget the pacing man's crow distance is 424.556px;
the different sampling moment explains the difference from the author's 434.10px value.
The [compact reproduction package](../evidence/plush-moose-path-vs-crow-2026-10-08/independent-review/README.md)
retains the drivers, mutation, measurement patch and results. Focused arrow/protest checks
and the final uninstrumented recipe pass without engine diagnostics.
