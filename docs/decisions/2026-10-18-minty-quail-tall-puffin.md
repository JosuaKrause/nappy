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
the far sidewalk, so the way round the van grows long, and the rig's planner, which prices a tile of
a body's clearance at 64 (`_CLEARANCE_STEP_COST`), takes the one frontage tile through the van's
clearance as the cheaper plan. On the other seeds the far sidewalk is free and the plan never comes
near the van. The price is the planner's documented trade-off, a plan crossing one tile only where
going round is longer still: with the old site choice, a price of 100 still crossed, and 400 or
1000 went round on both seeds, so a way round exists there. The planner is unchanged.

**Built.** The suite picks a kerb site with no event within 8 tiles (`QUIET_SITE_TILES`), and runs
the clearance checks on the default run seed and on the two that pinched it (`PINCHED_RUN_SEEDS`),
each in its own fixture; with the old site choice those seeds fail two checks each.

**Open to overturn.** Keeping the planner's price rather than raising it so the rig never presses
against a van; the 8-tile radius, and testing for any event rather than only hazards; and no
test of its own for a street where going round is longer than the price, so the plan crosses one
clearance tile.
