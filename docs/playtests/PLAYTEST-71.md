# Playtest 71 — 2026-09-13

Not a run: the player's answers to the questions the previous session left open, given in one
message after reading the handoff. Each answer is a decision; the item it decides is named.

## M129's three readings, decided

> "pacing rows -> time pass -- don't route around them. moving rows -> no block at all since the
> player can cross the street, wait, then come back without ever getting excited by it -- region
> doors -> no block at all since it costs by design"

The probe that measures *a path through the city never has to cost* asked how strictly three
kinds of row count as blocking a route. The answers, each against the reading the session
recommended:

- **A pacing row** (the yeller's beat) is passed by timing, not routed around: only the ground
  the beat never leaves free counts as blocked. *Recommended the whole beat · overturned.*
- **A moving row** (dog walker, patrol, van) never counts: she can cross, wait for it to pass and
  cross back without ever standing in its field. *Recommended its dawn position · overturned.*
- **A region door** never counts, since a door costs by design. *Recommended counting it ·
  overturned.*

The entry in `TODO.md`, M129, is rewritten against these; its first item is the re-run under
them, since no number has been taken with all three at once.

## A flock is scenery

> "flocks are basically free already -- don't count it as block, just count is scenery."

M131 had placed a flock off the day's routes because, under the cost rule, a 42-over-168px
field is a wall. Overturned: a flock is not a block for the probe and not a wall for the placer.
It may land on a route. *A placed flock stands off the route · overturned.* The item is under
M129 in `TODO.md`, because it is a reading of the same rule.

## The route lines

> "what number key is the route lint debug?"

`5` in a debug build, or `--layers 5` from the command line — the same row of keys as the field
(`1`), shadow (`2`), body (`3`) and readout (`4`) layers, `docs/TELEMETRY.md`, "The debug view".
The `REVIEW.md` item about the lines stays open; nobody has looked yet.

## The contact is whoever she hands the note to, and the trap comes to her

> "not the first yeller she reaches but the first yeller she interacts with. so the task is
> always solved by going to any yeller she notices. maybe spawn the robber in pursuing mode
> offscreen when she interacts with the yeller so it runs towards her from offscreen."

Two things. The contact: not decided by which yeller she first came near, but by which one she
hands the note to, so walking up to any yeller she has noticed completes the step. The code's
re-pointing already follows her from look-alike to look-alike, so what changes is the wording of
the rule and a test that leaving one yeller's reach and touching another still counts; that is
under M137 in `TODO.md`. The trap: instead of a robber seeded beside one particular yeller at
dawn — which M132 left guarding only that one — the robber spawns off screen, already pursuing,
at the moment she hands the note over, and runs at her. *The trap guards the seeded yeller
only · overturned.* Built as M137, the trap comes to her; the `REVIEW.md` item that asked
whether an unguarded contact reads as too cheap closes on this decision.

> "we need a version of the robber that is not frozen when spawned"

On being told that an alley robber stands waiting from the frame he spawns until he notices
her, so one spawned off screen would stand frozen unless woken by hand: the robber of the trap
is his own catalogue row, awake from its first frame by definition, not an alley robber with
his wait undone after the fact. Under M137 in `TODO.md`.
