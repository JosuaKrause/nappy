# minty-quail — The city map's files are typed and the blocked layer keeps its fields to itself · 2026-11-10

**The ask.** "never read fields directly. always read through a method" (inbox #1173 in
gray-dolphin), and every receiver gets a class the field-read check can tell, which the player
asked to be made working (inbox #1268 in olive-ferret). A Fable planning agent cut two things in
the city's model: five of its files typed, and the blocked layer (`BlockedLayer`, what blocks each
tile of the walking lattice) asked through methods by the two maps that read it.

## What was built

- **Five files lose their opt-out line**: `src/city/city_map.gd`, `city_generator.gd` and
  `street_trees.gd` type their loop variables; `marble_bag.gd` reads two `peek()` calls through
  `as MarbleBag`; `city_state.gd` reads an enum key through a `String`. The generator reads its
  power station's blocks and door block by subscript of a typed `Dictionary`, the same values. No
  tile and no guarantee changes.
- **`BlockedLayer`'s five fields are underscore-private**, and the two maps ask it:
  `lay_posts(at)` (from `CityMap.index_posts()`), `todays_closed_tiles()` and
  `replace_closed_tiles()`, `todays_soft_sealed_tiles()` and `replace_soft_sealed_tiles()` (behind
  the map's `closed_tiles` and `soft_sealed_tiles`), `todays_body_tiles()` and
  `body_ground_changes()` (behind `WorldMap.obstructed_tiles` and `obstruction_version`). The
  questions about posts reuse the layer's existing `blocks(tile, Mover.POSTS)` and
  `tiles_of(Mover.POSTS)`.
- **Two setters with no writer are deleted**: those of `WorldMap.obstructed_tiles` and
  `obstruction_version`; nothing under `src/`, `tests/` or `tools/` wrote through them.
- **`CityMap.post_tiles()` answers a copy**; its readers only read it, and its doc says so.
- **The map's four properties keep their names and hand out the live dictionary**, since the
  closure planner (`closure_planner.gd`) and tests write through it.
- `tests/test_world_passability.gd` and `tests/test_day13_guard.gd` ask the layer through its
  methods; `tools/field_reads.txt` loses the layer's lines.

## Parity

The excitement fingerprint (what every source charges her) and the events tick sweep's chains give
one hash each on `main` at `651606332` and on the pull request's head.

## Choices open to the player's overturn

- **The names** `todays_closed_tiles()`, `todays_soft_sealed_tiles()`, `todays_body_tiles()`,
  `replace_closed_tiles()`, `replace_soft_sealed_tiles()`, `body_ground_changes()` and
  `lay_posts()`, the builder's.
- **The live dictionary behind the map's properties**, kept because writers outside the map use it;
  a map that hands out only copies would move those writes to methods first.
