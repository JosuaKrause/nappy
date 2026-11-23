# minty-quail — PlanBuilder._cross_street_path and RouteSpec.Kind.CROSS_STREET are deleted · 2026-11-23

No catalogue row has a crossing route (`RouteSpec.Kind.CROSS_STREET`): the director sites the cat
dash at the lead ahead of her and carries its own path. The plan builder's crossing path
(`PlanBuilder._cross_street_path`), its `build()` arm and the kind are deleted, since code nothing
reaches is deleted (designing-classes). The one reader was a closing check in
`test_world_passability.gd`'s cat-crossing case that laid the crossing for the cat on each road tile
and asserted its ends were open ground; it held only the deleted function and went with it, the
case's checks of the director's siting (start and end on open ground, a clear run, never inside the
crouching cat's field) all standing. Rejected: giving a row the route, since the director's siting
already holds the cat's contracts.
