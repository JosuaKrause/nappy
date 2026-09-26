## M159 — Cheaper crowd contribution sweeps · measured and optimized 2026-09-19

The player clarified in [PLAYTEST-86](../playtests/PLAYTEST-86.md): "well the point was to actually
do some optimizations. measurement is nice and make sure it's fully recorded but the core is to
make things faster". Instrumentation alone was not the deliverable. The raw callback recorder,
bounded atlas spans and original inconclusive toggle experiments remain preserved in
[the frame-trace record](../evidence/m159-frame-traces-2026-09-19/README.md); their limitations do not
prevent optimizing a separately isolated, demonstrably expensive calculation.

**The optimization.** Every baby/halo crowd sweep called `CrowdAgent.contribution_at()` for every
body and calculated velocity, pocket state and elliptical distance even for distant sources.
The function now returns zero first when squared distance exceeds the square of
`max(ordinary_outer, active_jolt_outer) / (1 - FIELD_ECCENTRICITY_MAX)`. The ellipse kernel is
`r * (1 - e * cos(theta))`, with `e` capped, so nothing outside this conservative circle can reach
either falloff. The bound covers hurried walkers and turning cars without computing velocity.
It reads live jolt state and position on every call: no cache, new RNG draw, gameplay number,
tick cadence, pacing switch or atlas policy changes. Contributions within the bound still use
the identical original calculation.

**Measured work.** The retained probe steps a generated crowd with its real traffic/door machinery,
warms five simulated seconds and measures six more at 30 steps/second, over three repetitions
each for days 1 and 9. Each timed sample averages 32 source sweeps; timing excludes simulation
and reference parity checks. On this Apple M2 host, the pooled day-1 sweep median changes from
387.813 to 59.375 microseconds (84.7% lower), p95 from 394.719 to 63.531; day 9 changes from
82.875 to 10.719 microseconds (87.1% lower). Every source is compared exactly against the full
calculation outside the timer. Before/after non-timing rows, source totals and positions match
exactly. Day 1 has positive contributions; day 9's query path has none, so the latter measures
the quiet-path case. These are query costs, not whole-game frame times or phone results.

**Ordinary play.** Three complete before and three after traces use identical twelve-second
walking inputs, five seconds of raw-clock warmup, and the same first six active seconds. The
observed median ranges are 9.324–9.592 ms before and 8.760–9.090 ms after. The p95 ranges are
16.668–23.939 ms before and 10.313–12.242 ms after, but after-run maxima remain 25.809–26.158 ms.
One additional before trace is rejected because its active sample lasts only 0.324 seconds;
its raw output is preserved. The loss cause is not recorded with telemetry disabled. All complete
trials move, but frame-dependent crowd interactions and final positions differ slightly. Runs
are serial with other agents' heavy work paused, while ordinary desktop activity remains. This
supports the isolated query optimization, not a claim that stutter is solved or that all observed
frame-distribution change is causal. Phone measurement and remaining-stall attribution stay open.

**Evidence and choices.** [The full measurement record](../evidence/m159-crowd-rejection-2026-09-19/README.md)
retains raw workload rows, frame traces, logs, hashes, launch commands and rejecting analysis
filters. The maximum eccentricity bound is deliberately looser than a current-speed bound so
the early rejection does not pay for the velocity calculation it removes. New parity tests cover
stationary/moving/hurried bodies, saturation speed, both kinds, horns, large jolts, a curved heading
and position/jolt changes without advancing the body's clock. The original float result is kept
for every contributing body. The branch remains based on its existing checkpoint because the
player explicitly prohibited merging main during this work; its later crowd changes need
integration review before this can land. M163, ground atlas reference parity, and M164, engine
errors fail the gate, remain separate documented follow-on briefs, with no fix in this change.
The boot gate and focused crowd, contribution, halo, meter and frame-trace suites passed. The
meter test's camera fixture explicitly selects physics processing, removing the engine's
interpolation override warning; this changes no gameplay camera. Doc lint, whitespace and
raw-workload parity checks passed; the full suite remains CI's gate.
