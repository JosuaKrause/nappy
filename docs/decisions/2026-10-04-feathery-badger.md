# feathery-badger — Every guarded target sends the robber from off screen · 2026-10-04 · not from an entry

*([grassy-goose](../playtests/2026-10-04-grassy-goose.md), inbox #556: "the robber should spawn in
off-screen already pursuing when I touch the goal", then "Every guarded target (Recommended)".)* This
overturns the waiting robber at the burnt shell, the district door, a mast's foot, the swing and the
last night's front door, which [M137](2026-09-13-M137.md) had kept as "the smallest reading" of the
player's answer then.

**What was built** (PR #570). `ResistanceDirector.keeps_a_waiting_guard()` is true only for a chalk
mark and the roadblock; `sets_a_trap_on_her()` is true for every other task but the neighbor's. Doing
the burnt shell (day 8), the district door (day 9, the moment the inspection lets her through), a
mast's foot (day 11), the swing (day 12) or the station's front door (day 14) sends
`robber_giving_chase` from off screen on the note's own rules: `Tuning.TRAP_ARRIVAL_DISTANCE` away, past
the line where the screen-edge badge rises, awake from his first frame; the van still sends
`van_guard_giving_chase`. Day 14 included, since the night is won by walking home after the sabotage.
`docs/NARRATIVE.md` and `docs/EVENTS.md` say so; `tests/test_resistance.gd` checks every target on its
real day.

**Measured** (`tests/probes/grassy_goose_target_traps.gd`, 30 cities): at a door on a facade the
building stands above her, so the robber usually starts beside her along her own street (22 of 30 on
day 8, 24 of 30 on day 14), and from there walking straight away escapes him; for the note that
start comes up about a fifth of the time. 2 of 30 cities on days 8, 11 and 14 have no clear run from
any start, and one day-14 city had no legal start, so nobody came. Stills of day 8's robber arriving
are in `docs/evidence/grassy-goose-target-trap-arrives-2026-10-04/` (four replays, not one burst).

**Proposed, not asked for, and open to overturn:** day 14 trapped; one row for every target, his line
still "They were waiting for you."; day 9's robber sent as she is let through; the arrival rules
inherited unchanged, so a facade door's robber mostly comes along her street (a start of its own for
doors on a facade is the alternative, with its own fairness check). His warning timing is M226's, now
one second of badge before he is placed (inbox #569).
