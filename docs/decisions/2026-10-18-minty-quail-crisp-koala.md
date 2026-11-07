# minty-quail — After dawn: one reader of the walk's events, no live reachability check, day 13's roadblock found or swapped in, no convoy barricade · 2026-11-07


minty-quail's `walk-placed-blockers.md`, in #1169. The design is the player's words in inbox #1173,
#1177, #1179, #1182, #1183 and #1185 in gray-dolphin, and the orchestrator's readings marked there;
#1169's description holds the build commit by commit.

**Built.**
- **One reader of the walk's events, `WalkEvents`**, and what blocks her way is one rule,
  `Planned.obstructs()`, door bodies excluded (`Planned.is_door()`). No consumer filters the raw
  list of plans.
- **No live reachability check** (inbox #1173 in gray-dolphin, "that's a hard no"). `WalkSiting`'s
  flood and the resistance director's own reachability reading are deleted. Where she can get to
  from home is worked out once as the walk starts, `DayReach`, from the walk's plan, and handed in
  inside `WalkEvents`. Day 3's fire and day 11's added mast are sited on her way like the bag's
  events. The park cordon's gap check stays, and asks each event its clearance
  (`Planned.clearance()`, `where_it_stands_now()`).
- **No convoy leaves a barricade** (inbox #1183 in gray-dolphin): `military_convoy` has no
  `aftermath.on_finish`, so neither day 13's column nor a rolled convoy leaves one, and the
  column's trucks drive on and off. The `barricade` row stays, for dawn's seals.
- **Day 13's task roadblock** (inbox #1185 in gray-dolphin): after the day's ambient rows, scars and
  masts and before the scripted rows and the fill, a dawn pass places roadblocks beside her routes
  (a street no route runs along, one of whose junctions a route crosses, never the main road),
  outside the budget on its own streams, until every route tile has one within 1,024px along her
  paths. The task uses the nearest one the day placed, by today's measure (576, 896, then
  1,024px from the chalk mark); only when none is close does it swap one in, out of her sight, in
  place of a still, non-live event the day placed there (seals included; never the region wall's
  bodies, door bodies or scars). No fallback for "nothing near" is built.
- **Two of the re-derived cases** (`re-derived-cases.md`'s after-dawn half): the walkability repair
  reads its calm tiles from the day's `CalmAreas`, and a scene recipe builds its `CalmAreas` once.
- **Measured.** The placement fingerprint (days 1, 4, 8, 9, 10, 12, 14, the escape, the building)
  and the cordon's are identical to the base. The director's differs only on day 13 and on its
  probe's direct roadblock calls. Day 13 on the six probe seeds (4242, 90210, 1234567, 7, 31337,
  2024), the mark read at 10 places along her routes each:

  | | roadblocks at dawn per seed | beside her routes | the task | distance from the mark |
  |---|---|---|---|---|
  | before | 6 each | 0 or 1 | adds one at all 60 | 577–893px, median 590 |
  | after | 22, 17, 20, 15, 25, 17 | 14, 10, 13, 9, 17, 10 | finds one at all 60 | 101–1,034px, median 516 |

**Rejected.**
- The barricade kept, placed by the task roadblock's rules or only where the column stops off her
  routes: the player dropped the barricade instead (inbox #1183 in gray-dolphin).
- An extra roadblock pass after the fill, at most 6 (the orchestrator's pick on
  roadblocks-at-dawn): the player ordered the routes, then the spaced roadblocks, then the bag
  (inbox #1185 in gray-dolphin).
- A swapped-in body no wider than the one it replaces: not needed, since a body off the routes
  closes none of them (inbox #1185 in gray-dolphin).

**Open to overturn** (the builder's choices where the design was silent):
- the count: route tiles taken in the map's order, the first with no roadblock within 1,024px gets
  one, each sited by the planner's `_best_of()` with the fill's own spacing, preferring the far
  half of the reach (`BESIDE_THE_ROUTES_FAR_SHARE`, 0.5);
- a roadblock the task finds may already be in her view, since it stood there from dawn;
- `Planned.is_in_the_wall()` is set by `DayPlanner`, since the region planner was outside the
  pull request;
- the old last resort, the contact spawned on the search circle's edge, still catches the case
  nothing near and nothing to swap;
- `test_walk_siting_spec` keeps only its source scan and spec check of the home-street rule.
