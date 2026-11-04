# minty-quail — The run flow and main suites read the booted game through its hand-ins and real frames (tests through public seams: W20) · 2026-11-04

minty-quail's `tests-public-seams.md`: `tests/test_run_flow.gd` and `tests/test_main.gd`, with a
finder for the readout's label in `tests/booted_main.gd`, and `tests/test_run_config.gd`. Tests
only.

**Built.** The run flow suite (private-read lines 4 to 0, `GameState` lines 6 to 0) reads the
section the flow began off the readout's label of a game booted on the escape's city, and the
reload through the pause screen's restart: the walk's tick counts while she walks, the restart asks
`main`'s `use_reload()` hand-in once, and the tick stops once the reload is asked for. The main
suite (3 to 0, `GameState` lines 69 to 0) checks the readout's interval on real frames, a node
taping each frame's delta, so a frame rebuilds the text exactly when the deltas since the last
rebuild have run out the interval, at any frame length; every boot sits on a run of its own in a
home, and the city ground tests build their city on a run of their own. Four mutation runs.

**Run config.** `test_run_config.gd` (4 to 0) no longer writes a resolved config's private
fields: the refused writes are the public fields', counted, and what the config was parsed from,
the movie flag and every word, is read back through `RunConfig.with_recipe()`, the call `main`
makes, so a parse that dropped either fails.

**Not done:** a setter of the stored words or the movie flag that took a write after the build,
which nothing public writes, so no check can reach it without a private write.
