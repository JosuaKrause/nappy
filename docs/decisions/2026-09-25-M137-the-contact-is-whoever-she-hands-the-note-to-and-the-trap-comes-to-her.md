## M137 — The contact is whoever she hands the note to, and the trap comes to her · built 2026-09-25

*([PLAYTEST-71](../playtests/PLAYTEST-71.md): "not the first yeller she reaches but the first yeller
she interacts with" · "maybe spawn the robber in pursuing mode offscreen when she interacts with
the yeller so it runs towards her from offscreen" · "we need a version of the robber that is not
frozen when spawned".)*

**The contact.** The code already re-pointed the step onto whichever look-alike she was near;
`docs/NARRATIVE.md` now says she hands the note to him rather than reaches him first, and the
director's function is `_follow_her_between_look_alikes`, since the old name described the
overturned rule. `tests/test_resistance.gd` walks near one look-alike, away, and hands the note to
a second: the step completes on the second, he leaves, the first keeps shouting.

**The trap.** A perform step whose contact rides on a row (the man shouting, the van, the burnt
shell, a roadblock) gets no robber at dawn. At the handover, `ResistanceDirector.
_set_the_trap_on_her()`, gated on `TRAP_FIRST_DAY`, spawns `robber_giving_chase`: the alley
robber's numbers copied from `_alley_robbery()` (body, a field of 16 over 30–200px, 130px/s, a
30px catch, `hard_fail`, the walk-off), with no trigger distance, so he is never waiting and his
clocks start the frame he spawns. It is `SCRIPTED` with `scripted_day` 0, the marker the scheduler
already reads, so no day rolls it; `EventDef.validate()` refuses any map-placed pursuer with no
trigger unless it is that. His picture is the alley robber's sprites under a look of its own,
`ROBBER_GIVING_CHASE`, as `door_guard` reuses the roadblock guard; his catch reads "They were
waiting for you.", the alley robber's line without the alley. He spawns on the guard's ground
rules, off screen by the sight check, preferring a bearing with a straight walkable line to her.

**His warning is short and his chase is long** *([PLAYTEST-140](../playtests/PLAYTEST-140.md): "12.9s
is a *long* warning to the point where nothing really happens anymore", which overturned a 12.9s
warning chosen so that walking away could not escape him)*. `telegraph_time` is
`PURSUIT_MIN_NOTICE` plus half a second, 2.0s; `duration` is twice `PURSUIT_TIME`, 6.0s.
**`Tuning.TRAP_ARRIVAL_DISTANCE` is 315px**, the furthest start a walker still loses from: walking
straight away the gap closes at 130 − 92 = 38px/s, so 30 + 38 × (2.0 + 6.0 − 0.5) keeps half a
second of margin. `tests/test_resistance.gd` holds the relationships rather than the number: the
screen-edge badge is up before he is on screen, walking into him leaves the contract's reaction
time between badge and catch, and running ends the chase. On seed 4242, day 6, a real run was
caught 2.1s after the handover ("They were waiting for you."); the burst is in
`docs/evidence/m137-trap-comes-to-her-2026-09-25/`.

**Choices made where the spec was silent, open to overturn**: the neighbor's step, never guarded,
gets no trap; the district door, the mast, the swing and the last night keep their waiting guard;
a chalk mark's robber still waits by the mark, since which side she comes from is a route decision
a chasing robber would remove (M213, the chalk mark's robber stands at the far end of its alley,
moves him within that). The clear-run preference for his bearing is checked on seed 4242 only.
The same real run on the same seed ended once caught and once crying, a race between the meter and
the catch that is not this row's contract.
