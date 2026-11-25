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
other runs. Real ticks, measured by the PR's review: 400 walks took 52.4 s and 52.6 s on `step_the_repeats()` and 97.5 s and 98.6 s with the rig calling
`_tick_the_events(STEP)` (about 9 s of each is boot): 1.87 times gross and about 2.05 times net, about 45 s
more per 400 walks, roughly 120 s across the probe's 1,100. The BASEMENT lines matched between the two,
so real ticks did not change what a walk meets. The added time is well over 30 s and the ratio reaches
2 times, so the public step is the choice.
