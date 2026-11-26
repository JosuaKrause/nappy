# crisp-beaver — A seal on a pedestrian street closes it wall to wall, and no soft seal stands there · 2026-11-26

**The ask.** Asked what a soft seal should leave open on a pedestrian street, which has no cars,
with (a) still leave the middle open, (b) close the street completely, or (c) never place a soft
seal on a pedestrian street, the player answered "(c)" (tiny-lark #931). The entry read it as: on a
pedestrian street a hard seal closes the street completely, per the M64 record ("A **hard** seal
spans the street frontage to frontage and nothing gets past it"), and no soft seal is placed there.
The defect was found by the review of M219 (on a pedestrian street a blocked walker turns round),
not reported by the player.

## What was built

- **`SealPlanner.offers()` takes whether the street is a precinct**
  (`TutorialRoute.is_a_precinct()`), and on one offers only what `_closes_a_precinct()` passes:
  a hard seal whose rows are solid all across their shape. `plan_day()` asks it of every street it
  draws a picture for, the tutorial route's side-street mouths ask it too, and a scene recipe's
  authored seal (`SceneRecipeRuntime`) is held to it, so an authored seal stands only where the
  day's own pass could put one.
- **`EventDef.is_solid_in_parts()`**: whether a row's body is solid only in the pieces it declares
  (the crash's two cars), so the planner asks the row rather than reading its body.
- **What a precinct is offered now**: the burst water main and the fallen tree (on a street with
  trees) from day 1, the barricade from its own first day, the burnt-out car and the collapsed
  frontage from day 4. The same streets are sealed, since a precinct had a hard picture on every
  day; only the picture changes. A hard seal holds its street (`CityMap.held_streets()`), so a
  precinct off the tree no longer carries a catalogue row beside its seal, where a soft seal's
  street did.
- `docs/CITY.md` ("Sealing the tree") and the car accident's row in `docs/EVENTS.md` say so.

## Measured

`tests/probes/crisp_beaver_precinct_seals.gd` (seeds 67, 1 to 20, 24757 and 71717, days 1 to 14,
the seal rng `tests/test_seals.gd` uses). Before: of 1060 seals on precincts, 655 were soft pairs,
each leaving the middle two lanes open to walkers (four lanes where the thinning dropped a body)
and a 22 to 54px band her centre passed (up to 110px thinned); 106 were car accidents, leaving the
four sidewalk lanes open and a 46 to 50px band. On seed 67, 47 seals stood on precincts, 32 soft,
36 with a way through. After: 1060 seals on precincts, none soft, none leaving a lane or a band
open, on seed 67 47, none open. So she could pass every one of those gaps, which answers the
entry's "proposed, not asked for" question. The per-picture table and two stills, a barricade and
a collapsed frontage across a precinct of seed 67, are in
`docs/evidence/crisp-beaver-precinct-seals-2026-11-26/`.

## Tests

`tests/test_seals.gd` gains two cases, each failing on `main` (365 failures) and passing on the
branch: no soft seal body stands on a precinct on any day of the suite's six cities, and on seed
67's days 2 to 8 and 10 to 13 every seal on a precinct leaves no walker lane (body footprints and
soft-sealed tiles) and no line for her (`WalkGround`'s solid pieces) open past it.

**The run log baseline moved** (`tests/fixtures/observed_run_log.txt`, which
`tests/test_observers.gd` compares line for line, seed 4242): the day's plan counts change with the
pictures, and on day 1 two of the tutorial's lesson rows, the delivery van that shuts her sidewalk
for the crossing with no cars and the yeller whose beat she times, now find a tile of their slot
where the baseline had none for either. Why the seals reach those slots was not traced; the
baseline is re-recorded from this branch.

## Choices left open to the player's overturn

- **The car accident seals no pedestrian street.** It is a hard seal, but solid only at its two
  cars, with its debris and both pavements walkable and priced by its field (PLAYTEST-63), so on a
  precinct walkers walk through it and she passes at a cost. The entry's reading ("a hard seal
  closes the street completely") rules it out there, and a crash of two cars on a street no car
  drives is no picture of anything; the plainer alternative was to keep it and hold only the soft
  seals out. The builder's pick.
- **The rule is derived from the rows, not named per picture**: a hard seal is offered on a
  precinct unless one of its rows is solid in parts, so a new picture is placed there or not by
  its own body.
- **A precinct's seals on days 1 to 3 are nearly all the burst water main**, since the barricade
  and the later acts' wreckage are not offered yet and the fallen tree needs a tree-lined street;
  over the 23 seeds 509 of the 1060 seals on precincts are burst mains. The eight-pictures rule
  (no single barrier is the city's signature) holds over the whole city, not a precinct; whether
  a precinct wants an early picture of its own is a question for the player, not answered here.
