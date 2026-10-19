# The escape city's placement runs on the day's scheduler, with its marble bag

The player: only "the *building* escape may keep its own way of placing events *NOT* the city escape"
(minty-lemur #785). Today the city's placement is a parallel pipeline: `EventScheduler.build_finale`
and `_fill_a_finale_street` (near 357 and 421) with `EscapeGround`/`EscapeSolid`, `_finale_ground`,
`_finale_ground_cache`; `SealPlanner.plan_finale` with its own candidate list; `FinalePlanner`'s chains
instead of a `RouteTree`/`RegionPlanner`; `City.start_finale` (`city.gd` near 998) skipping
`_sync_home_door`, `refresh_street_trees`, `_close_streets` and the posters, and
`tint_the_escape_route` duplicating `_tint_the_route_kerbs`. `build_finale`'s doc justifies its fixed
counts ("A budget is the wrong shape for this"), which the player answered: "so you prefill the events
for escape but that doesn't justify not using a marble bag. those concepts are orthogonal"
(minty-lemur #785).

**Build:** `build_day(spec)`, with the spec supplying the route source (an interface both `RouteTree`
and `FinalePlanner`'s plan satisfy: the streets on the walk, whether a tile carries a route), the rows
and how they are drawn (the escape's marble bag, in the player's order "trucks > explosions > vans >
barriers > empty", minty-lemur #785, with the counts downy-tapir measured, `Tuning.FINALE_SLOTS_PER_STREET` and `FINALE_BAG_*`; `build_finale`
already takes the bag and the slot count as arguments), and
which rules apply. The player kept, for the escape, no calm-park rule, the escape's own rules for the
home's streets, and no per-day caps (minty-lemur #785, the PR #781 forks); those become spec settings.
`EscapeGround`'s guarantees (each street keeps a sidewalk open, the walk stays joined) become a rule
both paths share. `plan_finale` folds into the seal planner's day path, `City.start_finale` into
`start_day(spec)`.

**Also, found measuring downy-tapir's bag:** a van at a narrow point can leave no safe walk, since
`EscapeGround` keeps a sidewalk open past its body but not past its 54px lethal reach — the shared rule
should keep the walk clear of a lethal reach, not only a body; `build_finale` reads its defaults from
`Tuning` instead of being handed them by the planner; and `RouteRig` (`--route`) is not built on the
escape boot, so `tests/probes/escape_winnable.gd` stands in for the baby and collisions — a real walker
on the escape boot replaces that stand-in.
