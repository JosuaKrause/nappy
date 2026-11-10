# minty-quail — A look is handed its row and its drawer, and the base look asks the live event through methods (minty-quail, the events' interface) · 2026-11-10

**The ask.** "never read fields directly. always read through a method", and "fields are not API
interaction between different objects need to go through APIs" (inbox #1173 in gray-dolphin). The
events' interface design's row 2b, "the looks ask the live event and are handed their settings"
(`docs/todo/2026-10-18-minty-quail/event-interface.md`), is built as six pull requests, a cut a
Fable planning agent made and no tracked file holds: a probe of what every row's look draws
(minty-quail-polite-newt), the footprints asking the row, this one, then the looks drawn on the
event's own canvas, the looks drawn in slices with the scenery, and the roadblock's look.

## What was built

- **The base look (`EventLook`, `src/events/views/event_look.gd`) is handed its row, its drawer and
  whether it draws**, in its constructor (`_init(owner, row, drawer, skip_draw)`); `EventInstance.setup()`
  makes it with `EventLooks.for_row(self, definition, drawer, skip_draw)`, which picks the class by
  the row's `picture()`. It reads no field of its row or of the live event but the event's `age`,
  twice (the caret's flash and a mast telegraphing now), since `age()` cannot be a method while the
  variable stays.
- **Questions added**: the row's `casts_a_shadow()` (whether a shadow is put down under its body)
  and `peak()` (the field's peak intensity); the live event's `is_silenced()`,
  `where_its_placards_point()` (`Vector2.INF` while unset) and `walks()` (its route).
- **Two answers moved into the family that owns them**: the roadblock guard's facing at his post
  is `RoadblockLook.drawn_heading()`, and the van victim's stride
  `EventVehicleLook.victim_gait_is_stepping()` (the base answers false). The caret's flash is one
  function, `_mark_is_flashed_off()`; `_mark_swell()` is `_share_of_its_peak_now()`, so the slice
  looks and the fire's look can call it in their pull requests.
- **The nine family looks are unchanged** and still read `event.def` and `event.drawer`; their two
  pull requests convert them.
- **Five suites hand the drawer before `setup()`**, as the spawner does (`test_danger`,
  `test_event_views`, `test_heat`, `test_protest`, `test_frame_record`); nothing under `src/` sets a
  drawer, an atlas or whether an event draws after `setup()`.
- `docs/ARCHITECTURE.md`'s `views/` paragraph and `docs/EVENTS.md`'s vocabulary cell name the
  hand-in and the renamed swell. `tools/field_reads.txt` lost 31 lines and gained none.

## A member kept public for a suite, open to the player's overturn

`tools/test_only_members.txt` gains `event_look.gd victim_gait_is_stepping` in its `[kept]` group for
lines the check misreads: the check does not count `EventVehicleLook` as a reader, since that file
declares the name too, and `tests/test_event_strides.gd` reads it on three lines. It goes when that
suite reads the victim's frame off a recording drawer.

## Parity

The run log is line for line what it was (`tools/test.sh observers`), and the cost table is
unchanged (`tools/cost-table.sh --check`). On `main` at `651606332`, the commit this branch was made
from, and on the code commit `b8c008e55`, each probe gives one hash: what every source charges her
(`probes/excitement_fingerprint.gd`, its `XF` lines less `XF_COST`), every event, crowd agent and
meter on every tick (`probes/m159_tick_sweep_events_cost.gd`, the `chain` values), and what every
row's look draws (`probes/look_fingerprint.gd`, its `LK` lines), run with the probe file from its
own pull request at `943ed9d8b` and again at `77b1cbaee`, the same file in both trees each time.
What a look draws straight on the canvas no probe sees: `_draw_body_shadow()` changed only where it
asks (`casts_a_shadow()`, `body_pieces()`).

## Choices the builder made where the design was silent, open to the player's overturn

- **The look is handed its drawer once, at setup**, not asked for it on each draw, since nothing
  under `src/` sets a drawer after `setup()`.
- **`_protest_objective()` stays a one-line private helper of the base** that asks the event, since
  `RankLook`, which calls it, is a later pull request's.
- **Names the design does not give**: `where_its_placards_point()`, `_share_of_its_peak_now()`,
  `_mark_is_flashed_off()`.
