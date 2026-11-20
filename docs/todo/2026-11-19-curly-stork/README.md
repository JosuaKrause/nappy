priority: now

# curly-stork — A planned body's pieces are laid out once, not by three loops · filed 2026-11-19

**The finding.** The design of row 3a of minty-quail's `event-interface.md` found that three loops lay out a
planned body's pieces from its geometry, each its own way: `WalkGround.solids_of()` (`src/events/walk_ground.gd`),
`EventSpawner.obstructed_footprint()` (`src/events/event_spawner.gd`) and `RouteRigPlanner._planned_body_tiles()`
(`src/dev/route_rig_planner.gd`). After row 3a's pull request "where a body stands on its street is the model's" all
three ask the new `BodyStance` for the geometry, but each still lays the pieces itself. A fact derived in more than
one place is the smell **designing-classes** names (inbox #1156 in gray-dolphin): one object derives it once and is
handed around. minty-quail's list is frozen, so this is an entry of its own (inbox #1268 in olive-ferret).

**Item:** `one-layout-of-pieces.md`.

**Proposed, not asked for:** the band `now`; and that it waits for row 3a's `BodyStance` pull request and row 3b
(which owns the spawner), said in the item.
