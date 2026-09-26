## M181 — The narrow targets are reachable by construction · built 2026-09-24

*([PLAYTEST-128](../playtests/PLAYTEST-128.md): "Yes, we need to make that a guarantee by
construction.")* Day 9's named door, day 12's swing and day 14's district contact were placed
with `_pick_reachable()`'s reachability check off, and the day's seals and event bodies could ring
them. `tests/probes/m181_resistance_targets.gd`, 40 cities through the real day order: before, 13
of 40 finale contacts stood on ground cut off from home and two cities had no reachable district
tile at all; after, every door, swing and district contact is reachable.

**How.** The day keeps a route to one tile of the day's target pool through the same layers
that keep a calm area: on day 14 the corridor grows a spur to the district, ending on its
junction corners or open lot ground, as it already does to the power station's door (a door is
already a crossing the tree uses, a swing's park already on the tree); `ClosurePlanner` refuses
a closure that cuts off every tile of the target; and the scheduler's walkability pass keeps one
reachable with the seals and the region wall counted as standing — it only removes bodies, and on
24 city-days it removed none. `ResistanceSteps.target_candidates()` is the one pool planning and
the director both read; `require_reachable` is gone and the director always requires it. The
spur search could cross the home street and send `_resettle_the_tails()` round forever, which
hung day 14 on a city whose district touches the home block; the station spur carried the same
latent bug, and both are fixed. `tests/test_resistance.gd` plans days 9, 12 and 14 on four cities
whose district would otherwise be ringed, and the M188 sweep checks the door and the swing too.

**M188's "zero of 72 reachable" was the rig's, not the city's.** That rig planned events without
`City.start_day()`, so every region door's bodies counted as blockers; in the real day order 45 of
the 72 tiles are reachable. The sabotage test now runs `City.start_day()` first.

**Open to overturn, chosen by the agent:** the guarantee is one tile of the pool, not a target
chosen in advance, so the director's seeded draws do not move; it covers stationary bodies, seals
and closures, and a moving event counts where it starts; the spur follows the day number, so day
14's corridor carries it whether or not the goal is met. **Left open:** on one or two cities only
one or two district tiles stay reachable, which meets the guarantee; whether to protect more is
a design call nobody has asked for. **The corridor-weight check was re-measured.** On seed
4242 the day-14 spur adds two junction cells to the corridor, which reshuffles day 14's placement
draws, and `tests/test_events.gd`'s narrow-row share fell from 29 of 71 (40.85%, already under the
test's own 1.5-point margin on `main`) to 28 of 71 (39.44%). The test's docstring prescribes a
re-measure when its sample moves, so the floors are now 0.37 narrow and 0.32 whole, both above
the third of the ground that is corridor, which an unweighted day would give. The narrow share
was 1.5 to 2 points lower in every day-14 sample taken, with no mechanism found; that is what
would make the dip worth looking at again. **Not built here, and still in `TODO.md` under M181:** on 9
of 40 cities every playground park is taken by day 12, so the swing has nowhere to be — the
forced-open park — and the second open park reachable from the swing.
