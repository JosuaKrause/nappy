From `Tuning.REGION_WALL_FIRST_DAY` on, place fewer of the three hard blockers that today fill the
ground off the day's route tree, and leave everything else as it is: the route tree, distances,
connectivity and routing are computed exactly as now, and the region walls with their gatehouses
stay where `RegionPlanner` puts them, on the actual paths (`region_planner.gd`'s door-or-wall test
reads the real tree and is not touched). `RouteTree.is_on_the_tree()` itself is not changed, since
the generator, the gaps and rim and the region planner read it for structure.

The three, and where each is decided:

- **Seals**, the barrier on every off-tree street: `SealPlanner` (`src/routes/seal_planner.gd`, the
  loop that skips `tree.is_on_the_tree(key)`), and its alley-mouth seals.
- **Road closures**, placed only off the tree: `ClosurePlanner`'s candidate pool
  (`src/routes/closure_planner.gd`).
- **Wall-role catalogue rows**, weighted toward off-tree ground: `EventScheduler._copies_of()`
  (`src/events/event_scheduler.gd`).

**Proposed, not asked for** (the player said "fewer", not how many; open to their correction once
they have played it): from that day on, seal one off-tree street in two rather than every one, place
half as many road closures, and halve the wall rows' off-tree weights, each as one new `Tuning`
constant named for the gatehouse day so a playtest can move it. Removing a blocker only adds ground
she can reach, so winnability holds by the city skill's monotonicity test; the thinning keeps seals
on the streets nearest the tree's rim first or spreads them evenly, whichever the seal planner's
existing thinning already does. Measure the before and after with the route rig on day 9 to 13 and
put the numbers in the record.
