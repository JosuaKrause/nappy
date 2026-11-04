# minty-quail — The probes hand what they measure a run of their own (run state handed in: G6) · 2026-11-04

minty-quail's `run-state-handed-in.md`: the probes under `tests/probes/` that named the stand-in or
reached it through `RunCity.of_the_run()`. Tests only.

**Built.** A probe over a city builds it through `RunCity.with_own_run()` and reads its run; one
with no city makes a run and frees it; the two that boot `main` boot it through `tests/seat.gd` on
a scratch-path save. A probe that never started a run of its own takes seed 2, the seed the
runner's reset gave the stand-in, and one that did keeps its seed; the saves and restores of the
stand-in are gone. Each probe's output was compared before and after: the same, apart from timings,
except the trap-arrival sweep, whose two hundred cities no longer carry one shared run's steps and
alley tiles from city to city, which is what its header says it measures.

**Not done:** probes broken on main before this change, converted by inspection and left broken:
the other-pursuers probe calls a suite's helper that no longer exists; the far-end probe uses an
undeclared variable; the two ground-frame probes have no `run()`; the lazy-scenery routes probe
assigns a node of the wrong type; the lazy-scenery measure probe drops the run it hands a city when
it swaps the city's script.
