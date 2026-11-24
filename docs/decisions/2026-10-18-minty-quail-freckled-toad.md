# minty-quail — The event manager's own suites ask its answers, with one hand-in and two kept forwards (minty-quail, A2b, M) · 2026-11-24

**The ask.** A member only its own class and the tests use becomes internal, its tests checking what
the class does from outside; a check that holds nothing once its member is gone goes; a hand-in
stays public (inbox #1098 in curly-rabbit, inbox #1097 in curly-rabbit, inbox #1095 in
curly-rabbit). This is the first pull request, "M", of the design that moves the event manager's five
parts (`ahead`, `checkpoints`, `spawner`, `streaming`, `warnings`) behind the manager: it moves the
manager's own suites off them.

## What was built

- **`EventManager.use_sitings(maker)`**, a hand-in forwarding to `EventsAhead.use_sitings()`: the game
  keeps the maker `_init()` makes, a test hands in `FakeSitingMaker` (the counting-ground case of
  `test_event_manager.gd`, the home-street cases of `test_walk_siting_spec.gd`) or
  `KeepingSitingMaker` (through its `on()`, which the two probes `m179_fire_on_her_way` and
  `m180_crews_on_her_way` use).
- **`EventManager.route_row(id)` and `EventManager.way_on()`**, two forwards to the director, kept
  because a suite reads the director's state: `way_on()` by `test_event_manager.gd` (a recipe's
  bodies are in the through roads the walk's way on drives by), `route_row()` by
  `test_resistance_arrow.gd` (PR W). The list holds the `way_on` line; the `route_row` line is
  added by W with the suite that reads it, since the check refuses a line no test reads.
- **`EventsAhead`'s two walk settings private** (`_holds_the_home_streets`,
  `_sends_poster_pursuits`); their two list lines are gone.
- **The suites ask answers.** `test_event_manager.gd` starts its walks with `start_recipe()`, streams
  through `stream_around()`, makes unplanned instances with `spawn_extra()` and `retire()`, runs the
  cyclist's warning on real physics ticks, and reads the way on through `way_on()`.
  `test_event_parts.gd` builds the parts it drives the way `EventManager._init()` does (`_Parts`) and
  takes the body-listener case from `test_event_manager.gd`, whose subject is
  `EventStreaming`. `test_event_manager_fire.gd`'s covered-corner case starts a walk holding the fire
  and passes one tick with the scheme handed in. `test_walk_siting_spec.gd` reads the home-street
  rule through the maker's recorded ground.

## Measured

- Check counts, main then head, each suite alone: `test_event_manager.gd` 833 to 829 (the moved
  listener case, four checks), `test_event_parts.gd` 35 to 39 (the same four), `test_walk_siting_spec.gd`
  14 to 15 (the guard that the two rules differ now opens the first case too),
  `test_recipe_structures.gd` 54 to 51, `test_scene_recipe_boot.gd` 6 to 6,
  `test_event_manager_fire.gd` 58 to 58.
- `test_recipe_structures.gd`: the two field reads of the poster setting and the field read of the
  home-street setting hold nothing once the field is private. The home-street half could not be
  asked of the installed scene through the maker: on the trailer-trucks recipe's 160 by 160 map the
  ground a walk holding the home's streets is handed and the one it is not handed differ for 22 of the
  catalogue's 55 rows before an install (the burning building: 864 tiles against 870), but the install
  holds the home street (`CityMap.is_held_at()` is true on it afterwards), which both rules refuse, so
  after an install the two grounds offer the same tiles for every row (856 for the burning building) and
  a check through `FakeSitingMaker` cannot fail there. The rule's link from the spec to the ground stays
  held by `test_walk_siting_spec.gd`, and which spec the scene's events took by the torn-poster half,
  since both settings come from the one `use_the_walk_of()`. `test_scene_recipe_boot.gd` drops its
  home-street half the same way.
- A day's spec sets both of `use_the_walk_of()`'s settings true and the escape city's both false, so
  a swap of the two changes no answer under them. The escape building's spec
  (`DaySpec.Section.BUILDING`) sets them apart (no poster pursuer, the home's streets held), and
  `test_walk_siting_spec.gd` runs a case under it (the ground its siting is asked on keeps the home's
  streets; a torn poster sends nobody), which fails with the two settings swapped (3 failures).
  Each setting set always true fails the three suites.
- Mutations shown failing: the summons deleted from the tick (the covered-corner tap case and four
  more), `warnings.run` deleted (the cyclist's four), `use_sitings` not forwarding (the counting-ground
  and both home-street cases), the way on made before the bodies are recorded (the way-on case), the
  streamed plan's `restore()` skipped (the streamed pursuer's four), the listener told before the body
  is recorded (the listener case), each setting of `use_the_walk_of()` always true.

## Left alone

- `tests/probes/minty_quail_crowd_frames.gd` does not parse on main (a variable `drawn` declared
  twice at line 63); no suite loads it, and PR Z runs each probe by name.
