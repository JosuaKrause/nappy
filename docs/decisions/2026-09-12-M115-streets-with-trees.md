## M115 — Streets with trees · built 2026-09-12

*(2026-09-11, playtest 57: "can we make only some streets have trees? it should be continuous
segments of 3/4/5 blocks randomly placed on the map in both directions. fallen trees should only
be possible on streets with trees and one spot should be empty (the fallen tree's spot)". Then
2026-09-12, playtest 58: "trees should only be allowed to be placed if there is no other blocking
event (or conversely due to map consistency) events can only be placed where no trees are (except
for the fallen tree which must empty out one tree lot). so trees must be quite rare to be able to
still place vans restaurants etc. also, trees make it harder to spot events like yeller, dog
walker, etc. so we need to be careful about how many we are placing".)* Before this, every
pavement fronted by housing or shops carried pits at a fixed spacing, a fallen tree merely
preferred a street with trees, and nothing stopped an event standing in a tree. Four agent
commits on `feature/streets-with-trees`, reviewed here.

**Runs, and few of them.** `StreetTrees.runs()` picks `Tuning.STREET_TREE_RUNS` (6) straight runs
of three to five consecutive blocks along one street line, either axis, from the city seed at
generation; a run is rejected whole rather than trimmed when any of its streets is absent, not
ordinary, not fronting housing or shops, or already taken, bounded at 240 tries so a hostile seed
ends with fewer runs. Runs never overlap. Planting walks the whole run, skipping junctions, so
`STREET_TREE_PIT_SPACING` (896px, two lot-lengths read as block plus street) crosses block
boundaries; under the old per-segment loop a wide spacing would have changed almost nothing on a
256px segment. **Measured** with `tests/probes/m115_tree_rarity.gd` over thirty seeds: about six
per cent of ordinary streets are tree-lined, the worst seed seven, about six runs and
twenty-seven pits in a city of some two hundred and thirty ordinary streets; the entry's quarter
is asserted as a ceiling, `STREET_TREE_MAX_LINED_FRACTION`. All four numbers are pinned and open
to overturn, six runs deliberately at the rare end.

**A tree and an event never share ground.** `EventScheduler._open_ground_for` gains a fifth
outright refusal beside closed, doorstep, held and home-block ground: any tile a standing tree's
own `GroundShape` footprint covers, the point the shadow reads, not merely the trunk tile; cached
once per day. **The seals took their own path**: `SealPlanner.plan_day` puts a body on every
off-tree street regardless of what the catalogue would be offered and asks none of the scheduler's
placement questions, so the refusal went into `SealPlanner._seal_along_tile`, which walks out from
the street's midpoint to the nearest cross-section with no pit in it; soft pairs carry that tile
into the thinning pass so `soft_sealed_tiles` marks where the bodies stand. `_hard_positions` took
an optional along-tile, default the midpoint, so the edge-to-edge tests are untouched. No sealing
guarantee was made hard: a street is eight tiles and the spacing allows at most one pit per kerb
on it, so a clear cross-section always exists and the midpoint fallback is never reached. The one
test where the scheduler's rule and the seal planner's rule must agree asks every catalogue
placement and every seal body over full days and seeds whether it stands in a tree.

**A fallen tree only where a tree stood.** `ClosurePlanner._pick_kind` drops `FALLEN_TREE` from
the roll on a bare street, a gate rather than a weight, and `SealPlanner._pick_candidate` drops
`fallen_tree_seal` the same way. **Chosen where the design was silent, and the most overturnable
choice here**: `_FALLEN_TREE_STREET_BIAS` (6.0) survives on top of the gate, because tree-lined
streets are six per cent of the city and a day closes one to four streets, so at the plain weight
the picture would be near-unreachable. Both planners take the pit nearest the closure's or seal's
own centre through `StreetTrees.pit_nearest()`, and the seal stands on that pit so picture and gap
coincide. The day's emptied pits are two small sets on `CityMap`, handed over whole each day so
neither pass accumulates yesterday and their order does not matter; `StreetTrees.planted()` is
never mutated; `City` keys its tree props by pit and `refresh_street_trees()` hides the emptied
ones. **One line outside the agent's fence**: `main.gd` calls that refresh after the seals are
planned, since seals are planned after `City.start_day` and without it a seal's pit kept its tree
until the next day; the alternatives were reordering the day, a per-frame poll or a signal, and
the line was the smallest honest fix. **An emptied pit draws nothing at all**, pit decal included,
as the entry specified; drawing the bare pit without its tree is one branch in `Prop._draw()` and
would say more directly that the tree here is the one in the road, so it is in `REVIEW.md`.
Tests sweep twelve seeds by fourteen days for the gate and the empty pit, and a day whose closures
are all on bare streets still shuts the act's full quota. Evidence in
`docs/evidence/archive/session-captures/2026-09-12/`: an overview on seed 4229 establishing the
rarity, and a fallen tree at that seed's day-one closure with standing trees beside it; the
emptied pit is out of that frame, since the spawn target stands at the closure's mouth and the pit
is nearest the street's middle, so it is held by assertion. `docs/GRAPHICS.md`'s street tree row
says where the pits are now.
