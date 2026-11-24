# minty-quail — The last survey for code nothing reaches (minty-quail, F3) · 2026-11-24

The survey over `src/` and `tools/` that `dead-code-sweep.md` asked for after the module sweeps
ran once the events, the crowd, the city and the tests' passes had merged, and it closes that
item (inbox #1180 in gray-dolphin: code nothing reaches, and code for a feature the game no
longer has, is deleted). What holds after it: `designing-classes` carries the rule,
`tools/check_test_only_members.py` and `tools/check_field_reads.py` hold the two ways code stays
reachable only by tests, and a module's pass deletes what it finds. Nothing is left for later:
every candidate the survey found is deleted or kept below with its reason.

**How it was run, with comments stripped** (a name in a comment is not a use):

- every definition under `src/` (func, var, const, signal, class, enum, `class_name`) counted as
  a word over `src/`, `tests/`, `tools/`, `scenes/`, `scene-recipes/`, `assets/` and
  `project.godot`, strings kept so `call("name")` and scene files count: one name with no use
  beyond its own definition;
- the receiver typing of `check_test_only_members.py` driven over every public member for ones
  with no reader in `src/`, none in the tests and none in their own file, and over every private
  member the same way;
- every signal against its `emit` and its `connect` (the visit counter connects through a list
  of pairs, so a bare `connect` search is not enough), every enum value, every file under
  `src/`, `tools/`, `scenes/` and `scene-recipes/` against any reference by name or path, and
  every Python and shell definition under `tools/` against its uses outside its own tests;
- a rig started by hand counts as one more thing nothing reaches: no tool, test, recipe or dev
  flag starts it, and a doc that gives it as a rerun command is answered by the revision that
  doc pins.

**Deleted** (nothing reaches it):

- `EventBehaviours.notice_run()`, an accessor of the behaviour a waiting row runs once it has
  noticed her; the composer holds the behaviour itself and nothing asks the accessor.
- `FieldSpec.falling_off()`, the builder of a row's own drop-off exponent that no catalogue row
  calls (its one reader was `tests/test_prediction_reuse.gd`), and with it the knob: the
  `falloff <= 0` refusal in `EventDef.validate()` could no longer fire, `Field.falloff()` lost
  its `power` parameter (the square `1 - t * t` is its one curve, so the branch that raised to
  another power is gone), `FieldSpec._band_crossing()` takes the square root only, and the
  curve's 2.0 lives nowhere as a number. `FieldSpec.falloff()` and `EventDef.falloff()` answered
  a constant, so they went too, with the `falloff_power` column of `docs/COSTS.md` (2.0 on every
  row; `tools/cost_table.gd` and the table are regenerated, the column the only change).
  `docs/EVENTS.md` and `docs/MECHANICS.md` say the square is the one curve.
- Eight `InteriorTile.Kind` values no map paints, each checked by name over `src/`, `tests/`,
  `tools/`, `scenes/` and `scene-recipes/` (the generators `InteriorMap` and `InteriorMapPlan`
  paint `HALLWAY_FLOOR_EDGE_N`/`_S`, `BASEMENT_FLOOR` and `BASEMENT_FLOOR_EDGE_N`/`_S` and
  nothing else of these): `HALLWAY_FLOOR`, `HALLWAY_FLOOR_EDGE_E`, `HALLWAY_FLOOR_EDGE_W`,
  `BASEMENT_FLOOR_EDGE_E`, `BASEMENT_FLOOR_EDGE_W`, `STAIR_FLIGHT_E`, `STAIR_FLIGHT_W` and
  `LANDING`. Their only mentions were the enum, the walkable table, `flight_direction()`, the
  tileset's source table, the stair kit of `tests/test_interior.gd` and the eight atlas members
  of `assets/atlases/membership.json`, all taken out. Their own comments kept six of them for a
  later hallway or flight, which the player's rule forbids (inbox #1180 in gray-dolphin);
  nothing plans one. The flights' last use was the basement's entry stair, which the player
  called bad (PLAYTEST-84 2), and `stair_down` replaced it; the landing art is in the
  rejected-graphics archive (M165). `InteriorTile.Kind.ENTRANCE_BARRICADE`, also never painted,
  went with the first pass. The art files stay on disk and move in `docs/GRAPHICS.md` to
  "Unbound, with nothing to bind them"; no SVG is edited. Taking a value out of the enum moves
  the later ones down by one, which nothing stores: `InteriorTileSet` keys its sources on the
  kind and no save, scene, recipe or test holds a number.
- The three roof preview rigs (`scenes/dev/roof_{context,scale,network}_preview.tscn` and their
  three scripts) and `Building.lay_roof_furniture()`, which only the network rig called. Nothing
  runs them, the roof art they show is live and accepted, and four refactor passes had carried
  them. The evidence folders that give them as a rerun command pin the revision to check out:
  `roof-equipment-scale-2026-10-03` and `roof-networks-2026-10-03` already did, and
  `m109-roof-context-2026-09-30` now names its capture revision (the squashed commit of pull
  request 441, which holds the folder and the scene).

**Kept, and why:**

- The 133 kept lines of `tools/test_only_members.txt` (hand-ins, relationship tests, members
  only a draw call or a headless run cannot show): each already carries its reason.
- `MarbleBag.ran_empty()`, `EventInstance.walk_back_to()` and `call_back_its_officers()`,
  `RoadblockLook.draw_the_far_guard()`, `SpreadLook.draw_the_slice()`,
  `FrameRecorder.at_process_end()` and `ExcitementSources.holds_her_alone()`: the driver listed
  them, each is called on another instance of its own class or through an override, which a
  receiver the typing cannot tell hides.
- `Building._Furniture._UNUSED_DUCT_CORNER`: the seeded roof layout's reserved value, which
  keeps every other furniture value stable.
- `tools/check_test_only_members.py`'s `test_only()`: the seam its own unit tests drive.
