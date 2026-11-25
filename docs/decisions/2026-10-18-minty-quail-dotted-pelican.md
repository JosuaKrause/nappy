# minty-quail — The routes, city and regions suites test their own module · 2026-11-17

minty-quail's `tests-one-module.md`, entry 7: each suite tests the one module it is named for and builds
no real object it does not test (inbox #1159 in gray-dolphin), the city built only where a suite tests
the city (inbox #1156 in gray-dolphin). The pass re-checked every `test_route*`, `test_routes_*`,
`test_city_*` and `test_regions` suite with `rg` for `RunCity.`, `.build(`, `city.tscn`, `booted_main` and
`build_day`/`start_day`/`begin_day`.

## What was built

- **The alley mouse's pile-preference case moves from `test_city_decay` to a suite of its own,
  `tests/test_scheduler_mouse_piles.gd`.** The case asks where the scheduler places the mouse (`GameDawn`,
  planning the last day on twelve generated maps, each from eight rolls, and counting mice within a tile of a
  garbage-sack pile), which is the scheduler's answer; the sacks (`GarbageSacks.alley_pile_tiles()`) are only
  what it is measured against. The case is unchanged, with its map-seed constant. It is its own suite, not a
  case of `test_events_scheduler`, because the 96 planned dawns are about 160 s of CI time and the longest
  suite sets the floor of a run: inside `test_events_scheduler` the pair measured about 408 s on CI against
  that suite's 134 to 183 s on main. `test_city_decay` keeps the curve, the cracks, the litter, the sacks'
  own placement and the shuttering, all the decay's; it dropped from 138 to 181 s on main to about 6 s.
- **`tests/test_route_lines.gd` builds no `City`.** Its readout rig held a `City.new()` only to hand
  `DebugReadout.draw_routes()` a map (null: the layer holds it and no check reads it); it is handed a
  bare `CityMap.new()` now. The suite tests `RouteLines`, and the readout it builds is `DebugReadout`'s
  own wiring, which `tests/test_debug_layers.gd` holds.
- **`tests/test_route_bag.gd` states why its one real city is built.** `_a_mark_puts_a_place_on_her_route`
  builds a `City`, the event manager and the resistance director, because the guarantee is the hand-off
  between the three (a mark's reading rigs the bag, the events' walk sites what it draws, the city streams
  the place in); a stand-in for any of them would hand the others the answer the case asks whether they
  agree on. The header says so.

## Left, in the item

Four cases of `test_route_bag` (`_test_a_stretch_of_her_route_the_length_of_a_bag_has_its_mix`,
`_test_day_one_hands_out_two_dog_walkers_among_the_first_three`,
`_test_day_3s_lesson_is_first_and_a_bag_of_its_own`, `_test_a_place_that_cannot_be_sited_holds_nothing_up`)
plan a whole real day through `GameDawn` on a generated map only to hand `EventDirector.start_day()` its
moments. The scheduler is not that suite's subject, so they are entry 7's what-is-left: handed moments read
once off a real plan and committed as the mock. No case of the suite uses the map cache.

## Left as they are, each for its stated reason

- **Direct tests of the city, or of a wiring only the real city has**: `test_routes_kerb_tint`,
  `test_city_buildings`, `test_city_world`, `test_city_atlas_holds`, `test_city_ground_water` and
  `test_city_map` (on real generated maps, since a copy is only as lossless as the fields generation fills);
  each says so in its header.
- **`test_route_rig`** drives the `--route` dev rig's whole loop (resolve, plan, walk, arrive) against a
  real city and a real resistance director; its header's reason is that the whole loop is what it proves.
- **`test_route_building`** boots the game in a child process (`--start-escape --route tunnel`) to drive
  the building walker and the rig, and reads the run log; its header gives the reason.
- **`test_city_map_cache`** tests the cache of generated cities (`tests/city_map_cache.gd`), which holds
  nothing but the generator's maps; **`test_city_map_kerb`** asks `CityMap.kerb_beside()` of points on a
  lattice and needs no map.
- **Build no `City`**: `test_route_rules` (a cached generated map with `GamePlanBuilder`, the rules' geometry
  read off the real tree, said in its header), `test_regions`, `test_route_tree`, `test_routes_lattice`,
  `test_routes_fallen_trees`, `test_routes_closures_a` to `_c` and `test_route_line_rule` plan over
  generated maps, the planners' input and plain data.

## Verified

Each moved or mocked case still fails with its module's line removed (a line of the module's source
deleted, the suite run, the line put back). The mouse case: with the five-fold draw of a location beside a
pile (`RuledLocationGround.scale()`) removed, mice land near a pile 68 times of 134 against a bar of 73, and
the check fails. `RouteLines` handed a bare map: with the layer's start state (`visible = 5 in indices`)
replaced by `true`, 16 of the suite's start-state and key checks fail. `test_route_bag`'s kept city case:
with `EventsAhead.place_what_is_owed_ahead()` made to return at once, the day 6 and day 11 checks that a row
is put on her route fail. The touched suites, `tools/check.sh`, `tools/lint.sh` and the field-read,
test-only member and layer checks pass.

Suite times, read from CI's shard logs of this pull request, are given in its description.

Choices where the design was silent, open to overturn: `test_route_bag`'s composition case is kept with a
stated reason rather than rewritten over stand-ins for the director, the manager and the city, since the
stand-ins would restate the answers the case asks about; the four route-bag cases above are left rather
than converted.
