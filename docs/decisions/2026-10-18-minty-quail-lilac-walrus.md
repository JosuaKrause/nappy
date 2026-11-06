# minty-quail — The crowd and route tree suites stop calling members only tests call · 2026-11-05

minty-quail's `tests-unseen-reads.md`, the crowd and route tree build, under the player's rule that
a public member only tests call is deleted where possible, the tests going through a fake or what
the game shows, and kept only where the information cannot be had otherwise and the test needs it
(curly-rabbit #1095); and `tests-hold-nothing.md`'s findings in the same files.

**Built.**
- Deleted from `src/`: `Crowd.signals_for_tests()` (tests read `city.signals`, the same object),
  `Crowd.traffic()` (test-only too, though not on the audit's list; tests read the index through a
  car's `traffic`), `TrafficIndex.entry_count()` (the index suite compares each lane's
  `rearmost()` with the rearmost car or the place a turn booked, and no longer sees a claim counted
  twice), `CrowdExcitement.jolt_swell()` (tests read `jolt_swell_after(0.0)`, which the car's caret
  draws with), `LaneMover.lane_key_parts()` (a test helper, `tests/lane_key_search.gd`, finds a
  lane's parts through the game's `make_lane_key()`), `CrowdLanes.quietest_pavement()` (a helper
  of the crowd rig's own, and the `m117_decay` probe's), `RouteTree.branch_for()` and `bundles()`
  and `Branch.has_a_choice()` (the route tree suite scans the tree's branches, counts shared cells
  with `branches_on()` and counts a branch's routes), and `StreetNetwork.junction_distances()` (the
  lattice suite asks `at_junction()` and `has_street()`). Two doc sentences that named `bundles()`
  name the suite instead.
- The audit's findings held and went: the crowd rig's walker-presentation test (no `ModularWalker`
  node exists), its arterial check comparing a call with itself, its duplicate bump-outruns-decay
  check and `frames_with_one`; `on_the_spine >= 0` in the route tree suite; the lattice suite's
  junction, street and rect-size restatements; the seals suite's two alley-rate bounds, keeping the
  `candidates > 0` guard. The turns suite's red-light test now checks its junction is signalled
  rather than returning silently. The crowd rig's "exactly two precincts, three blocks long" checks
  became a non-empty guard, the builder's choice, open to overturn.
- The crowd rig's pack and unpack round trip went with the inverse it tested; its lane-key check
  now holds distinctness only, and the index suite's replacement for `entry_count()` is weaker, as
  above.

**Kept.** `Crowd.set_focus()`, with its reason written on it: the crowd's field follows the player
only in the player half of its live tick, which also shoves, warns and strikes, while the rigs tick
with `step()`, which has none, so a stroller handed through `use_player()` moves no field there,
real frames would add bumps and strikes to every check, and recycling would drop the cars and
walkers under test. Handing the crowd a focus source, which would let it go, changes `src/` and is
left open in `tests-unseen-reads.md`. `Crowd.recipe_coverage()` has a dev caller.
`space_out_the_traffic`, `trunk_used_the_spine` and `CrowdLanes.busyness` are members only their
own class uses, `tests-own-class-members.md`'s.
