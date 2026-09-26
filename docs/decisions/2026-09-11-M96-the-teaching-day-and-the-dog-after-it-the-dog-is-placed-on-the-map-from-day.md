## M96 — The teaching day, and the dog after it · the dog is placed on the map from day 4, built 2026-09-11

One agent commit on `feature/dog-on-the-map`, reviewed here, finishing the placement half of
*"the tutorial dog may appear later but not as tutorial"*. **The shape**: `EventDef` gains a
day-keyed spawn mode — `spawn_mode_switches_after_day` and `spawn_mode_after_first_day`, read
through `spawn_mode_on(day)` — as a derived answer rather than a mutation of the shared
resource, since a mutated singleton would carry across a replay in the same process (the same
reasoning `at_heat()` rests on). `charging_dog` switches to `MAP` after `Tuning.RUN_TAUGHT_DAY`,
the scheduler's placement and role code ask `spawn_mode_on(day)` at the three call sites that
already had the day, and the director builds its owed list the same way, so the scheduler placing
the dog and the director queueing it cannot both happen. **Removed**: the director's off-heading
half-measure — the 50–110° bearing, its two constants and the helper — because the switch keeps a
day-4 dog out of the owed list before that code is reached. `_teach_the_run()` and day 3's
siting are untouched; the tests hold day 3's heading, a `build_day()` sweep in which every
day-4-plus dog plan is placed, and an owed list of zero past the teaching day, in place of the
old off-heading angle checks. `validate()` checks the switched-to mode's obstruction the way it
checks the base one.

**The fork, named by the agent and left to the player** (it is the open item in `TODO.md`,
M96): the placed dog has no `pursues_within`, because day 3's lesson needs it to charge at once
and `tests/test_danger.gd` pins that, so from day 4 it begins its charge the moment it streams
in — `Tuning.EVENT_STREAM_RADIUS` (900px) away — rather than when she enters its field. Placed
on the map, yes; met by routing into it, not yet. **The recommendation** is a day-keyed trigger on
the same switch, waiting inside its own outer radius from day 4. **Not done**: a `TOWARD_PLAYER`
check for the switched-to mode, since no row uses that pairing.
