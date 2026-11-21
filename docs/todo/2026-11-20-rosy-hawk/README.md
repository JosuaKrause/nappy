priority: now
after: 2026-11-19-curly-stork

# rosy-hawk — Where a plan's body stands is chosen once, not in three places · filed 2026-11-20

**The finding.** The design of curly-stork (a planned body's pieces laid out once) found that where a plan's body stands
is chosen in three places, `WalkGround._stands_at()`, `RouteRigPlanner._planned_position()` and
`PlanBuilder.body_stands_at()`, each `BodyStance.stands_at(map, plan.row(), route[0] if route.size() > 0 else
plan.placed_at())`: the geometry is one call, the choice of point is written three times. A fact derived in more than
one place is the smell **designing-classes** names (inbox #1156 in gray-dolphin).

**Item:** `one-choice-of-point.md`.

**Proposed, not asked for:** the band `now` (the refactor's own kind of work, as curly-stork is), and the fix.
