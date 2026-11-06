# minty-quail — The city's, the map's, the interiors', the routes' and the other city owners' members only their own class used become internal · 2026-11-06


minty-quail's `tests-own-class-members.md`, the underscore pass, for the city (`City`, `CityMap`,
`CityState`, `CityGenerator`, the blackout, the scenery residency, the street trees, the poster art,
the marble bag, the traffic signals), the interiors (`InteriorScene`, `InteriorMapPlan`,
`InteriorMap`), the routes (`RouteTree`, the region planner, the closure marker, the seal planner,
the park closure, the corridor) and the finale planner: a public member only its own class and the
tests use becomes internal and its tests move to what the class does outward (curly-rabbit
#1098), and one with no reader left is deleted (curly-rabbit #1095).

**Built.** Deleted, with no reader left: `City.home_door_is_sealed`, `CityMap.is_post` and
`is_soft_sealed`, `CityState.changed_on`, `InteriorMapPlan.inner_floor_approaches`,
`InteriorMap.PARTS` and `RouteTree.trunk_used_the_spine`. Every other member of these files only
they and the tests used is internal, `Blackout.update` and `distance_from_station` and
`ParkClosure.from_along` among them, and `City.blackout`, a node the city builds itself. The
suites read what the classes do: the blackout as the lights a stroller in the tree sees (signals,
windows, the city gone dark), a patrol on a city dark from the start, the home door and its
building off the city's nodes (`tests/home_door_reads.gd`; the door is a picture, not a body), a
barrier off the solid the city stands at each mouth, the soft seals through `Mover.SOFT_SEALS`, the
city's state through its save snapshot (`tests/city_state_reads.gd`), a signal's phase through
`green_for`, an interior's doors by standing her on them over real frames, its light through the
scene's `modulate`, its bang through `bang_outside()`, a way out through `way_out()`, a park
fence's ends through `rail_ends()`, the regions through their boundary segments and the plan's
alleys, the lattice grid through `ReachabilityGrid.build()`. Removed as holding nothing
(curly-rabbit #1097): two region checks that asked the planner whether it agreed with itself, the
flood test now shutting exactly the plan's alley mouths; an interior stair check that compared the
parser with itself now asks only that the cell is painted, and the lit-while-dark tally became "all
or none each tick, and every flash ends".

**Kept public**, each with its reason beside its line in the list:
`CityGenerator.power_station_rank`, since the generator drops the candidates it passed over and only
the rank shows the order; `SceneryResidency.ordinary_guard_preparations`, a probe's measurement;
`InteriorScene.distant_flash_wait`, whose curve needs thousands of draws; and
`ClosureMarker.cause_picture` and `cause_feet`, which exist only as draw-call arguments.
`STREET_TREE_MAX_LINED_FRACTION` stays a constant its test holds a relationship against. Open to
overturn.
