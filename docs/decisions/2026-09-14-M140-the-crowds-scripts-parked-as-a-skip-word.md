## M140 — The crowd's scripts parked, as a skip word · built 2026-09-14

*(2026-09-14, [PLAYTEST-73](../playtests/PLAYTEST-73.md): "Sure let's try stopping the simulation
for the crowd. We can keep the atlas as it is still an improvement. Is there any obvious
optimization we can do with the crowd code?")* One agent commit on
`feature/m140-crowd-motion-skip`, reviewed on the PR; the still is
`evidence/m140-crowd-motion-skip-2026-09-14/skip-motion.png`.

**Why a fourth word.** With the crowd atlas released the phone reads the same with the crowd
drawn and with `skip=crowd` (M139, the phone reading, below), so the crowd's drawing is ruled
out of the phone's frame and what is left of the crowd is its simulation: `skip=crowd` returns
from `CrowdAgent._draw` and nothing else, and the 234 agents still steer, look ahead, turn,
recycle and queue on every tick. `motion` says what that costs. The reading is the player's,
on the phone, on the next release, and is the `REVIEW.md` item: `?debug=1&seed=123&skip=motion`,
then `&skip=crowd,motion`, read for `fps` and the `process` and `physics` means against
playtest 73's table.

**What it is.** `motion` joins `DevFlags._SKIP_KNOWN_WORDS` and gets `skip_motion()` beside
the three draw getters, under the same gate: honoured only while `readout_requested()` holds,
so a release page nobody asked `?debug=1` of never parks anything. `CrowdAgent` reads it once
at spawn into `_skip_motion` the way `_skip_draw` is read, and `_process` returns before its
first line while it is set, so the agent's clocks, steering, lookahead, turning, gait and
recycling all stand still and it is drawn wherever the day placed it. `Crowd` reads it once in
`setup()` and `_physics_process` returns before the signals advance, so nothing the crowd
ticks — the signals, the pockets, the traffic spacing, the index, the junctions, the gates,
the doors, the player's make-way and bump scan, the strike and the horn — runs that frame.
`start_day` still places the whole population, so the street stands full of standing people
and parked cars; the events and the baby's own excitement read of the crowd are unchanged,
since that scan is the baby's and not the crowd's. `Crowd.step()`, the rig's own frame, is
untouched: a rig asked to walk the crowd walks it. The readout's `skip` line names the word
through `skip_words()` as it names the others, with no change of its own. The skip-word
parser tests take the four-word list and the four-getter gate check picks the new getter up;
the crowd suite sets `_skip_motion` on a live agent, steps it two seconds by hand and asserts
its position is unchanged, and the same for an agent with the flag off. `docs/TELEMETRY.md`'s
skip-words paragraph lists the fourth word and says it turns off ticks where the other three
turn off a draw call each. The still, `tools/shot.sh` on seed 3265820891, day 1, three
seconds of walking under `--debug --skip motion`, shows the readout's `skip  motion` line and
the crowd standing where the day placed it.

**One choice made where the design was silent, open to overturn.** `Crowd._skip_motion`
defaults to `false` and is read in `setup()` rather than at construction, because a `Crowd`
outlives its construction and is set up separately, where an agent is read once at spawn; a
test that wants the crowd's tick parked sets the member directly, the same shape as
`_skip_draw`.

**What the crowd's scripts do each frame, read for the player's question.** Every
`CrowdAgent` is a `Node2D` with its own `_process`, so the engine calls 234 of them a frame:
each runs its clocks down, moves along its lane, holds itself inside its tile, considers a turn
at a corridor, advances its gait, looks ahead, diverts if blocked, checks whether it has left
the field or is sealed in a pocket, and asks for a redraw only when its picture changed. Two of
those are already gated — `_look_ahead()` rescans only when the agent enters a new tile, and
the redraw key means a walker in a lane costs no draw list — and the rest are a few dozen small
GDScript calls apiece, which on the web's interpreter is the cost that scales with the
population rather than with what is on screen. `Crowd._physics_process` then walks every agent
again at the physics tick, sixty a second regardless of the frame rate: the traffic is bucketed
by lane and each lane sorted, the index rebuilt, the junctions negotiated, the gates and doors
held, and every walker tested against the player for making way and bumping. The physics line
reads 6 to 11 ms on the phone against 1.8 on the desktop, and at a phone's 28 fps that tick runs
twice a frame. **The one obvious change, if the probe says the scripts are the cost, is a
slower tick for the agents nobody can see**: the field is 1600px square and the screen shows a
tenth of it on the desktop, a quarter on a phone in portrait, and `CrowdField`'s own licence is
that consistency off screen does not matter — so an agent outside the camera's rect could step
every fourth frame with four times the delta and nobody could tell. It is not filed: the probe
comes first, and if the scripts are not the cost there is nothing to save.
