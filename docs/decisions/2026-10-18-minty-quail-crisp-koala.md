# minty-quail — After dawn: one reader of the walk's events, no live reachability check, day 13's roadblock found or swapped in, no convoy barricade · 2026-11-07


minty-quail's walk-placed-blockers item, built whole in #1169. The design is the player's words in inbox #1173,
#1177, #1179 and #1182 in gray-dolphin and on the open inbox issues #1183 and #1185, and the
orchestrator's readings marked there;
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
- **No convoy leaves a barricade** (inbox #1183): `military_convoy` has no
  `aftermath.on_finish`, so neither day 13's column nor a rolled convoy leaves one, and the
  column's trucks drive on and off. The `barricade` row stays, for dawn's seals.
- **Day 13's task roadblock** (inbox #1185): after the day's ambient rows, scars and
  masts and before the scripted rows and the fill, a dawn pass places roadblocks beside her routes
  (a street no route runs along, one of whose junctions a route crosses, never the main road),
  outside the budget on its own streams, until every route tile has one within 1,024px along her
  paths. The task uses the nearest one the day placed, by today's measure (576, 896, then
  1,024px from the chalk mark); only when none is close does it swap one in, in place of a still
  event the day placed there whose picture is out of her view (seals included; never one that has
  noticed her, the region wall's bodies, door bodies or scars), the roadblock taking the nearest
  road tile on that event's street within 3 tiles and passing every rule a roadblock is placed
  under. Nothing is added mid-walk: with neither, the task offers nothing after its mark (the
  player: no fallback, "it can always swap", inbox #1185).
- **The guard's side is decided once** (inbox #1185): the man who waits by day 13's
  task roadblock stands on its far side from the way she comes, fixed the first frame the
  roadblock the red arrow points at is drawn on screen; before that the side follows where she
  stands, and a guard on her side then is moved unseen once he and the new spot are out of her
  view. The decided side belongs to the roadblock's place, the tile its body stands on, so a
  roadblock that streams out and back in keeps it; seen again from its other side, it is not
  decided again. Nothing checks reachability.
- **The placement design is written down** (inbox #1185): `docs/EVENTS.md`, "The
  three views and the placement order", the player's design (placement by construction: the three
  views on the route, route-adjacent and off the route, each with its own bag; a street's three
  sections and six locations; the roadblock phase at dawn; the section swap) and where the code
  differs from it. The events skill points to it before every placement change.
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

  On 480 real chalk marks (20 cities, 24 each), the task finds a roadblock the day placed at 428
  (median 480px); the swap finds one at 19 more (435–1,042px, median 750px); 33 (6.9%, on 11
  cities) have nothing to swap: at 25 no event within 1,024px stands where a swap is allowed, at 8
  a roadblock's own placement rules refuse the candidate (a held street, unused calm ground, a
  door's clearance). Before the swap took in-world events and sidewalk ones, 52 had nothing.
  **These misses stand**: the swap and the dawn roadblock pass work on tiles, and placement by
  construction (locations, a bag per view, the roadblock phase, the section swap) replaces both
  whole after #1169, so neither is changed further here.

**Rejected.**
- A roadblock added mid-walk on the edge of the 576px circle round her when nothing was near and
  nothing could be swapped: the player, no fallback (inbox #1185).
- The barricade kept, placed by the task roadblock's rules or only where the column stops off her
  routes: the player dropped the barricade instead (inbox #1183).
- An extra roadblock pass after the fill, at most 6 (the orchestrator's pick on
  roadblocks-at-dawn): the player ordered the routes, then the spaced roadblocks, then the bag
  (inbox #1185).
- A swapped-in body no wider than the one it replaces: not needed, since a body off the routes
  closes none of them (inbox #1185).
- Dawn standing a roadblock close by every place the chalk mark can be read, to cover the 33
  misses: the orchestrator's reading, withdrawn when the player restated the design (inbox #1185).
- Widening the swap past 1,024px and to the streets a route runs along, which a queue item held
  for a while: not the player's measure, and the swap is replaced by placement by construction.
- Narrowing the swap to the design on tiles (dropping standing still, having noticed her, the
  re-judged placement and the 1,024px cap): left for placement by construction, so the work is not
  done twice (inbox #1185).

**Open to overturn** (the builder's choices where the design was silent):
- the count: route tiles taken in the map's order, the first with no roadblock within 1,024px gets
  one, each sited by the planner's `_best_of()` with the fill's own spacing, preferring the far
  half of the reach (`BESIDE_THE_ROUTES_FAR_SHARE`, 0.5);
- a roadblock the task finds may already be in her view, since it stood there from dawn;
- `Planned.is_in_the_wall()` is set by `DayPlanner`, since the region planner was outside the
  pull request;
- the guard reads her position against the roadblock, not her heading, which flips with a turn;
  where the far side has no spot, he stands on her side and the run log says so;
- the side is decided for the roadblock the red arrow points at when it first comes on screen,
  since that is the roadblock she approaches (inbox #1185);
- the swap keeps "standing still", since a moving event leaves no place to take;
- `test_walk_siting_spec` keeps only its source scan and spec check of the home-street rule.
