# minty-quail — The screen-edge badge is typed: its stand-ins extend the event manager and its opt-out line goes · 2026-11-19

**The ask.** Code is typed wherever the language can type it, the tests included: "we type when we
can. with the public seams tests you won't have to keep things untyped to make it work" (inbox #1280
in olive-ferret); every receiver gets a class the field-read check can tell (inbox #1268 in
olive-ferret). This is the screen-edge badge's bullet of `field-reads.md` ("What is left of the
typing under `src/`"): the badge (`src/ui/danger_edge.gd`) held its event source as a `Node` and
asked it with `has_method()`, because three test stand-ins extended a bare `Node`, and it waited for
those stand-ins to extend `EventManager` and for its fallback to a view of its own to go (the record
2026-10-18-minty-quail-tawny-toad). The badge's earlier underscore pass is the record
2026-10-18-minty-quail-golden-toad.

## What was built

- **`src/ui/danger_edge.gd` parses without its file-level opt-out line** (`unsafe_method_access`).
  It holds its event source typed (`_events: EventManager`, `setup(events: EventManager, player)`)
  and asks it directly for `instances()`, `pending_warnings()` and `visible_view()`. The two
  wrappers that existed only to type a duck-typed answer, `_live()` and `_warnings()`, go, and so do
  the three `has_method()` tests.
- **The badge's fallback to a view of its own goes**: `_own_view`, and the look through it from her
  camera at the start of every `_measure()`. Nothing in the game used it. `main._add_danger_edge()`
  hands `main._event_source()`, which is typed `EventManager`: the city's events, or the building's
  in the escape's first section, or null before either exists, when `_measure()` and `_draw()`
  return at once as before. Every suite and rig that hands the edge something hands a real manager
  (`tests/masked_man_meeting.gd`, `test_pelican.gd`, `test_interior.gd`, `test_events_pursuit.gd`,
  `test_danger.gd`, `test_drawn_view.gd`). Only the three stand-ins lacked `visible_view()`.
- **The three stand-ins extend `EventManager`** and override only what their test hands in, so the
  rest of each is the manager's own:
  - `_Source` in `tests/test_badge_model.gd` overrides `pending_warnings()` and returns the warnings
    the drawing test puts up, its list renamed `held` because `warnings` is the manager's own field
    (its `WarningBoard`). Its instances are the manager's own, none. Its view is the manager's own,
    never looked through, so it sees nothing. The six warnings are pending, and a pending warning is
    announced whether or not it is on screen, so the six are listed and drawn as before. It is no
    longer added to the tree: the edge reaches it only by calls, and a manager in the tree would
    take its own physics ticks and hold an atlas page during the frames the test waits for.
  - `_Source` in `tests/test_visible_view.gd` overrides `instances()` alone. The view the edge reads
    is the manager's own (`visible_view()`). The joystick's covered corners reach it through
    `use_controls()`, the way `main` hands them, and the test looks it through in place of the
    manager's tick, as it looked through its stand-in's view before.
  - `Source` in `tests/probes/m226_arrival_timing.gd` overrides `instances()` and
    `pending_warnings()`, its list renamed `pending` for the same reason. Before each `_measure()`
    it looks the manager's own view through from her (`Stroller.view_centre_of(player)`). That is
    the look the edge's fallback took at the start of `_measure()`, and the one the manager's own
    tick takes (`EventManager._look_through_the_camera()`).
- **No read is exposed and none is added to `tools/field_reads.txt`**: typed, the badge reads no
  field of another class that the check counts. Its writes of `BadgeModel.Subject`'s fields, a plain
  record the badge fills, are an inner class's, which the check does not see as fields (the record
  2026-10-18-minty-quail-tawny-toad leaves them for the same reason). `tools/test_only_members.txt`
  gains no line.

**Rejected.**

- *Keeping a `view` field and a `visible_view()` override in the visible-view stand-in, as before.*
  The manager's own view, with the controls handed through `use_controls()`, is the one the game
  reads, so the override would only have copied it.
- *Putting the drawing test's warnings on the real manager's board (`warn_first()`) instead of
  overriding `pending_warnings()`.* That suite tests the badge and its model. How the board puts up a
  warning is the board's own suite's to test (writing-tests, "Only mock what you do not want to
  test").
- *Typing `setup()`'s parameter while keeping the fallback.* With every source a manager, the
  fallback's branch could not be reached, and code nothing reaches is deleted (designing-classes).

## Fields read and written, by class

`tools/field_answers.py --counts` on the four files, as it prints them on this branch. The tests'
reads of other classes' fields are left to the suites' conversion to one module
(`tests-one-module.md`), as `typed-everywhere.md` says.

Fields of classes under `src/` that `src/ui/danger_edge.gd`, `tests/test_badge_model.gd`, `tests/test_visible_view.gd`, `tests/probes/m226_arrival_timing.gd` read or write through a receiver of that class, each with the method of the class that answers it (`tools/field_answers.py`). `(N calls)` counts a method's calls under `src/` outside its own file, `+N own` those in its own file, `+N untold` the calls of that name whose receiver's class cannot be told.
- `BadgeModel.Subject`: `announces` written (`src/ui/danger_edge.gd` on 1 line): no method; `approach_speed` read (`tests/test_badge_model.gd` on 16 lines): no method; `approach_speed` written (`src/ui/danger_edge.gd` on 1 line, `tests/test_badge_model.gd` on 1 line): no method; `charging` written (`src/ui/danger_edge.gd` on 1 line, `tests/test_badge_model.gd` on 3 lines): no method; `finished` written (`src/ui/danger_edge.gd` on 1 line, `tests/test_badge_model.gd` on 1 line): no method; `heard_within` written (`src/ui/danger_edge.gd` on 1 line): no method; `key` written (`src/ui/danger_edge.gd` on 1 line, `tests/test_badge_model.gd` on 1 line): no method; `left` written (`src/ui/danger_edge.gd` on 1 line, `tests/test_badge_model.gd` on 5 lines): no method; `logged_name` written (`src/ui/danger_edge.gd` on 2 lines, `tests/test_badge_model.gd` on 19 lines): no method; `payload` written (`src/ui/danger_edge.gd` on 1 line): no method; `pending` written (`src/ui/danger_edge.gd` on 1 line, `tests/test_badge_model.gd` on 5 lines): no method; `position` read (`tests/test_badge_model.gd` on 34 lines): no method; `position` written (`src/ui/danger_edge.gd` on 2 lines, `tests/test_badge_model.gd` on 4 lines): no method; `shown` read (`tests/test_badge_model.gd` on 5 lines): no method; `shown` written (`src/ui/danger_edge.gd` on 1 line, `tests/test_badge_model.gd` on 3 lines): no method; `warned` written (`src/ui/danger_edge.gd` on 1 line, `tests/test_badge_model.gd` on 1 line): no method
- `EventDef`: `draws_body_shadow` read (`tests/probes/m226_arrival_timing.gd` on 1 line): `casts_a_shadow()` (3 calls); `id` read (`tests/probes/m226_arrival_timing.gd` on 5 lines): no method; `look` read (`tests/probes/m226_arrival_timing.gd` on 2 lines, `tests/test_badge_model.gd` on 1 line): `picture()` (38 calls); `telegraph_time` read (`tests/test_visible_view.gd` on 2 lines): `telegraphs_for()` (6 calls)
- `EventDef.SolidPart`: `shape` read (`tests/probes/m226_arrival_timing.gd` on 1 line): `ground_shape()` (3 calls)
- `EventInstance`: `_heading` read (`tests/probes/m226_arrival_timing.gd` on 1 line): `facing_now()` (51 calls); `age` read (`tests/probes/m226_arrival_timing.gd` on 1 line): on its view, `EventInstance.Figure.age()` (13 calls), a view no public method hands out; `came_under_a_warning` written (`tests/probes/m226_arrival_timing.gd` on 1 line, `tests/test_visible_view.gd` on 2 lines): no method; `def` read (`tests/probes/m226_arrival_timing.gd` on 1 line): `row()` (3 calls); `is_pelican` read (`tests/probes/m226_arrival_timing.gd` on 1 line): `is_drawn_as_a_pelican()` (1 call); `is_pelican` written (`tests/probes/m226_arrival_timing.gd` on 1 line): no method; `look` read (`tests/probes/m226_arrival_timing.gd` on 7 lines): no method
- `PendingWarning`: `is_pelican` written (`tests/probes/m226_arrival_timing.gd` on 1 line): no method
- `TouchControls`: `rotated` written (`tests/test_visible_view.gd` on 1 line): no method
- `VisibleView`: `controls` written (`tests/test_visible_view.gd` on 1 line): no method; `view` read (`tests/test_visible_view.gd` on 10 lines): `camera_view()` (3 calls)
- Receiver's class not told: `tests/test_visible_view.gd:90` `source.live`
- Receiver's class not told: `tests/test_visible_view.gd:96` `source.live`

## main merged: the danger edge's own suite

`main` gained `tests/test_danger_edge.gd` (the record 2026-10-18-minty-quail-rosy-bunny), the badge's
control checked alone. Its stand-in event source extended a bare `Node` and kept a view of its own,
and it no longer parses against `setup(events: EventManager, …)`. The merge was clean in text, and
this was its one semantic conflict.

- **Its `_Source` is an `EventManager` fake like the other three.** It overrides `instances()` alone,
  keeping the live events it is brought. Its view is the manager's own, which the rig looks through
  about her at the origin (`visible_view().look_from(Vector2.ZERO)`). With nothing covering it, that
  is the box the stand-in's `VisibleView.around(Vector2.ZERO, null)` was. The fake stays in the tree,
  since the convoy it is brought is its child. With no player handed in, the manager's own tick never
  looks the view through again, and it steps nothing, because its own list of instances is empty.
- **The convoy's drawn box is read off the row** (`EventFootprints.drawn_box_of(row, true)`, the call
  `EventInstance.drawn_box()` makes for a body running north to south), not typed in a constant
  beside a comment that named the function. The suite's own sight test and the edge are then
  checked against the box the game would draw, so a change to the convoy's picture or footprint
  cannot leave the margin check passing on a stale box. The box is the same today,
  `Rect2(-30, -38, 60, 38)`.
- **The suite still fails under a mutation**, reverted and never committed. Making the edge's sight
  test drop its margin (`_sees()` asking `VisibleView.sees()` with no margin) fails "and no badge was
  raised on any of them (24 frames up)". The convoy comes down from above, so its feet enter the
  view before any of its box; a mutation of `_shows()`'s drawn-box half is not one this suite can see.

## Verified

- `tools/check.sh` boots clean, before and after the merge of `main`.
- `test_badge_model`, `test_visible_view`, `test_drawn_view`, `test_interior_masked_man` and
  `test_interior_masked_man_badge` pass; after the merge, `test_danger_edge` with the first four.
- The arrival-timing probe (`tools/test.sh probes/m226_arrival_timing.gd`) passes. It prints the same
  27 rows at the head as with `origin/main`'s badge and probe run the same day. Its three
  vertical fire-engine rows differ from the evidence kept in October
  (`docs/evidence/m226-arrival-measurements-2026-10-07/after.txt`) on both, so that difference
  predates this change.
- The field-read check against `origin/main` passes with no new read, one file fewer carrying the
  opt-out line. The test-only member check, the layer check, the override check and the doc lint
  pass.

**Remeasure:** nothing; nothing changed in play.
