# minty-quail — The crowd's, the cars', the walkers' and the world's members only their own class used become internal · 2026-11-06


minty-quail's `tests-own-class-members.md`, the underscore pass, for the crowd (`Crowd`, the car
and walker strategies, the car turn, the lane mover, the crowd's lanes and field, the walker look)
and the world (`SpawnSiting`, `ExcitementSource`, `ExcitementSources`, `WorldContext`, `DrawLayer`,
`ChaseWay`): a public member only its own class and the tests use becomes internal and its tests
move to what the class does outward (curly-rabbit #1098), and one with no reader left is deleted
(curly-rabbit #1095).

**Built.** Internal: `DrawLayer._z_of` (the layer suites ask the depth a node asked onto a layer
draws at, through `draw_on`); the car strategy's shadow shape and turn bookkeeping (the shape suite
uses `ground_shape()`); the car turn's spin, start angle and carriageway edge (the car-view suite
builds real arcs with `CarTurn.into_an_arm`, the turns suite reads the arm radii off real arcs);
`Crowd._give_way_at_junctions`, `CrowdField._stretch_ends_of`, `CrowdLanes._busyness` (the rigs call
`busyness_for()`) and `WalkerLook._heading_now`. `WorldContext.total_excitement_at`, which no game
code read since the baby sums `excitement_sources_at`, is deleted with its overrides in three fake
worlds. Removed as holding nothing (curly-rabbit #1097): the walker views' per-sector heading
read-back, the sector seen from the opposite view being the outward check, and "a yielding
walker's own heading is zero", which the next check covers. Comments, docs and two skill sentences
(crowd-traffic, city) that named the renamed members name them as they are.

**Kept public**, each with its reason beside its line in the list: `Crowd.space_out_the_traffic`,
since the rig measures what the separation pass alone moves a car by and a zero-length tick still
recycles cars; `LaneMover.end_the_frame`, `ExcitementSource.will_be_lethal` and
`ExcitementSources.sources_at`, which other owners' classes override;
`ExcitementSource.expected_impact_at`, checked against what the excitement bar gains, since the
caret has only three levels; `SpawnSiting.is_out_of_sight` and `seen_from`, which hold the promise
that nothing pops in where she can see it; `WalkerStrategy.door_answer_for`, since only a hut tells
"walks through" from "held"; and `ChaseWay.sweep_under_way`, a frame-timing probe's read. Open to
overturn.
