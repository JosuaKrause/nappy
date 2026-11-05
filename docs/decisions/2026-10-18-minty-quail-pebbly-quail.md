# minty-quail — The runner shuffles and repeats suites, and every CI shard runs in a shuffled order it prints (isolated tests) · 2026-11-05

minty-quail's `tests-isolated.md`, part of its flaky half. Test tooling: the runner
(`tests/run_tests.gd`), `tools/test.sh` and `.github/workflows/ci.yml`.

**Built.** The runner takes `--shuffle SEED`: the suites it runs, after filtering and sharding, run
in an order drawn from the seed, the same seed giving the same order, and it prints the seed, the
order and the command that replays it before any suite runs. `--repeat N` runs the chosen suites N
times in one process, each pass in an order of its own drawn from the seed and the pass, and tags a
failure with its pass. `tools/test.sh` passes both through on every path; which suites go on which
shard is unchanged, only the order within a shard. Every CI shard runs shuffled with the run's id as
the seed and prints the local command that replays its order. Cost recording reads the measured rows
as a set, so order does not reach it, and refuses `--repeat`. One full local run, shuffled, found no
order-dependent check. The item no longer names the telemetry suite's run-folder tests among what
writes a real folder, since they are handed a scratch one.

**Choices, open to overturn.** Every CI run is a shuffled run, so an order dependence shows on any
pull request rather than only when two land together on `main` (the orchestrator's proposal); the
seed is the run's id, so re-running a run replays its order (the builder's call). Any other argument
still reaches the test scene, which reads its own flags, and filters the suites as before.
