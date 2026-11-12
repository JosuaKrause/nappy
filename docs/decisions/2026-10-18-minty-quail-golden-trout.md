# minty-quail — The frame record's and the encounter watch's suites are typed · 2026-11-11

**The ask.** Test code is typed as the code it tests is ("we type when we can", inbox #1280 in
olive-ferret), and a test reads its subject only through methods (inbox #1182 in gray-dolphin):
`typed-everywhere.md`, one pass per module. This pass is the observers; its search covers `FrameLedger`,
`FrameRecord`, `FrameRecorder`, `FrameTraceBuffer`, `FrameTiming` and `EncounterWatch`.

## What was built

- **Four suites parse without their file-level opt-out line**, which each loses: `tests/test_frame_record.gd`
  (`untyped_declaration`, `unsafe_property_access`, `unsafe_method_access`), and `test_frame_record_wiring.gd`,
  `test_frame_trace.gd` and `test_encounters.gd` (`unsafe_method_access`).
- **Typing**: report dictionaries are read through typed locals and loops take their types; the draw-kinds table
  is an `Array[CanvasItem]` beside an `Array[int]` (a `Dictionary` keyed by the nodes fails at run time, since the
  loop frees its keys); the wiring suite's `before` callback takes the main scene's script type, the type
  `Boot.Booted.main` already has; `test_encounters` instances its scenes through typed `PackedScene` constants.
- **No read converted**: none of these suites reads a field of a searched class. The one field written,
  `EncounterWatch.day` (twice in `test_encounters`), has no method, and the game writes it the same way
  (`EventManager`). No check deleted or moved; nothing under `src/`, the rigs or `tools/test_only_members.txt`
  changed; `test_frame_record_wiring`'s six `timing` reads stay, as `tests-one-module.md` entry 1 names them.

## Fields read and written, by class

`tools/field_answers.py --counts` on the four files, as it prints them at f0b09a779, each named method read in its
class. None is converted: the only searched class among them is `EncounterWatch`, whose one field has no method,
and every other class's fields are left for their own modules' passes.

- `Baby`: `timing` read (`tests/test_frame_record_wiring.gd` on 1 line): no method
- `City`: `crowd` read (`tests/test_frame_record_wiring.gd` on 2 lines): no method; `events` read (`tests/test_encounters.gd` on 4 lines, `tests/test_frame_record_wiring.gd` on 1 line): no method; `frame_timing` read (`tests/test_frame_record_wiring.gd` on 1 line): no method; `map` read (`tests/test_encounters.gd` on 4 lines): no method; `scenery` read (`tests/test_frame_record_wiring.gd` on 1 line): no method
- `CrowdAgent`: `excitement` read (`tests/test_frame_record_wiring.gd` on 2 lines): `mood()` (6 calls)
- `DangerEdge`: `timing` read (`tests/test_frame_record_wiring.gd` on 1 line): no method
- `EncounterWatch`: `day` written (`tests/test_encounters.gd` on 2 lines): no method
- `EventDef`: `id` read (`tests/test_encounters.gd` on 1 line): no method; `look` read (`tests/test_encounters.gd` on 1 line): `picture()` (38 calls); `obstructs_radius` read (`tests/test_encounters.gd` on 1 line): `obstructs_within()` (7 calls); of it alone, `has_a_body()` returns `obstructs_radius > 0.0` (7 calls); `pursuit` read (`tests/test_encounters.gd` on 1 line): no method; `telegraph_time` read (`tests/test_encounters.gd` on 1 line, `tests/test_frame_record.gd` on 1 line): `telegraphs_for()` (5 calls)
- `EventInstance`: `age` read (`tests/test_frame_record.gd` on 2 lines): on its view, `EventInstance.Figure.age()` (13 calls), a view no public method hands out; `age` written (`tests/test_frame_record.gd` on 1 line): `resume()` does `age = from_age` (3 calls); `came_under_a_warning` written (`tests/test_encounters.gd` on 2 lines): no method; `def` read (`tests/test_encounters.gd` on 9 lines): `row()` (2 calls); `def.detain_distance()` read (`tests/test_encounters.gd` on 2 lines): `detain_distance()` (3 calls); `def.hard_fail` read (`tests/test_encounters.gd` on 1 line): `ends_the_day()` (1 call); `def.telegraph_time` read (`tests/test_encounters.gd` on 2 lines): `telegraphs_for()` (1 call); `drawer` read (`tests/test_frame_record.gd` on 1 line): no method; `excitement` read (`tests/test_encounters.gd` on 13 lines): `source()` (16 calls); `held_by_hand` written (`tests/test_encounters.gd` on 2 lines): no method; `look` read (`tests/test_frame_record.gd` on 1 line): no method; `look` written (`tests/test_frame_record.gd` on 1 line): `setup()` does `look = EventLooks.for_row(self, definition, drawer, skip_draw, barrier_post)` (1 call); `timing` written (`tests/test_frame_record.gd` on 1 line): no method
- `EventManager`: `checkpoints` read (`tests/test_encounters.gd` on 2 lines): no method; `timing` read (`tests/test_frame_record_wiring.gd` on 1 line): no method; `world` read (`tests/test_encounters.gd` on 1 line): no method
- `EventWorld`: `map` read (`tests/test_encounters.gd` on 1 line): no method
- `ExcitementHalo`: `timing` read (`tests/test_frame_record_wiring.gd` on 1 line): no method
- `ExcitementSource`: `landed_ever` read through `EventExcitement` (`tests/test_encounters.gd` on 4 lines): no method
- `PursuitSpec`: `warns_for` read (`tests/test_encounters.gd` on 1 line): no method
- `RunConfig`: `frame_record_requested` read (`tests/test_frame_record.gd` on 5 lines): no method
- `RunHeader`: `day` read (`tests/test_frame_record_wiring.gd` on 1 line): no method
- `RunState`: `header` read (`tests/test_frame_record_wiring.gd` on 1 line): no method
- `SceneryResidency`: `timing` read (`tests/test_frame_record_wiring.gd` on 1 line): no method
- `ScreenCover`: `left` read (`tests/test_encounters.gd` on 3 lines): `left_corner()` (2 calls); `right` read (`tests/test_encounters.gd` on 2 lines): `right_corner()` (2 calls)
- `TouchControls`: `covering` read (`tests/test_encounters.gd` on 1 line): no method
- `WorldMap`: `world` read (`tests/test_encounters.gd` on 1 line): no method; of it alone, `has_world()` returns `world != null and is_instance_valid(world)` (3 calls, +1 own); `world` written through `CityMap` (`tests/test_encounters.gd` on 1 line): no method
- Receiver's class not told: `tests/test_frame_record.gd:224` `rig.recorder`
- Receiver's class not told: `tests/test_frame_record.gd:562` `rig.recorder`

The two lines whose receiver's class is not told, `rig.recorder` in `test_frame_record`, read the suite's own
inner class's typed `FrameRecorder`, not another module's field.

## Verified

At test parity: the four suites pass; the typing census, `./tools/check.sh`, the field-read and the test-only-member
checks pass.
