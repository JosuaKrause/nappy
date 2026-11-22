priority: later

# coral-heron — The tick-sweep probe fails its day-9 chain check · filed 2026-11-22

**Found** by the agent of the minty-quail work earlier on the day row 4b finished, in its day-9 frame-step copy.

**What holds.** `tests/probes/m159_tick_sweep_events_cost.gd` runs its checks on main and three of them fail: for seed 4242, day 9, the events walk, repetitions 0, 1 and 2, the check "the split step changes every event, agent and meter exactly as the real one". The probe's contract (its header) is that its `split` mode, which makes the events' step's own calls in its own order (`_tick_the_events()`), chains the same SHA-256 over every event's and agent's state as `whole`, which times the real `EventManager._physics_process()`; a mismatch means the copy of the step no longer is the step the game runs on that day. Every other check passes.

**The command that shows it:**

    tools/test.sh probes/m159_tick_sweep_events_cost.gd; echo $?    # 1, three FAIL lines, about six minutes

**What the fix must hold.** The probe's copy of the events' step is brought to what `EventManager._physics_process()` does on day 9 (the first call that differs is what the entry finds), or the probe asks the manager for its steps instead of holding a copy, so it cannot drift again; every check passes.
