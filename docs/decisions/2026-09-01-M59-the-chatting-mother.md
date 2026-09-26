## M59 — The chatting mother · `feature/the-chatting-mother`

Asked for on 2026-09-01 (playtest 18, finding 4: *"another mother with child. when getting too
close one gets caught up in a conversation that takes 5s and consumes 25% excitement. if the baby
is already sleeping it's a pure time loss if it's not it bears overstimulation risk"*). Built
same-day, seven commits, suite green. The readings that shaped it — "consumes 25%" adds 25 points
awake, "pure" means asleep the chat emits nothing at all — are in the playtest entry and were
implemented exactly: the chat's contribution bypasses `SLEEPING_SENSITIVITY` entirely rather than
scaling through it, because a scaled 13.75 could cross the wake threshold and would not be pure.

The numbers as built: intensity 4.5 over 34/70px (a person-scale ambient field, just over the
passer-by's 4.2), pacing at 26px/s over an 8-tile sidewalk beat, `detain_seconds` 5, `detain_radius`
26 (under the 32px lane spacing, so the far lane of a pavement can never trigger it),
`max_per_day` 2, `first_day` **1** — the balance suite measured green there, so the fallback to
day 2 was never needed. One conversation per instance; afterwards she departs like a `dog_walker`.
The lock zeroes the stroller's input for the duration, so the existing idle rules price the time.
`EventDef` carries the general machinery (`detain_seconds`/`detain_radius`, validated:
detain < inner ≤ outer, never on a `hard_fail` or a pursuer). A `chat` telemetry entry records
position, duration, baby state and what the meter did; the `blocked` watcher is gated on the
detained state so a conversation cannot log as a stall.

**Three rig-building traps found while writing its tests**, each the kind that passes vacuously:
a bare `Stroller.new()` has no `CollisionShape2D`, so `move_and_slide()` never moves it and a
position assertion proves nothing (assert on `velocity`); its baby lookup is by child name, so a
test's `Baby.new()` needs `name = "Baby"` or the awake query silently answers its no-baby default;
and hand-built nodes want explicit `.free()` or the suite reports leaked instances under a green
check count.
