## M100 — Small, real, and nobody's · three defects built 2026-09-11, by construction

Three of M100's defect items and the proof they imply, on `feature/placement-by-construction`,
four commits from three agents — the first wrote it, the second found the seeding fault below, the
third verified and split it — reviewed here. All three are built where the ground is chosen and
never as a pass afterwards, which is `CLAUDE.md`'s own rule for every guarantee: **a candidate is
refused before the roll, never repaired after it.**

**Events spawn inside a fully blocked street** *(2026-09-09, playtest 49: "a definite bug is that
inside fully blocked streets (eg tree) restaurants etc can still spawn which is silly"; 2026-09-10,
playtest 55: "the barriers are oddly placed. why would they be in front of a checkpoint? … there
is no way to actually get to the checkpoint here" — "the checkpoint suggests that there was a
path planned through so there shouldn't be a barrier … this shouldn't happen by construction").*
`CityMap.held_segments` is the day's list of street segments no catalogue row may be offered,
keyed by segment and filled by `EventManager.start_day` before `EventScheduler.build_day` rolls a
single candidate: every closure's segment, every **hard** seal's segment — `SealPlanner.plan_day`
gained a `held` out-parameter and marks each hard seal as it places it, which is why it now runs
*before* `build_day` rather than after; it is a pure function of the map, the day, the tree and its
own RNG stream, so the order changes which seals a day gets not at all — every region wall and door
segment, and every segment bordering the home block. `EventScheduler._open_ground_for` refuses a
tile on a held segment beside its existing closed-tile, doorstep and kerb tests. **A soft seal is
deliberately not held**: its carriageway is still walkable and a café on it is the price of that
route. The day's budget is unchanged, so a refused tile means the row lands elsewhere, not nowhere.
`tests/test_events.gd` plans four seeds over five days, including the region days, and asserts
nothing the catalogue placed stands on a closed, held or home-block tile, with the closure count,
the boundary segments, the checkpoint bodies and the seal placements asserted against a measured
baseline so a regression reads as construction changing rather than the test drifting.

**Two things here are the agents' and open to overturn.** The queue entry said a *blocking* row
is never offered a door segment; the build refuses **every** row there, a café and a chatting
mother included, because `is_held_at` is asked before the row's kind is — narrowing it to rows
with an obstruction radius is a small change if the door streets now read as empty. And the count
a day places was not measured before and after: the tests hold that days still place events and
that none stands on held ground, not that a day places as many as it did. A row whose whole
candidate pool sits on held ground is skipped for that day; the probe seeds are where to look.

**Nothing on the home block — the whole block, as playtest 11 asked** *(playtest 11, finding 1:
"events/hazards should not spawn on the home block"; 2026-09-10, playtest 55: "if there spawns an
alley at the home (which shouldn't happen) the robber spawns too leading to a spawn kill every
time … there was a bug report a while back -- where did it go").* What M43 had built for finding 1
was the one street outside the front door; the block itself was narrowed away with nobody saying
so, and was reopened from the old finding. Two halves. `CityGenerator._build_block` skips the
through-alley for the home block, so `_home_rect` lost its sideways slide with nothing left to
slide off; `tests/test_generator.gd` asserts no alley tile on the block over sixty seeds and that
alleys still exist elsewhere. And the block's own ground is refused everywhere a thing is placed:
`CityMap.is_on_home_block` in the scheduler's candidate pass, and in `ResistanceDirector`'s
initial roll, its guard draw and the M78 relocation that follows a never-seen mark toward her — the
run that showed it (seed 291862120, day 7) had the mark offered far away and moved at second zero
onto the alley two tiles from the doorstep, guard and all.

**The seeding fault the second agent found, and the measurement it moved.** The first build
wrote the exemption as `block != home_block() and rng.randf() < chance`, which short-circuits
and skips the draw for the home block — so every block built after it in row-major order, about
half the lattice, rolled its alley off a shifted stream, and the same seed produced a different
city. The corridor-share check on seed 4242 fell from 64% to 44% and caught it. The roll is now
drawn for every block and only its result discarded on the home block, so a seed's other blocks
are exactly what they were. The held-ground test's baseline had been measured against the faulty
generator; reverting the fix reproduced the old numbers and the failing corridor test together,
which is the evidence, and the baseline was re-measured on the corrected city (48 closures held;
441→456 boundary segments, 384→396 checkpoint bodies, 5119→5320 seal placements).

**The guard robber is placed inside a building, where he is stuck for ever** *(2026-09-02: "the
robber can be placed inside buildings which makes him unable to move at all"; playtest 50: "the
robber is stuck inside the roof"; playtest 55: "the robber is inside the roof as usual").* Seed
2295276695, day 5 was the reproduction: the mark on an alley tile, the robber one tile south of it
in a building, his lethal radius with him. `ResistanceDirector._draw_guard_position` now draws the
bearing and the distance up to `TRAP_DRAW_LIMIT` (24) times, keeping the band and the half-circle
facing away from her, and rejects any point that is not walkable, is closed, is held, or is on the
home block. An `ALLEY` tile is kept the moment one is found, since the row's own placement is
`ALLEY`; any other walkable tile is kept as a fallback, because a 64px alley is narrow against a
band that reaches 176px out. **When all 24 draws land in walls, the mark goes out unguarded** and
the run log says so — *no trap is better than a trap in a wall* — which is the agents' choice and
open to overturn. Tests sweep every alley tile on six seeds three draws each and assert walkable,
unheld, off the block and outside every footprint; force a band to solid building and assert no
guard; and, the proof the three items imply, sweep six seeds over days 4–14 asserting no
`alley_robbery` — scheduled or guard — within lethal reach of the doorstep, then replay seed
291862120 day 7 through the real pipeline, relocation included.

**Verified** with `./tools/check.sh` and the events, generator, resistance, seals, city and crowd
suites, green on the final tree; `./tools/lint.sh` clean. **Unwalked**: a blocked street with
nothing standing in it, a checkpoint with a clear approach, a robber who is always on the ground,
and whether the door streets now read as too quiet.
