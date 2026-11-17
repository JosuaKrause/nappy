# minty-quail — The routes, city and regions suites test their own module · 2026-11-17

minty-quail's `tests-one-module.md`, entry 7: each suite tests the one module it is named for and builds
no real object it does not test (inbox #1159 in gray-dolphin), the city built only where a suite tests
the city (inbox #1156 in gray-dolphin). The pass re-checked every `test_route*`, `test_routes_*`,
`test_city_*` and `test_regions` suite with `rg` for `RunCity.`, `.build(`, `city.tscn`, `booted_main` and
`build_day`/`start_day`/`begin_day`.

## What was built

- **The alley mouse's pile preference moves from `test_city_decay` to `test_events_scheduler`.** The case
  asks where the scheduler places the mouse (`GameDawn`, planning the last day on twelve generated maps, each
  from eight rolls, and counting mice within a tile of a garbage-sack pile), which is the scheduler's answer;
  the sacks (`GarbageSacks.alley_pile_tiles()`) are only the thing it is measured against. The case moves
  word for word with its own map seed constant (`_MOUSE_PILE_BASE_SEED`, the seed `test_city_decay` used).
  `test_city_decay` keeps the curve, the cracks, the litter, the sacks' own placement and the shuttering, all
  the decay's.
- **`tests/test_route_lines.gd` builds no `City`.** Its readout rig held a `City.new()` only to hand
  `DebugReadout.draw_routes()` a map (null: the layer holds it and no check reads it); it is handed a
  bare `CityMap.new()` now. The suite tests `RouteLines`, and the readout it builds is `DebugReadout`'s
  own wiring, which `tests/test_debug_layers.gd` holds.
- **`tests/test_route_bag.gd` states why its one real city is built.** `_a_mark_puts_a_place_on_her_route`
  builds a `City`, the event manager and the resistance director, because the guarantee is the hand-off
  between the three (a mark's reading rigs the bag, the events' walk sites what it draws, the city streams
  the place in); a stand-in for any of them would hand the others the answer the case asks whether they
  agree on. The header says so. It is the one such case in the suite: the rest is the bag and the director over
  a cached map.

## Left as they are, each for its stated reason

- **`test_route_rig`** (the dev rig's walker against a real city and a real resistance director),
  **`test_route_rules`** (the rules read the real tree's geometry), **`test_routes_kerb_tint`**,
  **`test_city_buildings`**, **`test_city_world`**, **`test_city_atlas_holds`**, **`test_city_ground_water`**
  and **`test_city_map`** are direct tests of the city or of a wiring only the real city has, and say so in
  their headers. `test_regions`, `test_route_tree`, `test_routes_lattice`, `test_routes_fallen_trees`,
  `test_routes_closures_*` and `test_route_line_rule` build no `City`: they plan over generated maps, which
  are the planners' input, plain data.

## Verified

Each moved or mocked case still fails with its module's line removed (a line of the module's source
deleted, the suite run, the line put back). The mouse case: with the five-fold draw of a location beside a
pile (`RuledLocationGround.scale()`) removed, mice land near a pile 68 times of 134 against a bar of 73, and
the check fails. `RouteLines` handed a bare map: with the layer's start state (`visible = 5 in indices`)
replaced by `true`, four of the suite's key and start-state checks fail. `test_route_bag`'s kept city case:
with `EventsAhead.place_what_is_owed_ahead()` made to return at once, the day 6 and day 11 checks that a row
is put on her route fail. The four touched suites, `tools/check.sh`, `tools/lint.sh` and the field-read,
test-only member and layer checks pass.

Choices where the design was silent, open to overturn: `test_route_bag`'s composition case is kept with a
stated reason rather than rewritten over stand-ins for the director, the manager and the city, since the
stand-ins would restate the answers the case asks about.
