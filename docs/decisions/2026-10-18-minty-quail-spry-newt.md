# minty-quail — Tests stop reaching private parts by routes the count misses (tests through public seams) · 2026-11-05


minty-quail's `tests-unseen-reads.md`, section 1: the private members tests reached by routes the
count commands miss. Tests only; no `src/` change.

**Built.**
- `tests/crowd_rig.gd` places its gate across a bucket edge by the corridor geometry it already
  knows (`4 * TILE_SIZE`) instead of reading `Crowd._LINE_BUCKET`, and its check that the bucket
  width equals the private constant goes.
- `test_atlas_leaf_consumers.gd` and `test_atlas_loading.gd` sweep every `ui/` region name the
  baked table holds and check each is on the `ui` page, instead of reading the private icon
  constants; `ModeButton` is asked for each of its symbols and must hand back an icon.
- `test_scene_recipe_activity.gd` compares the recipe's roof fixtures with `Building.roof_layout()`,
  the layout the roof is drawn from, through a map from fixture kind to the building's public
  texture names, instead of indexing the private `_Furniture` enum.
- `test_event_redraw.gd` copies a row with `duplicate()` and its shape and solid parts by hand, as
  `EventDef.at_heat()` and `as_warned_first()` copy one; `test_resistance_placement_kinds.gd` copies a
  step's public fields by name.
- `test_main.gd` checks the resistance director takes no frame callback through `is_processing()`
  instead of `has_method("_process")`.
- `test_touch.gd`'s read of the focus knob's offset and radius stays, named beside the read: the
  knob is drawn by `draw_circle()` on the control with no drawer, and a headless run draws no pixels.

**Open to overturn:** the director check says no frame callback is enabled, not that its clock
ignores frame length (a behavioural check wants a public read of its elapsed time, which it has
none of); the crowd rig no longer notices a change to the bucket width; only `ModeButton`'s symbols
are asked of the node, the pause, run and save icons resting on the page sweep, so a typo in their
private names is no longer caught; the roof comparison holds a second copy of the fixture kinds; a
field added to a step is not copied until its line is added to the helper.
