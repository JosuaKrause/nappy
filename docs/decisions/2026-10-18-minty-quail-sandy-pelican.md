# minty-quail — Three more members of the world layer nothing reaches are deleted · 2026-11-19

minty-quail's `dead-code-sweep.md`, `src/world/`, the module outside `src/events/` and
`src/resistance/` with the most dead code (those two wait for the events' interface rows 3a, 3b and
4b, which rewrite them): code nothing reaches is deleted, and a feature wanted back is built fresh
(inbox #1180 in gray-dolphin).

**The survey.** `tools/check_test_only_members.py --list`; every member declared under `src/`,
`tests/` and `tools/` searched for by name across `src/`, `tests/`, `tools/`, `scenes/`,
`scene-recipes/` and `project.godot`, comments stripped; every private member searched for in its
own file, an override of a base's hook counting as a use; and the check's own receiver typing (its
`scan()`) for a public member with no use in another file that can reach it, none in its own file
and no test read. That last pass finds a dead member whose name another class shares, which a name
search cannot: `Navigator.passable()` shares `WorldMap.passable()`'s name, `WorldMap.path()`
`Navigator.path()`'s.

**Deleted.**
- **`Navigator.passable()`** (`src/world/navigator.gd`): whether a mover may stand on a tile, a
  one-line forward to `WorldMap.passable()`. Added with the shared navigator (#817), and nothing
  ever called it: every caller asks the map, or `Navigator.passable_at()` for a world point, whose
  doc now names `WorldMap.passable()` itself.
- **`WorldMap.path()`** (`src/world/world_map.gd`): a way round for a mover, a one-line forward to
  the map's navigator. Added with the one `WorldMap` (#835), and nothing ever called it: every way
  round is asked of a `Navigator`.
- **`ExcitementSource._walled_off()`** (`src/world/excitement_source.gd`): whether a wall stands
  between a source and her. The game's last caller was the projection (the caret's look over the
  next seconds), until #882 moved the shared source into the world layer and the projection began
  asking `wall_grid().wall_between()` itself, the grid read once per sampling. Since then only
  `tests/fixtures/prediction_reference.gd` (the independent projection
  `tests/test_prediction_reuse.gd` holds the game's to, bit for bit) and the probe
  `tests/probes/polite_rabbit_wall_costs.gd` called it, reaching a private member from outside.
  Each now asks the public `wall_grid()` the same question the deleted body asked
  (`grid != null and grid.wall_between(...)`), so neither changes meaning. `_walled_off_now()`, the
  one-line cache `contribution_at()` asks through, takes over the deleted doc's sentence and says
  the projection asks the map itself.

**Kept.** The module's members in the `[kept]` group of `tools/test_only_members.txt`
(`ChaseWay.sweep_under_way`, `ExcitementSource.clock`, `expected_impact_at` and `will_be_lethal`,
`ExcitementSources.sources_at`, `SpawnSiting.seen_from` and `is_out_of_sight`) were read against
their reasons, which hold: each is the only handle on a promise no outward sign carries.
`ExcitementSources.holds_her_alone()`, which no file outside its own calls, is the base of
`EventSources`' override and asked of every set in `ExcitementSources` itself.

**Left.** The survey's findings in the other modules are in `dead-code-sweep.md`'s "Where the rest
is", by module: one or two members each in `src/crowd/`, `src/dev/`, `src/ui/`, `src/visuals/`
and `src/game_enums.gd`, three in `src/events/` for the events' interface rows, none in
`src/resistance/`, and helpers nothing calls in `tests/` and `tools/`.

## Parity

The diff under `src/` is deletions and comments only (inbox #813 in curly-moose).
`tests/test_excitement_source.gd`, `test_navigator_fallbacks.gd`, `test_prediction_reuse.gd` and
`test_world_passability.gd` pass. The probe `tests/probes/polite_rabbit_wall_costs.gd` (three
seeds, days 1, 5, 9 and 13) passes, its own check that the built wall rule (the changed line)
summed over every route agrees with the game's `contribution_at()` included.
`tools/cost-table.sh --check` passes.
