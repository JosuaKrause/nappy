# minty-quail — The events' picture suites are typed · 2026-11-11

**The ask.** Test code is typed as the code it tests is ("we type when we can", inbox #1280 in
olive-ferret), and a test reads its subject only through methods (inbox #1182 in gray-dolphin):
`typed-everywhere.md`, one pass per module. This pass is the events' pictures (`src/events/views/`),
search none: the row's, the live event's, the plan's and a spec's fields go with row 4a's scripted
rewrite (`event-interface.md`), so it types, deletes the opt-out lines and converts no read.

## What was built

- **Four suites parse without their file-level opt-out line**, which each loses:
  `tests/test_event_views.gd`, `tests/test_event_redraw.gd` and `tests/test_event_strides.gd`
  (`untyped_declaration`, `unsafe_method_access`), and `tests/test_protest.gd` (`untyped_declaration`).
- **Each `for` variable takes the narrowest type its writer gives** (`String`, `Array`, `bool`,
  `Vector2`, `float`, `EventDef.Look`), and a recorded draw's picture is read through a `String`
  local before it is asked a string's question.
- No check deleted or moved; nothing under `src/`, `tools/test_only_members.txt` or the two helpers
  the suites load (`tests/drawn_event.gd`, `tests/recording_event_drawer.gd`) changed.

## Fields read and written, by class

Built with `tools/field_answers.py --counts` on the four files, each named method read in its class.
None is converted (search none).

- **`AbductionSpec`**: `taken_over` → no method.
- **`City`**: `events`, `map`, `run`, `spawn_siting` → no method.
- **`CityMap`**: `alley_rects` → `alley_lots()`.
- **`EventDef`**: `look` → `picture()`; `hard_fail` → `ends_the_day()`; `telegraph_time` →
  `telegraphs_for()`; `obstructs_radius` → `obstructs_within()`; `outer_radius` → `heard_within()`;
  `pulse_period` → `pulses_every()`; `draws_body_shadow` → `casts_a_shadow()`; `shape` →
  `ground_shape()`; `abduction`, `pursuit`, `notice` → no method (`waits_for_her()` answers
  `notice != null`, not the read). Written: `shape` (`solid()` also sets `obstructs_radius` and drops
  the cached parts, so it is not the test's write), `solid_parts`, `hard_fail` → no method.
- **`EventInstance`**: `def` → `row()`; `excitement` → `source()`; `is_finished` → `is_gone()`;
  `is_leaving` → `is_on_its_way_out()`; `flock.birds` → `birds()`, behind a guard; `abduction`,
  `barrier_post`, `departure`, `drawer`, `flock`, `points_at`, `look` → no method. Written: `atlas`,
  `drawer`, `gate_state`, `held_by_hand`, `silenced` → no method; `age` (`resume()` also sets the
  path travelled, guards a non-positive age and restarts the notice, so it is not the test's write).
- **`EventManager`**: `points_at`, `world` → no method.
- **`EventWorld`**: `drawer`, read and written → no method.
- **`NoticeSpec`**: `runs_within` → no method.
- **`PursuitSpec`**: `stands` → `stands_for_its_notice()`; `warns_for` → no method.
- **`RegionPlanner.GateState`**: `raised`, written → no method.
- **`ResistanceSteps.Step`**: `is_pickup` → no method.

## Verified

At test parity: the four suites pass; the typing census and the field-read check pass.
