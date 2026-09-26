## M175 — The cost table is generated, checked in, and checked by CI · built 2026-09-20

*(2026-09-20, [PLAYTEST-114](../playtests/PLAYTEST-114.md): "those numbers gets automatically
computed/updated but also checked in so we can see in the diff where the balance changed", and
of the first draft's columns at each row's own radii, "do computations at fixed distances across
all objects (each column represents the same distance for every object) -- that way we can get
the real impact and not the relative impact dependent on the object";
[PLAYTEST-115](../playtests/PLAYTEST-115.md): "the \"survey\" should happen automatically every
time and should show up in the commit diff if it changes".)* One agent, two commits on
`feature/m175-cost-table`, reviewed here. It is the second and third items of M175; the first,
rows that declare a cost tier, stays in `TODO.md` and waits on the player's tier values.

**What it is.** `tools/cost-table.sh` runs a headless scene over the real catalogue and the
real `Tuning` constants and writes `docs/COSTS.md`: each row's geometry and role, its net rate
while she walks a fixed distance away (0 to 550px, the last past the widest `outer_radius`, and
the tool fails if a row outgrows it), and the net points of one pass at fixed sideways offsets
(0 to 120px), awake and asleep, on quiet sidewalk. The constants it was computed under are
lines of the file, so a moved decay shows as itself and as every row it moved. `--check` is a
step of CI's `gates` job and names each row and column that differs, old and new. No balance
number moved in the pull request, and the pass cells for `homeless_yeller`, `dog_walker` and
`loose_dog` equal M174's record.

**Why a scene and not a script:** every column reads the `Tuning` autoload, which
`--script` never starts. The pass reuses `M174Pass.pass_net_averaged()` from
`tests/probes/m174_pass.gd`, which the tool can load where it lies once the import pass has run.

**Chosen where the design was silent, each open to overturn:** five tables rather than one wide
one, in catalogue order, columns padded to their header's width so no row reflows another; role
read at day 0; the two `city_wide` rows excluded, having no distance; pursuers' pass cells are
dashes, since their notice and chase read a player position the pass rig never sets, and a solid
row's 0px pass is a dash; detainers' figures are notional, as `walk_through_cost()`'s are; no
running column and no other ground. The orchestrator renamed the distance block from "standing"
to "walking at a fixed distance", since it nets the walking decay and idle decay is zero.

**Found on the way:** running the pass over the whole catalogue raised an engine error for
`protest` alone, from a `get_tree()` call on a node outside the tree that already had a
fallback; `EventInstance._protest_objective()` asks `is_inside_tree()` first.
