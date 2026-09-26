## M152 — The about-face is planned, and the morning is unpacked early · built 2026-09-15

*(2026-09-15, [PLAYTEST-76](../playtests/PLAYTEST-76.md): "in some case instead of routing a turn
(or u turn) they just teleport"; and of the same build a burst later, [PLAYTEST-77](../playtests/PLAYTEST-77.md):
"cars are still jumping around".)* Two agent commits on `feature/m152-about-face`, reviewed on
the PR; the probe's output before and after, and the player's own run folder with its burst, are
`evidence/m152-about-face-2026-09-15/`.

**The morning unpack, and why it was seen at all.** A day is started from an *idle* frame —
`main._start_day()` runs out of `_ready()` after its await, or out of the summary's continue
button — and Godot draws at the end of the iteration it is in, after the idle phase and before
the next physics tick. Measured: the crowd is placed at process frame 1 with the physics counter
at 12, and the next physics frame the crowd sees is 20. So the placement is the frame the player
is shown and the first frame's separation pass is the correction she watches, on the street the
day built the crowd around. `Crowd.start_day()` now ends by running that resolve itself,
`_resolve_the_queues()`, extracted for the purpose. **It is the overlap resolve and nothing
else**, which is the distinction from spacing the crowd in `start_day`: no position is chosen, a
car that was not inside another one does not move, and no balance test moved. Rejected: calling
the whole of `space_out_the_traffic()`, which also negotiates the junctions and reads a gate list
`main.gd` only sets afterwards. The check in `tests/test_crowd.gd` steps one frame after
`start_day()` on a day from each act and asserts no car moved further than it could drive in one
— 57.4 px without the call, under 3.1 px with it; it excludes recycles by the `_cruise` reading
the probe already uses, since a recycle is the one teleport the design allows.

**Why cars reached the last resort, measured rather than reasoned.** `_commit_to_a_turn()`
answers with the check that refused an arc (`TurnRefusal`) instead of a bare false,
`_plan_a_turn()` records those four answers and which of its two ways out reversed the car, and
the probe prints the table. Over seven rig days on the old code: **315 reversals on the spot,
every one from the "stopped with no room" branch and none from the illegal-ground branch M111
names as the only way in, every one with `_room_to_stop_in()` at zero** — which is where the
brake aims, so the test fired on the ordinary case rather than on a state a placement had to
produce. Underneath: about 179 the street about-face refused as `too-tight`, because its entry
sits at `blockage − about_face_reach()` and a car braked to that point is a fraction of a pixel
past it, which sends an about-face to `tighten_to()`, which its radius can never satisfy; about
90 `sweep-blocked`; about 31 `landing-taken`, which clears by itself. A trace on the player's
seed (3126506586, day 1) found the burst's car: a stub of carriageway with a precinct's paving
6 px ahead and a solid body on its own lane three tiles back, 464 reversals in 120 s, the
cross-steer sliding the body between the two lane centres at `STEER_SPEED` between them. The
same trace caught `_look_ahead()` alternating between clear and blocked on frames where nothing
moved but the car's drift across its lane, because the scan started from the body's tile and the
row beside a lane is the other lane or the kerb. The picture's single flip in the burst is a
stopped car keeping its last facing (`EightDirection` holds the sector under `CAR_IDLE_SPEED`)
and latching the one frame it moved north — not a second defect.

**Four changes, each stating a decision over the right thing.** The lookahead is asked from the
car's lane centre, which is the rule `_detour` already forces on a walker. The brake leaves the
arc the four pixels a 28 px body has spare in a 32 px lane (`TURN_ROOM_MARGIN`), because a
manoeuvre that fits exactly does not fit — a brake arrives a frame late and a swept body is
sampled rather than solved. The street about-face's entry is clamped to where the car already
is, so the sweep check answers instead of `tighten_to()`. And the reversal is stated over the
refusals: a landing another car is standing on is waited out, bounded at the time a car needs to
clear its own minimum gap at turn speed (`TURN_WAIT_SECONDS`), and a reversal into a lane whose
own road runs out inside a half turn is refused outright, because it changes nothing about the
state that caused it — that car stands (`_nowhere_to_turn`) and leaves the way a pocketed body
leaves, recycled at the first frame the camera is off it. **Rejected: an unbounded wait**, which
took the reversals to 45 and parked the traffic at 34 of 34 cars stopped in ninety seconds on
seed 4242 against 8, the exact failure M111 measures; and a bound of a gap at cruise, which kept
the road moving and bought nothing.

**Measured.** Reversals on the spot 315 → 73 over seven rig days, 1 in view either way; sway
episodes 11 → 0; on the player's seed 132 → 9 and 10 → 0, none in view; stopped cars at 90 s
over seeds 4242/24757/99001, the same rig both sides, 8/21/5 → 7/15/8 of 34. **The residual is
73 reversals, 72 of them off camera**, almost all the street about-face refused as
`sweep-blocked` — a wall, a closure, a seal or a precinct under the arc, which waiting cannot
mend — plus a few where a *stopped* car outsat the wait on the landing; the one in view is one
of those, and it reverses into the lane whose spot level with it is the very landing it waited
for, so the resolve then moves one of the two. Recorded on the PR as the shape to try if it
shows in play: a landing held by a stopped car treated as a plug, stand rather than reverse.
**Left open, in `TODO.md` under M152**: a follower shunted about 65 px backwards by the
front-to-back resolve in view on seed 91117 day 1, in the before run at the same coordinates.

**Tests.** `tests/test_turns.gd`, driven through `Crowd.step()`: a car whose landing is occupied
waits, does not reverse, and takes the arc once the lane clears; and a car with less than a half
turn's road at either end stands rather than reversing. With the two rules removed they report
the defect in the player's own words — 15 reversals in six seconds with the body sliding across
the street. One warning the run surfaced and this branch does not own, filed under M100: the
balance suite's rig builds a `Camera2D` that Godot overrides to physics process mode.
