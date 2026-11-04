# minty-quail — The route bag and dog suites drive the director's public calls (tests through public seams: W6b) · 2026-11-03

minty-quail's `tests-public-seams.md` and `run-state-handed-in.md`: the route bag, tutorial dog and
loose dog suites, subtask W6b of the scoped plan. One `src/` change: `MastSites._is_eligible()` is
`is_eligible()`, since `WalkSiting`, `ResistanceDirector` and `SceneRecipeRuntime` already called it
from outside its class.

**Built.**
- `test_loose_dog_arrives.gd` (private-read lines 1 to 0) has the director owe the dog through
  `EventManager.force()` and `start_day()`, walks her toward where it will be sent, and lets the
  manager's own physics ticks run `place_what_is_owed_ahead()`, one tick per frame through
  `PhysicsTicks`, instead of calling `EventsAhead._send_down_her_line()` by hand. The far dog is
  still placed by the spawner, since the director never sites one that far, and the suite checks it
  is retired where it stands, never walked off by leaving its route first.
- `test_tutorial_dog.gd` (2 to 0) hands the director's rows out through `due()` and rigs the second
  dog with `rig_her_route()`, so that dog is a bag marble rather than a row owed as itself.
- `test_route_bag.gd` (18 to 9, `GameState` lines 10 to 0) reads the route rows through
  `EventDirector.route_rows_on()`, finishes the mark through `contact().complete_now()`, reads the
  rigged bag from the resistance director's own run-log line, and uses `WalkSiting.cell_centre()` and
  `cells_ahead()`; its refused-siting check asks whether the mast's marble was drawn and whether
  the refusing siting was asked. Its check that reading the mark ends within 1.5 s of wall clock
  goes, since no wall-clock budget decides a check; the work is counted in the tiles the rig asks,
  which an existing check holds at none.
- The loose dog and the route-bag mark tests build their city on a run of their own. Checks 122,
  200 and 7 to 120, 248 and 10; eleven mutation runs.

**Open to overturn:** the loose dog suite runs on seed 2, whose far dog's line is clear; on seed
4242 a solid cuts its route, so it leaves by walking off instead of giving up. The city mark test still calls the
public `site_what_is_on_her_way()` and `place_what_is_owed_ahead()` by hand on a 0.1 s step, since
600 s of walking would be about twelve thousand real ticks.

**Not done:** `test_route_bag.gd`'s siting context (`_siting`, `_ground_as_a_set()`,
`_its_ground_on()`), which wants a reader a game class calls, and the places handed to her walk
(`route_row()`, `_placed_from_the_route`), which want the manager or the resistance director to
answer them; `test_day7_van.gd`'s `route_bag()` accessor. The cyclist's warned send through
`force()` and real ticks is not tried, so `test_pelican.gd`'s and `test_event_manager.gd`'s calls of
`_warn_down_her_line()` and `_send_down_her_line()` wait for a follow-up after #1008.
