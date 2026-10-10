# calm-pelican — A catch on the frame a door releases her counts as influenced · 2026-10-10

From the re-review of PR #589 (Influenced counts a real catch or hold): the encounter watch ran
before the detentions and the hard fails in `EventManager._tick_the_events`, so when a hut
inspection set her down within reach of a cyclist past its warning, the day ended before the watch
saw the catch and GoatCounter's `influenced` was never sent, against #577's "let's count chases and
catches as influenced always".

**Built in PR #644.** `_check_hard_fails()` names the instance that struck her to the watch,
through `EncounterWatch.caught_by()`, which makes one look at it with the game's own `is_lethal_at`
under the same guards as the ordinary watch (not in the finale, not stood aside). That covers every
path that strikes her, not only a door's release (the first of the item's two fixes, open to
overturn). `docs/TELEMETRY.md` and the watch's doc say a pursuer chases from the moment it comes for
her (`EventBus.pursuit_began`), which is before she is within its reach. The new test drives the
hard-fail check directly rather than a real hut release, and fails without the call.
