# minty-quail — The event pictures' and the autoloads' unreached members are deleted · 2026-11-07

minty-quail's `dead-code-sweep.md`, `src/events/views/` and `src/autoload/`, in #1239, a commit per
class; each member re-checked unreached across `src/`, `tests/`, `tools/`, `scenes/` and
`project.godot`, comments aside.

**Deleted.**
- **`EventPictures.CAFE_SITTER`, `CHATTING_MOTHER_TALKING`, `ROBBER_WAITING` and `VAN_VICTIM`**
  (`src/events/views/event_pictures.gd`): atlas-key strings nothing read, only their `*_BY_VIEW`
  tables being looked up; the last read went with #861, which moved the looks under
  `src/events/views/`.
- **`Telemetry.SHOT_SPACING`** (`src/autoload/telemetry.gd`), an alias of `TelemetryShots.SPACING`
  nothing used since #976 moved the snapshot gate into `TelemetryShots`; its comments and
  `docs/TELEMETRY.md` name `TelemetryShots.SPACING`.

**Kept.** `EventLook.drawn_rect_now` moves from the check's `[no reader]` group to `[kept]`:
`test_no_pop_in`, `test_drawn_view` and `test_resistance_traps` hold the arrival promise (a thing is
wholly off screen on its first frame) against it, and a headless run draws no pixels while the
danger caret is drawn straight onto the event, so nothing else holds the extent; the same reason
`mark_rect` has (record minty-quail-olive-sparrow).

**Left.** `ParkCordon._point_at`, named nowhere, sits in a file #1169 holds; the item names it.
