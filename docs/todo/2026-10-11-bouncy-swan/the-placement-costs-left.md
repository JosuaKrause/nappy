*Proposed, not asked for:* the placement audit's remaining options, none of them a measured spike.

- **A binary search in `_ensure_the_city_is_still_walkable()`**, dropping the same blockers with a
  logarithmic number of floods; it matters only on a dawn that drops many, which was not measured.
- **Door points passed in `ResistanceDirector._add_a_mast_near()`**, as `MastSites` now builds them
  once per `compute()`; it changes no placement.
- **A failed `_way_on_out_of_sight()` search remembered for a while**, so a leaving body stops
  searching up to 4096 tiles every frame; it changes when the body asks again, so it goes to the
  player first.
- **Skipping identical unplaced copies in a look** is not taken: it changes how much the crews'
  stream is drawn, and the look's shared verdicts already leave about 0.24 ms a look on day 9.
