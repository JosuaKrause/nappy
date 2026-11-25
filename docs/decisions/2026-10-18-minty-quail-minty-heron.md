# minty-quail — The HUD's, the badges', the danger vocabulary's and the texts' suites are typed · 2026-11-11

**The ask.** Test code is typed as the code it tests is ("we type when we can", inbox #1280 in
olive-ferret), and a test reads its subject only through methods (inbox #1182 in gray-dolphin):
`typed-everywhere.md`, one pass per module. This pass is the view's HUD, badges, danger vocabulary and
texts; its search covers `BadgeModel` and `BadgeModel.Subject`, `DangerEdge`, `MeterBar`, `HelpText`,
`SentenceLines`, `Texts` and `src/ui/hud.gd`.

## What was built

- **Six suites parse without their file-level opt-out line**, which each loses: `tests/test_hud.gd`
  (`unsafe_property_access`, `unsafe_method_access`), `tests/test_badge_model.gd` and
  `tests/test_danger.gd` (`untyped_declaration`), and `tests/test_sentence_lines.gd`,
  `tests/test_sentence_lines_render.gd` and `tests/test_texts_catalogue.gd` (`untyped_declaration`,
  `unsafe_method_access`).
- **The HUD and the day summary**, whose scripts have no class name, are named through preloads of
  their scripts, as `tests/finale_rig.gd` and `tests/test_main.gd` name them; the pause screen is typed
  as `PauseScreen`; loop variables take their writers' types; `test_danger`'s street rig is a preloaded
  script's instance.
- **Two reads converted** in `test_danger.gd`, both through `DangerEdge.announcing()`, which returns
  `model.announcing()` and which `DangerEdge._draw()` and the run log's observer also call:
  `edge.model.announcing()`, and `edge.model.has_badges()` as `not edge.announcing().is_empty()`
  (`BadgeModel.has_badges()` asks whether the list `announcing()` builds from is empty). No check deleted or
  moved, nothing under `src/` or the rigs changed.

## Fields read and written, by class

Built with `tools/field_answers.py --counts` on the six files. The searched classes' methods were
read in their class; the other classes' answers are the tool's.

- **`BadgeModel.Subject`** (searched): `approach_speed`, `charging`, `finished`, `key`, `left`,
  `logged_name`, `pending`, `position`, `shown`, `speed`, `warned`, read or written → no method (plain
  data the event source's adapter fills field by field).
- **`DangerEdge`** (searched): `atlas`, written → no method.
- **`HelpText`** (searched): `line` → no method (`show_line()` writes it).
- **`Baby`**: `excitement`, written → `reset()` sets it to 0.0; `state`, written → `reset()` and `force_sleep()` write it through the
  private `_set_state()`; neither sets a chosen state.
- **`CrowdAgent`**: `excitement` → `mood()`.
- **`DayEnd`**: `elapsed_seconds`, `reason`, `result`, written → no method.
- **`EventDef`**: `hard_fail` → `ends_the_day()`; `inner_radius` → `core_within()`; `look` →
  `picture()`; `mobile` → `moves()`; `outer_radius` → `heard_within()`; `pulse_period` →
  `pulses_every()`; `telegraph_time` → `telegraphs_for()`; `pursuit` (read and written), `speed` → no
  method; written: `id`, `inner_radius`, `intensity`, `outer_radius`, `telegraph_time` → no method.
- **`EventInstance`**: `def` → `row()`; `def.telegraph_time` → `telegraphs_for()`; `excitement` →
  `source()`; `atlas`, written, and `drawer`, read and written → no method.
- **`EventManager`**: `streaming`, `warnings` → no method.
- **`ExcitementSource`**: `player_at`, read through `CrowdExcitement` → no method.
- **`ResistanceRunState`**: `completed_steps`, `progress`, written → the game writes both through
  `RunState.complete_resistance_step()`, which appends a chosen step; `give_back()` and `restore()`
  assign both, and `reset()` assigns `progress` and clears `completed_steps`.
- **`ResistanceSteps.Step`**: `brief` (read and written), `header`, `index`, `is_pickup`,
  `needs_goal`, `title` → no method.
- **`RunHeader`**: `day`, written → `reset()` and `restore()` assign it; neither sets a chosen day.
- **`RunState`**: `header`, `resistance` → no method.
- **`Stroller`**: `carrying`, written → no method; `facing`, written → `reset_at()` sets it from a
  look vector.
- **`SummaryModel`**: `title` → `title_text()` (not this pass's search).
- **`WorldMap`**: `world`, written → no method.

## Verified

At test parity: the six suites pass; the typing census and the field-read check pass.
