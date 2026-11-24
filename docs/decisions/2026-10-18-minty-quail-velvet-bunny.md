# minty-quail — The tests read the contact, the map, the source and the mover through methods · 2026-11-24

**The ask.** A test reads what it tests only through methods: on the board's tests-read-fields,
whether a test counts as another object under "fields are not API", "yes" (inbox #1182 in gray-dolphin).
The item is `docs/todo/2026-10-18-minty-quail/tests-one-module.md`; this record is the part of it that
converted the five reads it listed. What is left of it (the mast sites, the reads the field-read check
finds in the tests today, the one kept exception) stays in the item.

## What was built

- **`ContactPoint.is_done` is `_is_done`.** The five resistance suites ask `is_finished()`, the
  method the game asks. `tests/test_destination_drawing.gd` reaches a done contact the way the game
  does, `complete_now()`, instead of writing the field. The line for `is_done` in
  `tools/test_only_members.txt` is deleted.
- **`WorldMap.blocked` is read through the map.** `tests/test_day13_guard.gd` asks `tiles_shut_to()`
  for the walk's blocked ground, and compares a copy of the map (`CityMap.copy()`) against another
  with the section's bodies given back (`release_obstruction()`), through `obstructed_tiles()` and
  `soft_sealed_tiles()`. `tests/test_world_passability.gd` lays its post as the game does: a
  precinct (`add_precinct()`), `index_posts()`, and the fixture takes the first tile
  `tiles_shut_to(Mover.POSTS)` holds, with a check that the tile is open ground of its own.
- **`ExcitementSource.player_velocity` is `_player_velocity`.** The frozen reference
  (`tests/fixtures/prediction_reference.gd`) is handed her velocity, as it is handed her sensitivity;
  the suite's told sources (`ToldEventSource`, `ToldCrowdSource`) keep the velocity the halo last told
  them in `set_her_motion()`. The two subclasses' projection keys read it as `_player_velocity`.
- **`LaneMover.view` is `_view`.** `tests/test_drawn_view.gd` hands a car and a walker its screen
  through `use_crowd_parts()`, the call the crowd makes, with nothing else handed (the other parts
  stay null, as the hand-built agent had them).
- **`Crowd.step` stays public, kept.** The live tick is the engine's physics frame, which a suite can
  give no delta and cannot wait out; the crowd-traffic skill asks a rig that steps the crowd to call
  `Crowd.step()`, the whole tick but the player half. Its line in `tools/test_only_members.txt`
  names that reason and no longer points at the item.

## Verification

Each converted read shown failing under a break and passing on restore: `is_finished()` returning
false fails `test_resistance_destination.gd`; the posts dropped from `BlockedLayer.blocks()` fails
three checks of `test_world_passability.gd`; the velocity not stored fails the reference parity of
`test_prediction_reuse.gd`; the view not stored fails three checks of `test_drawn_view.gd`; a no-op
`release_obstruction()` fails the map comparison of `test_day13_guard.gd`.

## The builder's choices, each open to overturn

- **`Crowd.step` is kept with a reason rather than made internal**, since its callers are rigs and
  suites in many files and the skill asks them to call it.
- **`player_expected_total_gross` is not converted**: the field-read check over a scratch copy with
  `tests/` under `src/` lists one read of it (`tests/test_prediction_reuse.gd`), which the item's
  list did not hold.
