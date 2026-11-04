# minty-quail — The route bag, events pursuit and spent park suites read what the game hands out (tests through public seams: W18) · 2026-11-04

minty-quail's `tests-public-seams.md`: `tests/test_route_bag.gd`, `tests/test_events_pursuit.gd`
and `tests/test_spent_park.gd`, and `src/events/events_ahead.gd` with `src/events/event_manager.gd`.

**Built.** Private-read lines 9, 5 and 4 to 0. `EventsAhead.use_director()` is handed the director
`EventManager.setup()` makes, rather than building one of its own, so the pursuit suite hands the
real events-ahead a fake director and a counting board and reads the blocked lesson's retries off
them; its cyclist test stands a real `DangerEdge` in the tree with an atlas and measures on real
frames, so no frame delta needs handing in. The route bag reads the director through
`director()`, the places handed to her walk through `is_from_her_route()` and the ground through
`open_ground_for()`, and checks the mast's offer by siting a mast through `ahead_of()`. The spent
park finds the closure pictures down the city's tree, asks the physics world for the barrier
bodies after a real tick, and hands the short archway and the day's park closures to a second city
through `recipe_closures` and `start_recipe_day()`.

**Not done:** a place waiting for its site sits in the director's private list until it is sited,
and nothing a game class asks reads it; `EventsAhead.walk_siting()`, which the route bag and fire
suites and two probes read, has no game caller; the route bag reads it where it read the private
siting before.
