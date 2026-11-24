# minty-quail — The last cross-module cases move to their own suites (minty-quail, tests-one-module) · 2026-11-23

minty-quail's `tests-one-module.md`, the entries that remained after the pass over every module's suites:
the fields-layer cases of `test_wall_shield`, the `--spawn` event, closure and door cases of
`test_dev_rig` and the fence round trip of `test_save`. Each case keeps its claim and its check texts; what
stays in a source suite is about its own module only. The entry that is a kept exception, the crowd's real-day
check, stays as it is.

## What was built

- **The debug view's fields-layer cases** (six: the cut where a wall stops the field, a blocked line cut whole,
  no wall question where none can block, the cut along the whole outline on a real city, a moved source cut
  again, no outline on screen culled) moved with their helpers (the hand-built map, the real street musician,
  the counting map, the emitter) from `tests/test_wall_shield.gd` to `tests/test_debug_layers.gd`. The suite's
  header says why it stands a real musician and real generated cities: the layer draws an outline only where the
  map's wall answer lets the meter read it.
- **`--spawn` event cases** (the target, the queue-fed refusal by name, the waiting row stood outside its
  trigger) moved to `tests/test_event_manager.gd`, on the stage over the generated map, day 6, where the
  manager's placed plans are the answer; the dev rig is handed the stage's manager, streets and header, and no
  resistance director. No city is built for them.
- **`--spawn closure`** moved to `tests/routes_closures_rig.gd` (run by `test_routes_closures_a.gd`), on the
  day's planned closures of the sweep's first map, with the tree and no city.
- **`--spawn door`** (the day before the region wall, and the hut's approach side) moved to
  `tests/test_checkpoints.gd`, on the region plan of the suite's first seed (the seed the dev rig suite used),
  where the hut bodies are the plan's own; no city is built for them.
- **`test_dev_rig` keeps** the named tiles, the contact target, the unknown target and the pavement offset, and
  its one city, which `contact` needs: the resistance director places the chalk mark from the city's map,
  events and streets together.
- **The fence round trip** is split at the map. `test_save` keeps the save's half (the fence survives the round
  trip) and builds no map; the map's half (a run resumed in act IV, handed the remembered fence, shuts its used
  area and chooses no second fence) is `_test_a_resumed_run_cannot_select_a_second_fence` in
  `tests/test_spent_park.gd`, the suite of the fence's rule, on the same seed.
- **`tests-one-module.md`** loses its third entry and the wall-shield clause of its second; this record is
  added to its list.

## Choices where the design was silent, open to overturn

- The dev rig's `--spawn` event, closure and door answers are asked of the modules' suites rather than rewritten
  over fakes, as the entry says ("to move with those modules"). Each moved case builds less than before (no
  city), but each still asks the dev rig, so those suites hold a dev-rig question.
- The map suite for the fence is `test_spent_park.gd`, not `test_city_map.gd` (the copy and capture suite).
  `_test_the_one_fence_is_remembered_after_its_act` in the same suite asks nearly the same of the map from a
  chosen fence; the moved case starts from a remembered one in act IV with a literal fence, which that case does not.

## Verification

Check counts by file name, main then branch (local runs): `test_wall_shield.gd` 84 to 53,
`test_debug_layers.gd` 74 to 105 (the 31 moved), `test_dev_rig.gd` 21 to 7, `test_event_manager.gd` 827 to 833
(the 6 of events), `test_routes_closures_a.gd` 792 to 794 (2), `test_checkpoints.gd` 18164 to 18170 (6),
`test_save.gd` 302 to 300 and `test_spent_park.gd` 54602 to 54604 (the 2 of the fence). Each moved check has its
old count: 14 left the dev rig for 6 + 2 + 6, the 2 left the save. Mutations, not committed: the hut's stand-off
at twelve tiles fails the door case; the closure target returning a point off the map fails the closure case;
the waiting row's stand-off clearance removed gives two failures in the event case. `tools/check.sh`,
`tools/lint.sh`, `check_field_reads.py`, `check_test_only_members.py` and `check_layers.py` pass.
