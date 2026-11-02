# minty-quail — The crossing suite drives public seams: the checkpoint's guard and the director's door (tests through public seams) · 2026-11-02


minty-quail's `tests-public-seams.md`: `tests/test_resistance_crossing.gd`, day 9's crossing of the
district door. The item stays open for the other resistance suites.

**Built.**
- `CheckpointController.guard_is_after_her()`, the one test the controller's three copies of it now
  call, and `ResistanceDirector.door_position()`, `door_axis()` and `trap()`, plain queries of what
  the director holds. Only the controller's own three sites call one of them in `src/`; the rest are
  queries the tests read.
- Each attempt builds its own city in a run of its own and crosses the door through the events'
  `door_crossed` signal. An outright move is `Stroller.teleport_to()`, the move the game uses, in
  place of writing `_last_seen_at`; the side she entered from comes from a real hold
  (`check_detentions()`, the hold's clock run out, `release_finished_holds()`) in place of writing
  `_door_entry_side`. Private reads go from 57 lines to 0 and direct frame calls from 1 to 0; the
  suite passes with its tests run in reverse order.
- Checks go from 137 to 139: the two "standing at the gatehouse or under the boom completes nothing"
  checks moved into a test of their own that lets real frames pass, and a new test shows a crossing
  seen through real frames (it fails when the manager stops watching the door lines).

**Open to overturn** (the builder's choice where the brief was silent): the two-second crossing
warnings are run by calling `watch_the_door_lines(STEP)` with a delta, the call the manager makes
each frame, rather than two seconds of real frames.
