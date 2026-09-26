## M131 — Pigeons exist before they are seen · built 2026-09-13

*(2026-09-13, [PLAYTEST-69](../playtests/PLAYTEST-69.md): "pigeons pop in on screen -- they should
exist before they are visible.")* One agent commit on `feature/m131-pigeons-on-the-ground`,
reviewed on the PR; the evidence is `evidence/m131-flock-on-the-ground-2026-09-13/`.

**A place, not a moment.** `pigeon_flock` is a `MAP` placement on sidewalk, square or park with a
wait trigger of 150px — inside its 168px field so the notice starts on ground she is already
charged for, and more than twice the 62px wheel so the birds are up before she is among them —
and the entry's recommendation was built as written. The birds peck on the tile from the moment
the day streams them in at `EVENT_STREAM_RADIUS`, over two screens out, and the 1.7s telegraph and
the burst begin when she comes inside the trigger: the telegraph contract paid in geometry, the
way the robber's and the day-4 dog's are. The alternative, keeping the row ahead-of-player and
siting it past the view's edge with `offscreen_lead()`, was rejected because a flock that walks
into view already bursting is never seen on the ground, which is most of what the row is, and a
crossing sited where she is not going is one she has no reason to reach.

**What the wait needed.** A waiting `pursues_within` row emits at full strength — the rule for a
man in an alley, who has started and only the lunge has not — so a flock would have charged 42/s
all morning to anyone within 168px. `EventDef.quiet_until_noticed` damps a row's wait and its
notice to `TELEGRAPH_INTENSITY_FRACTION`; `validate()` refuses it without a trigger, and refuses
a flock that obstructs, since eleven bodies wheeling have no one silhouette and being walked
into is the event. The intensity damping now lives in one place, `_notice_damping()`, which the
meter multiplies by and the caret's projection divides by. Two bugs found on the way: the flock
was held in the air for the whole wait because `_fly_the_flock()` asked only about the telegraph,
and the intensity ramp read the row's age rather than its chase age, so a long-waited burst would
have opened at the multiplier its end is meant to have. Two existing flock tests had gone vacuous
under the wait and now stand her in it.

**The test.** `tests/test_events.gd` holds that the row is map-placed on every day, that every
planned flock has a tile, that the stream radius less a frame of running exceeds the view's far
corner so a first drawn frame is never inside the view rect, and that an instance at stream
distance is waiting on the ground at the damped rate and rises only inside the trigger.

**Open to overturn, and one put to the player.** Under the cost rule a 42-over-168 flock is a
wall, so a placed one lands off the corridor rather than in front of her: a flock is now met by
straying, not on the way. That follows from the entry, which asked for existence before
visibility and said nothing about the route, and it is a different encounter from the one the
row was written for; a friction-role exception is the alternative if the player wants it on the
route. The trigger distance, the new field and the fourth solidity exemption are the agent's
choices. M100's rig defect closes for this row and stays open for the queue-fed ones, and gains
the gap the agent found: `first_event_position()` stands a rig inside a waiting row's trigger, so
no rig can photograph the silence before a flock or an alley robbery. `evidence/m121-halo-follows-
owner-2026-09-13/README.md` still says `--spawn event:pigeon_flock` cannot work; it is a dated
capture record and was left as written.
