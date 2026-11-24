# minty-quail — The basement walk rig steps the manager's repeats through a public step · 2026-11-24

minty-quail's pass over the tests that reach a private member. `tests/basement_walk_rig.gd` read the
event manager's private `_streaming` (`retire_finished()` and `bring_back_what_repeats()`) on every
frame of a walk.

**Built.**
- `EventManager.step_the_repeats(delta)` is the tick's retire-and-repeat step, and
  `_tick_the_events()` calls exactly it right after the broadcast's clock moves. The rig calls it in
  the tick's place.
- `tools/test_only_members.txt` keeps it with its reason; `tests-public-seams.md` lists the rig
  among the suites that drive a public step by hand.

**Measured.** The probe `tests/probes/basement_meter.gd` printed the same BASEMENT lines before and
after (18 lines, identical). Its run took 315 s before and 281 s after, on a machine shared with
other runs. Real ticks were not tried: the rig has no frames to wait on (a walk is a loop of
sixty steps a second of simulated time, and the probe makes 1100 walks of about 96,000 s in all),
and a real tick would also run the rest of the manager, which no walk asks about.
