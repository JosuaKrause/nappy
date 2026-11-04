# minty-quail — The pelican and event manager suites let the director send down her line on real ticks (tests through public seams: W2b) · 2026-11-04

minty-quail's `tests-public-seams.md`: the director's sends in the pelican and event manager suites,
the follow-up W2 (woolly-lark) and W6b (frosty-koala) left. No `src/` change and no seam added.

**Built.** `test_pelican.gd` (private-read lines 1 to 0) and `test_event_manager.gd` (3 to 1) no
longer call `EventsAhead._warn_down_her_line()` and `_send_down_her_line()` by hand: each starts a
recipe with `EventManager.start_recipe()` and `start_recipe_route()`, the call a scene's recipe
makes, which leaves the director owing one marble of the row; she walks up the sidewalk on a rig, and
the manager's own ticks, one per frame, run `place_what_is_owed_ahead()`, which warns of the cyclist
and sends the loose dog. The suites check that the director owes the row, that a warned row is
warned of before it exists, and branch on the row's `telegraphs` rather than on
`warns_before_it_exists()`, which followed the mutation meant to catch it; a warned row's warning
must be seen on an earlier tick than the row itself. Checks 53 and 1636 to 54 and 1637; five
mutation runs.

**Split.** `test_event_manager.gd` had reached two minutes serial in CI since its walks moved onto
real ticks (woolly-lark), the line `tests/run_tests.gd` draws for a suite to split; its fire and
walking tests (the covered corner, the fire sited on her way and burning where her walk put it, the
way out, the engine's road, the fire never lit, and a day won with the fire unmet) move to
`tests/test_event_manager_fire.gd`, every check kept, 1580 and 57 of the 1637. The fire suite is the
slower of the two, about seventy seconds on a loaded machine.

**Not done:** `test_event_manager.gd`'s `EventInstance._notice_damping()`, which no other game class
reads; why the loose dog suite's far dog on seed 4242 has its route cut by a solid (record
frosty-koala), which needs a probe of that line.
