# minty-quail — The save suite plays runs of its own, and one Seat helper hands a booted main its run (run state handed in: G1) · 2026-11-04

minty-quail's `run-state-handed-in.md`: `tests/test_save.gd`, and the `Seat` class three suites
copied, now one helper. Tests only.

**Built.** Every save test makes a fresh `RunState`, hands it to `GameSave` and frees it, so the
suite's snapshot of the global run, its restore at the end and its hand-reset of the run's facts,
calendar and checkpoint are gone, with nothing left to put back; every check is kept. `tests/seat.gd`
holds the one `Seat`: a fresh run and its home, a boot of `main` handed a scratch-path save, and an
end that frees both and gives the observers back; the main, boot handing and atlas loading suites
use it. Three mutation runs of the save's restore and refusal.
