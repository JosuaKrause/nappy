## M100 — The boom never inspects her, and a raised one lets her pass · built 2026-09-24

*(2026-09-24, the player, each answer to a question put in the session: "Boom shouldn't inspect
her. It should block her. If a car opens it for her and she walks through she would probably get
hit by the car, no?" · "I didn't say it should stay solid when it's open" · on whether a raised
boom lets her through, "A yes" · "The bot shouldn't route through the boom either way" · "The
guards should start pursuing her in that case" · "Or guards that pursue her should spawn at the
huts" · "The day ends, not going through the checkpoint is a clear unlawful thing here. She gets
detained/imprisoned or whatever in that case. This is independent of the resistance. She
shouldn't do it. One guard is enough".)*

**What was wrong.** The boom's own body took her in for an inspection with nobody on screen doing
it, since the guards stand at the huts. A guard stepping to the arm was the other answer offered
and was not taken.

**The gate.** `checkpoint_gate` no longer detains. `EventDef.lifts_for_traffic` makes its body
solid only while the arm is down; the cars raise and lower it exactly as before. Two things make
that hold in play: a hut's trigger reaches 80px, past the kerb, so a hut now ignores her on the
carriageway its own boom spans (`EventManager._on_a_booms_carriageway`); and `Crowd._stop_for_gates`
keeps a raised arm up while any part of her or the pram is under it, as it already did for a car
within a length, so the boom never closes on her.

**The walk under it.** `EventManager._watch_the_door_lines()` checks each physics frame whether
she crossed a door body's line within its reach without being moved outright;
`Stroller.outright_moves` counts `teleport_to` and `reset_at`, so a hut's release is never read as
a walk. The run log notes it under `checkpoint`. It lives in `EventManager` rather than the
telemetry observer because it is what sends the guard.

**The guard.** A SCRIPTED row, `door_guard`, steps out of the wall of the hut nearer to her on the
side she crossed to; the drawn hut guards stay, and one chases at a time. He copies the roadblock
guard: 130px/s, a 1.8 s notice, a chase of `PURSUIT_TIME`, caught at `MASKED_MAN_REACH`. He is
`hard_fail` in his own right, on every door day at every heat level, and the summary says "You
went under the barrier. They took you in." `EventDef.sets_off_beside_her` exists because he
spawns inside his own 106px stand-off: without it the ordinary pursuer rule would lunge on his
first frame with no notice. In the door rig nothing is lethal during the notice, walking away is
caught at 3.8 s, and running escapes until he gives up. In capture attempts a car struck her or
the baby cried within about 20 s of the dash, several times: the dash is expensive, as meant.

**The rig.** A real rig leg along a carriageway through a door walks under no boom (a control walk
in the same rig counts one). `_gate_ground()` blocks every tile from which her body would touch
the boom (its `solid_reach()` plus her body plus `_ARRIVE_RADIUS`), and the rig's door code no
longer treats the gate as a door. `still_watch.gd`'s list of detainers drops the gate (wording
only; the watch reads `is_detained()`), and `door_guard` is in `tools/cost_table.gd`'s pursuer list.

**Open to overturn** (the agent's choices where the design was silent): huts ignoring her on the
boom's carriageway; the arm staying up while any of her rig is under it; the check in gameplay
code; every door body's line counting, an alley post's included, each sending its own guard; the
id `door_guard`, clear of the "checkpoint" prefix other code matches on; no new drawing (he shares
the guard pictures, his badge `guard_lunging_side`); his excitement field copied from
`masked_pursuer`; `sets_off_beside_her`'s trap, that walking into him during his notice gets her
caught when it ends. **Queued:** a catch during another hut's hold (asked), the round boom body
sliding her to the hut, a car pulling away from a stop line honking late, `--spawn
event:checkpoint_gate`'s placement, and a walking bearing possibly read as running.
