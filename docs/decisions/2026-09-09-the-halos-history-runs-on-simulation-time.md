## The halo's history runs on simulation time — 2026-09-09

*("let's use simulation time not wall time")*, answering the tooling audit's finding below.
`CrowdAgent` and `EventInstance` each keep a five-second sliding sum of the points they landed on
the meter, and both stamped their entries with `Time.get_ticks_msec()`: wall time, so a pause
longer than `ExcitementHalo.WINDOW` (5.0 s) emptied every halo the instant the game resumed, and a
rig measured the window on however long its own assertions took. Each source now keeps its own
`_clock`, advanced by `delta` in its `_process()` and used for both the stamp and the prune;
gameplay nodes are `PROCESS_MODE_PAUSABLE`, so that clock stops exactly when the simulation does.
Two choices the brief left open and the agent made: an `EventInstance`'s clock advances after the
`is_finished` early return, so a spent instance's history freezes rather than draining; and
`tests/test_halo.gd` advances `_clock` directly to stand in for the window elapsing, adding the
invariant the change exists for — a second `landed()` read with no `_process` tick returns the
same sum. A shared global clock on an autoload was the alternative and was not taken: autoloads
run through a pause, so it would have needed its own paused check, and a per-source clock has no
second reader to disagree with. Verified with `check.sh` and the halo, meters, events and crowd
suites.
