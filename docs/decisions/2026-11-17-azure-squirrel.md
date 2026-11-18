# azure-squirrel — The posted guard catches a straight walker: the test walked her into a building · 2026-11-18

**What it is.** The entry azure-squirrel (bug band, inbox #1519 in breezy-magpie): a posted roadblock
guard seemed to charge a straight walker and miss her on some streets (3 of 32 posted walks over 8
seeds), and the finale rig held its check to a floor of half the walks caught.

**What was found: no game bug.** The guard notices her about 150px away, warns for 2.0s while she
walks on, and charges with her 106 to 123px ahead; he runs 130px/s to her 92px/s and catches her
about 400px past his band (399 to 418px on every walk measured). On the two missed streets (seed 77's
(7,0,1) forward, seed 31337's and 4216201080's (2,0,1) back) the street ends 209px and 304px past the
band, and the rig's line (`her_line()` in `tests/escape_roadblock_rig.gd`) ran on through the cross
street into a building and off the map, where no guard follows. A real walker is stopped by the
ground there.

**What was built.** The rig's line ends where the ground stops her body, and the walk holds her
there. The finale rig checks every posted walk per crossing again (the floor is gone); at main that
check fails on exactly the two crossings above. `probes/escape_roadblock_cost.gd`: posted walks
caught 28 of 30 at main, 30 of 30 now; lure walks get past on every street, as before. No warning
time, speed, reach or spacing changed. `docs/EVENTS.md` and `docs/MECHANICS.md` say a straight walk
is caught along his street, and that where his street ends sooner she can turn the next corner
first and get away, since his chase does not follow her round a building.

**Open, on the board as `corner-turner`:** whether the guard follows a walker round the corner (the
orchestrator's pick), turning the corner stays a second way past, or no posted band stands within
his catch distance of a street's end.
