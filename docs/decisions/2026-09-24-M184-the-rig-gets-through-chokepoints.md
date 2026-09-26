## M184 — The rig gets through chokepoints · built 2026-09-24

*(The route rig, `--route mark,task,calm,home`, is how M181's late days get timed; PLAYTEST-122.)*

**Measured** with `tests/probes/m184_route_timing.gd`, days 6 to 13 on seeds 4242, 90210 and
1234567 under `--invincible`, both sweeps on one tree: legs ending "stuck fast" 23 before, 0 after;
runs with a stuck leg 13 of 24 before, 0 after; runs walking the whole route 11 of 24 before, 23
after. The one that does not finish, day 9 on 90210, is not stuck: the mark at 27.7 s, the task at
91.5 s (3537px off, through four doors), the calm area at 99.6 s, and the day's 144 s run out on the
walk home — an open question in M181's "the late days are timed". No run was taken in by a boom;
huts and alley posts held her 26 times.

**Day 6's narrow gap on 1234567 was the rig's, not a placement bug.** The `delivery_van` at the kerb
(22px body) leaves 26px of sidewalk to the frontage and she needs 28px: the "wall by fit"
`docs/EVENTS.md` describes, allowed anywhere a route does not run along, and no route runs along
that tile. A player hugging the frontage does not get through, as designed, and the way past is the
road. Day 8's home leg on 1234567 and day 12's on 4242 no longer stall with either rig.

**What the rig does now** (`src/dev/route_rig.gd`): it keeps clear of a body by its outline; a
re-plan goes round the body that caught her and the unstick tries the direction away from it first;
it follows a moved mark; a door's hold is not a stall. It plans against the whole day's plan
(`EventManager.plans()`, read only) rather than what has streamed in near her, which ended the
re-plan loops. A door body stands on a tile boundary, so both sidewalk lanes are exactly 16px off
its axis and the crossing test's `< 16` counted neither as the way through; it is `<=`, with a test.
It copies the game's release latch; after a door sets her down on a building tile it plans from the
nearest open tile outside every door's reach (the game's release can do that — an open M100
defect); an any-instance task keeps the instance it picked; under `--invincible` a run ends once the
rig's own clock passes the day's length, and says so. The probe runs a day's three seeds side by
side, about 13.5 minutes a sweep instead of about 30.

**The rig never routes through a boom** *(2026-09-24, the player: "The bot shouldn't route through
the boom either way")*: wherever a `checkpoint_gate` rather than a hut would take her, the ground is
blocked in every plan, the last-resort one included, found by the plan's `GateState` rather than by
detention so it outlives the boom's change (M100, the boom never inspects her).
`_test_a_plan_never_goes_through_the_boom` fails with the rule off. When the gate stops detaining:
`_door_tiles()` and `_latch_the_doors_round_her()` drop it by their `redetains` filter, the
`gate_state != null` special case in `_door_tiles()` becomes dead code, `_gate_ground()`'s "nearer
than any hut" test can shrink to the boom's own lanes, and `_is_planned_body()` starts giving the
gate body clearance.

**Open to overturn** (the agent's choices where the design was silent): the rig reads
`EventManager.plans()`, documented as a readout's; `chatting_mother` is no longer avoided as a door,
since she walks; the boom's blocked ground is its trigger plus 10px wherever it is the nearest door
body; ending at the day's length applies only under `--invincible`.
