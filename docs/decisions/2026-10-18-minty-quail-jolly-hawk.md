# minty-quail — The last survey for code nothing reaches (minty-quail, F3) · 2026-11-24

The survey over `src/` and `tools/` that `dead-code-sweep.md` asked for after the module sweeps
ran once the events, the crowd, the city and the tests' passes had merged, and it closes that item
(inbox #1180 in gray-dolphin: code nothing reaches, and code for a feature the game no longer has,
is deleted). What holds after it: `designing-classes` carries the rule, `tools/check_test_only_members.py`
and `tools/check_field_reads.py` hold the two ways code stays reachable only by tests, and a
module's pass deletes what it finds.

**How it was run, with comments stripped** (a name in a comment is not a use):

- every definition under `src/` (func, var, const, signal, class, enum, `class_name`) counted as a
  word over `src/`, `tests/`, `tools/`, `scenes/`, `scene-recipes/`, `assets/` and `project.godot`,
  strings kept so `call("name")` and scene files count: one name with no use beyond its own definition;
- the receiver typing of `check_test_only_members.py` driven over every public member for ones with no
  reader in `src/`, none in the tests and none in their own file, and over every private member the
  same way;
- every signal against its `emit` and its `connect` (the visit counter connects through a list of pairs,
  so a bare `connect` search is not enough), every enum value, every file under `src/`, `tools/`,
  `scenes/` and `scene-recipes/` against any reference by name or path, and every Python and shell
  definition under `tools/` against its uses outside its own tests.

**Deleted** (nothing reaches it):

- `EventBehaviours.notice_run()`, an accessor of the behaviour a waiting row runs once it has noticed
  her; the composer holds the behaviour itself and nothing asks the accessor.
- `InteriorTile.Kind.ENTRANCE_BARRICADE`, a kind never painted, listed in no tile table; the barricade
  is the interior scene's own texture, drawn in front of the entrance door.
- `FieldSpec.falling_off()`, the builder of a row's own drop-off exponent that no catalogue row calls
  (`check_test_only_members.py` does not list it; its one reader is `tests/test_prediction_reuse.gd`). The exponent is the constant `FieldSpec._FALLOFF` (2.0, the curve every row is measured at);
  the `falloff <= 0` refusal in `EventDef.validate()` can no longer fire and goes with it, the one
  test row that varied the exponent goes, and the comments and `docs/EVENTS.md`'s builder list that
  named the knob are made true. `Field.falloff()` keeps its `power` parameter, since the engine's
  own default is the same 2.0.

**Kept, and why:**

- The 133 kept lines of `tools/test_only_members.txt` (hand-ins, relationship tests, members only a
  draw call or a headless run cannot show): each already carries its reason.
- `MarbleBag.ran_empty()`, `EventInstance.walk_back_to()` and `call_back_its_officers()`,
  `RoadblockLook.draw_the_far_guard()`, `SpreadLook.draw_the_slice()`, `FrameRecorder.at_process_end()`
  and `ExcitementSources.holds_her_alone()`: the driver listed them, each is called on another instance
  of its own class or through an override, which a receiver the typing cannot tell hides.
- `InteriorTile.Kind` values `HALLWAY_FLOOR`, `HALLWAY_FLOOR_EDGE_E`, `_W`, `STAIR_FLIGHT_E`, `_W` and
  `LANDING`: never painted, but each has an atlas member under `art/interior/`; deleting the kind
  without its art leaves an orphan member, and the art is the svg-art skill's. Left for the orchestrator.
- `scenes/dev/roof_*_preview.tscn` and their scripts: review rigs that write evidence pictures, started
  by hand, with no tool or test naming them. Left for the orchestrator's ruling.
- `Building._Furniture._UNUSED_DUCT_CORNER`: the seeded roof layout's reserved value, which keeps every
  other furniture value stable.
- `tools/check_test_only_members.py`'s `test_only()`: the seam its own unit tests drive.
