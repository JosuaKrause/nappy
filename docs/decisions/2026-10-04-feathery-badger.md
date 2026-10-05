# feathery-badger — Every guarded target sends the robber from off screen · 2026-10-04 · not from an entry

*([grassy-goose](../playtests/2026-10-04-grassy-goose.md), inbox #556: "the robber should spawn in
off-screen already pursuing when I touch the goal", then "Every guarded target (Recommended)".)* This
overturns the waiting robber at the burnt shell, the district door, a mast's foot, the swing and the
last night's front door, which [M137](2026-09-13-M137.md) had kept as "the smallest reading" of the
player's answer then.

**What was built, the first pass** (PR #570). `ResistanceDirector.keeps_a_waiting_guard()` is true only for a chalk
mark and the roadblock; `sets_a_trap_on_her()` is true for every other task but the neighbor's. Doing
the burnt shell (day 8), the district door (day 9, the moment the inspection lets her through), a
mast's foot (day 11), the swing (day 12) or the station's front door (day 14) sends
`robber_giving_chase` from off screen on the note's own rules: `Tuning.TRAP_ARRIVAL_DISTANCE` away, past
the line where the screen-edge badge rises, awake from his first frame; the van still sends
`van_guard_giving_chase`. Day 14 included, since the night is won by walking home after the sabotage.
`docs/NARRATIVE.md` and `docs/EVENTS.md` say so; `tests/test_resistance.gd` checks every target on its
real day.

**Measured, the first pass** (`tests/probes/grassy_goose_target_traps.gd`, 30 cities): at a door on a facade the
building stands above her, so the robber usually starts beside her along her own street (22 of 30 on
day 8, 24 of 30 on day 14), and from there walking straight away escapes him; for the note that
start comes up about a fifth of the time. 2 of 30 cities on days 8, 11 and 14 have no clear run from
any start, and one day-14 city had no legal start, so nobody came. Stills of day 8's robber arriving
are in `docs/evidence/grassy-goose-target-trap-arrives-2026-10-04/` (four replays, not one burst).

**Proposed, not asked for, and open to overturn (the first pass):** day 14 trapped; one row for
every target, his line still "They were waiting for you."; day 9's robber sent as she is let
through. His warning is the note's as it stands, the badge up from the moment he is placed just past
the view's edge; [M226](../todo/2026-09-26-M226/README.md), the pursuing dog keeps its day-3 timing
and the other warnings fit it, has not started, and is to make every off-screen warning at most one
second of badge with nothing placed, the trap robbers included (busy-quail, inbox #569).

## The review and the player's answers

*([plush-bunny](../playtests/2026-10-05-plush-bunny.md), inbox #571: on day 9, "(a)", under the boom
only the guard comes; "you shouldn't try to cheat it by going back in the hut -- that should be fatal
by the robber"; "yes, to your proposal about front doors", a start on the far side of the street, out
of view, with a walkable way to her, falling back to the note's rule where there is none.)* The
review of PR #570 found that day 9's walk under the raised boom sent the door's guard and the trap
robber in the same frame, and that a start's straight run could pass through the region wall or a
district door.

**What the fix built** (PR #570, at 9f717b7b):

- **Day 9 under the boom sends only the door's guard.** `EventManager.door_crossed` carries whether
  she was inspected; the crossing completes the task either way, and only an inspected crossing
  sends the trap robber.
- **A hut's hold does not end the robber's chase.** It already did not (M100's rule, "a hut's hold
  ends the door guard's chase", ends only the guard's); `tests/test_checkpoints.gd` now holds that
  the robber, 200px behind her as she steps into a hut, keeps after her and catches her while she is
  held.
- **A front door's robber starts across the street first**, at the burnt building and the station:
  the nearest tile below her, beyond her street, past the badge line and off screen, at least 311px
  (`Tuning.TRAP_ARRIVAL_DISTANCE`) out, from which his own chase walk reaches her in no more ground
  than the beside start would. Where no tile qualifies, the note's rule decides.
- **No start runs through the region wall or a district door.** A start whose straight run at her
  passes within a wall or door body's `obstructs_radius` is refused, the fallback included. Day 9's
  test and the probe measure from where she is released, 54px past the line on each side of the
  named gatehouse, rather than from the line.

**Measured** (`tests/probes/grassy_goose_target_traps.gd`, 30 cities, day 9 two cases per city, one
per side of the line; before is the same probe against 8b92282d). Where the start is, before → after:

| day | across the street | above/below, clear | beside, clear | no clear run | no legal start | no task |
|---|---|---|---|---|---|---|
| 8 | 0 → 27 | 6 → 0 | 22 → 2 | 2 → 1 | 0 | 0 |
| 9 | 0 | 39 → 36 | 21 → 20 | 0 → 2 | 0 → 2 | 0 |
| 11 | 0 | 23 | 4 | 2 | 0 | 1 |
| 12 | 0 | 30 | 0 | 0 | 0 | 0 |
| 14 | 0 → 23 | 3 → 0 | 24 → 6 | 2 → 0 | 1 | 0 |

How walking away fares, before → after ("a walk escapes": walking without running in at least one of
the four street directions outlasts his notice and chase, the robber row simulated against her frame
by frame):

| day | cases | his run crosses a district door's line | standing still caught | a walk escapes |
|---|---|---|---|---|
| 8 | 30 | 0 | 28 → 29 | 20 → 6 |
| 9 | 60 → 58 | 15 → 0 | 60 → 56 | 38 → 33 |
| 11 | 29 | 0 | 27 | 9 |
| 12 | 30 | 0 | 30 | 0 |
| 14 | 29 | 3 → 0 | 27 → 29 | 25 → 24 |

**Open, asked of the player on PR #570: day 14 barely moves.** The power station stands in the same
place in every city, and its nearest start across the street is a cross street about 144px to the
side and 320px down, about 351px out — past the 311px that `Tuning.TRAP_ARRIVAL_DISTANCE`'s own doc
gives as the walk-away ceiling — so walking away along the street still escapes him in 24 of 29
cities. The options put to the player: accept it, as the proposal was worded; cap the across start's
distance near 311px, which changes nothing alone since the beside start escapes too; or give the
station a start of its own. The coder would accept it until a played last night says it is too easy.
Neither change is built.

**Proposed, not asked for, and open to overturn (the fix):**

- The across start is the nearest qualifying tile centre, not a random draw; his walk may use at
  most `beside_distance()` (about 466px) of ground, so he is never later than the beside start.
- "A walkable way" is read as his own chase walk — straight at her, sliding along walls — rather
  than a path, since he cannot follow one; a step that keeps under a quarter of its length counts as
  stuck.
- The boundary refusal covers the region wall's bodies as well as the doors, though the review
  measured only the door. The fallback's straight line is checked, not its sliding walk, so in
  principle the fallback could still slide through.
- A front door is always read as facing south, so "across the street" is straight below her; every
  front in this city faces south.
