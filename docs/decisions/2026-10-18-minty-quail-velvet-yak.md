# minty-quail — A warning badge reads how fast its subject closes · 2026-11-16

**The ask.** The event interface's row 1 and section 7 point 6 (`event-interface.md`): the badge of a warning with nothing in
the world yet was made with the row's plain `speed`, which a pursuer does not set, so the run log read "closing 0px/s" for the
day-3 charging dog. This is the pull request #1478, one cut of the entry's row 1; its other item, the run log map's read of the
plan's `role`, waits for row 3a and is untouched.

## What was built

- A pending warning's badge is listed at the row's `approach_speed()` (`chase_speed()` for a row with a pursuit, `speed`
  otherwise), as a live event's badge is. `BadgeModel._announce_the_warnings()` reads `subject.approach_speed`.
- **Deleted**: `BadgeModel.Subject.speed` and its one write, `def.speed` in `DangerEdge.subject_for_def()`; the line
  `src/ui/danger_edge.gd speed` in `tools/field_reads.txt`.
- **Test**: `test_badge_model.gd` `_test_a_pending_warning_is_listed_closing_at_its_approach_speed`; replacing
  `subject.approach_speed` in `_announce_the_warnings()` with `0.0` fails it (the old line listed 0); the reviewer ran that mutation, replacing the read with `0.0`, and it failed.

## Measured

The builder's account, checked by the reviewer: the change moves the number only for pursuers; every other warning (vehicles, a cyclist, a van with no pursuit) lists what it
listed before. The number is the one a live thing that arrived under its warning starts closing at, so the log line a warning
writes and the one the same thing writes once it is in the world now agree. Nothing re-records (the builder's claim, confirmed by the reviewer's search): the only consumer of the listed
approach is the run log's "edge badge ... closing Npx/s" note, no fixture under `tests/fixtures` or `tools` holds that line,
and `docs/TELEMETRY.md` quotes a number only for the escape's live masked pursuer.

## Rejected, with the reason

Nothing was set aside. The reviewer's preference, not taken: a test that a pending subject built from the charging dog's row
carries its chase speed, since the line in `DangerEdge.subject_for_def()` that makes the number nonzero in play is not pinned
by a test; it existed before this pull request.

## What stays open

Row 1's other item (the run log map's read of `role`, with row 3a), which stays in `event-interface.md`.
