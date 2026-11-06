# minty-quail — The route rig's kerbed-van clearance test picks a quiet site and runs on the seeds that pinched it · 2026-11-06


minty-quail's `tests-hold-nothing.md`, its last finding: the dev route rig's suite
(`tests/test_route_rig.gd`) held its kerbed-van clearance test ("crosses none of any body's
clearance", "no step of the plan past the van") on run seeds 1, 3, 4 and 5 but not 2 (record
minty-quail-brisk-llama), and the question was whether the rig's planner had a gap or the check held
by luck. With it the item's findings are all applied, and the item goes: keeping such checks out
from now on is **verify**'s testing policy and the CI check of test-only members (record
minty-quail-gentle-hare), and the underscore pass removes a check that holds nothing once its member
is gone (curly-rabbit #1097).

**Found.** The check held by luck. On run seeds 2 and 9 of 1 to 12 a second stationary body stands
beside the first kerb site the suite picks; its hazard ring shuts the carriageway's second lane and
the far sidewalk outright, so with the van's clearance, the first lane and the kerb row every way
past the van crosses a clearance tile, and the plan that crosses one frontage tile is the right one.
On the other seeds the far sidewalk is free and the plan never comes near the van. A first reading
blamed the planner's price for a clearance tile (64) against the detour; raising it to 100 changed
nothing on either seed, so the planner is unchanged.

**Built.** The suite picks a kerb site with no event within 8 tiles (`QUIET_SITE_TILES`), and runs
the clearance checks on the default run seed and on the two that pinched it (`PINCHED_RUN_SEEDS`),
each in its own fixture; with the old site choice those seeds fail two checks each.

**Open to overturn.** The 8-tile radius, and testing for any event rather than only hazards; and no
test of its own for the sealed street, where a plan must cross exactly one clearance tile.
