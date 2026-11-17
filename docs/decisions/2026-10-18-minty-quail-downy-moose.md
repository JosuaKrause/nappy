# minty-quail — Members only tests read become internal, go, or keep a stated reason · 2026-11-16

**The ask.** `tests-own-class-members.md` and the open items of `tests-public-seams.md`: a member only a test reads is made
internal, deleted with the test rewritten to what the game does, or kept under a stated reason in
`tools/test_only_members.txt`. This is the pull request #1481, for the members the brief named; `PendingWarning.left` and
`EventsAhead.walk_siting` are live work and are not touched.

## What was built

- **Deleted** (their `[no reader]` lines removed): `EventAbduction.stop()` (`test_event_redraw.gd` ended the take by calling it;
  it advances the event's age past `taken_over`, which is how the take ends in play), `EventManager.on_screen()` (two checks in
  `test_resistance_replacement.gd` restated the view the test had just set, and one read the test's own view rect) and
  `RunStateRegistry.parts()` (`test_run_state.gd` finds a part's registration by whether `run_data()` carries its data, and
  walks the parts a `RunState` declares by reading its script variables).
- **Made internal, behind methods**: `EventFlock.Bird`'s `at`, `lift`, `heading` and `phase` become `_at`, `_lift`, `_heading`
  and `_phase` behind `at()`, `lift()`, `heading()` and `phase()`, written through `place()`, `face()`, `rise_to()` and
  `flap_to()`, which the flock's own step and two tests use; `SpreadLook.Slice.index` becomes `_index`
  (`look_fingerprint.gd` names a slice by its place in `slices()`).
- **`TouchControls`'s `FOCUS_KNOB_OFFSET` and `FOCUS_KNOB_RADIUS`** become public constants (a test reads a constant to hold a
  relationship, as writing-tests wants), and the 1.3 the running knob grows by is `FOCUS_KNOB_RUNNING_SCALE`, which the draw and
  the test share.
- **Two members moved to `[kept]` instead of deleted**, the fork the builder left open to overturn and the reviewer accepted:
  `RouteLines.routes()` is the only handle on the polylines `_draw()` passes to `draw_polyline()`, the same reason
  `EventRouteLines.routes()` is kept, and deleting it deletes `test_route_lines.gd`'s picture sweep, the guard for a route that
  once crossed mid-block; `SpreadLook.slices()` is read by four suites and two probes to find an event's slices, and a slice holds
  its look weakly so nothing else says whose it is. Its line names the mock drawer handed in (inbox #1018 in brisk-ferret) as
  its way out.
- The queue text the pull request made untrue is rewritten on the branch: `tests-public-seams.md`, `field-reads.md`,
  `event-interface.md` and the entry's README.

## Measured

The look fingerprint (`tests/probes/look_fingerprint.gd`, 63,070 `LK` lines, the flock and the spread look drawn) is identical
before and after, `a12e4cc9...18415539`, which the reviewer reproduced. The changed suites pass, and each rewritten check fails
without its line (`test_event_redraw.gd`'s "the take is over" without the age advance; `test_run_state.gd`'s "a part declared and
never registered is named" if `_is_written_by` answers true). The field-to-method search for a `Bird`'s fields finds no read from
outside its file. The reviewer ran `resistance_traps` and `event_behaviours` as well: 43,875 checks, 0 failures.

## Rejected, with the reason

- **Deleting `RouteLines.routes()` and `SpreadLook.slices()`**: the information cannot be had another way without a mock drawer
  for the route layer or a slice that answers whose it is, each a change of its own.
- **Dropping the two `test_resistance_replacement.gd` guards with `on_screen()`**: the first review found they asserted the
  scenario's geometric precondition, not a handed-in value; both were restored against the test's own `Rect2` and the second
  was mutation-checked.

## Review

The first review (changes requested) found the two dropped guards and a stale comment (`bird.heading` in
`m108_event_people_sheet.gd`); the delta review approved. A preference left open: `_is_written_by()` answers false for a part whose
`to_data()` is empty, a trap if a part ever starts empty. `Bird.speed`, `turn`, `ceiling`, `climb` and `beat` stay public and are
read across objects, outside what the brief named.
