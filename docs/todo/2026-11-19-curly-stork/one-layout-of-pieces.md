# A planned body's pieces are laid out once

The three loops that lay out a planned body's pieces (`WalkGround.solids_of()`, `EventSpawner.obstructed_footprint()`,
`RouteRigPlanner._planned_body_tiles()`) become one answer, asked by all three. One answer needs a model-layer value
for "a piece where it stands", since `Footprint` is the world's; that value and where it lives are the design
question. Starts after row 3a's pull request that adds `BodyStance` and after row 3b of minty-quail's
`event-interface.md` (the event manager's parts, which owns `event_spawner.gd`). Nothing a player sees changes: a
sweep that compares the three loops' answers before and after on the probes' cities holds it.
