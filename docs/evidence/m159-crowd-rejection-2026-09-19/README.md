# Crowd contribution rejection measurement

This record measures a behavior-preserving reduction in crowd contribution work for M159,
a slow frame names the frame that was slow. Its acceptance criterion comes from
[PLAYTEST-85](../../playtests/PLAYTEST-85.md): the deliverable is an optimization.

The retained headless workload and ordinary-gameplay frame traces answer different questions.
The workload isolates contribution sweeps over repeated identical simulated crowd states;
the frame traces report whole-game CPU callback intervals over equal active-play windows.
Neither is phone timing or a physical display presentation measurement.

## Production change and correctness

`CrowdAgent.contribution_at()` rejects points beyond the maximum possible forward reach before
querying velocity, pocket state or elliptical distance. The conservative radius is the larger
of the ordinary outer radius and an active jolt's outer radius, divided by
`1 - FIELD_ECCENTRICITY_MAX`. Since the effective distance is `r * (1 - e * cos(theta))`,
anything strictly outside that circle contributes exactly zero. Inside it the calculation is
unchanged. No caching, RNG, source order, gameplay values or presentation policy changes.

`tests/test_crowd_contributions.gd` compares against the unfiltered calculation for both kinds,
stationary and moving states, hurry, saturated eccentricity, horns and larger jolts, points at
and around the bound, a curved heading and a position/jolt change without a clock advance.
The probe also checks every individual source and the aggregate outside its timed block.

## Repeated identical-workload comparison

```sh
./tools/test.sh probes/m159_contribution_cost.gd
```

The probe generates seed 4242 once, then starts days 1 and 9 from the same crowd RNG seed on
each of three repetitions. It uses `Crowd.step()` to keep motion, traffic, signals and door
holds together. Its query point travels south for three seconds, then east/west in two-second
legs, at walking speed; this is a crowd workload, not a collision-driven player or full day.
Five simulated seconds warm it; the next six seconds supply 180 samples at 30 Hz. Each sample
times 32 calls to `Crowd.excitement_sources_at()` including the normal positive-source list
allocation and sum. Simulation, reference evaluation and output are outside the timer.

`workload-before.log` and `workload-after.log` retain every raw row and runner result.
The ordinary production source before is `7035fc6aa7da21ed2f8354fa07ce1a74d779c9ab`; after adds
only the contribution rejection. Both use the same new probe and oracle. Exact source SHA-256
values are in [source-hashes.txt](source-hashes.txt). For reproduction, apply the retained probe
and oracle to that checkpoint; the production before/after diff is solely the early rejection.

The following command refuses different workload data or failed parity, then computes nearest-rank
statistics pooled over the three repetitions. Values are microseconds per complete source sweep.

```sh
cd docs/evidence/m159-crowd-rejection-2026-09-19
jq -R -s -f compare_workloads.jq workload-before.log workload-after.log
```

| Workload | Version | Samples | p50 µs | p95 µs | p99 µs | Maximum µs |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| Day 1, 234 agents | Before | 540 | 387.813 | 394.719 | 406.313 | 438.625 |
| Day 1, 234 agents | After | 540 | 59.375 | 63.531 | 66.125 | 72.156 |
| Day 9, 50 agents | Before | 540 | 82.875 | 86.375 | 89.219 | 121.313 |
| Day 9, 50 agents | After | 540 | 10.719 | 11.844 | 13.219 | 22.875 |

Day 1's median is 84.7% lower and day 9's 87.1% lower. Every non-timing row is identical between
versions. Each day-1 repetition includes 71 query states with positive contributions, while the
day-9 path is entirely out of earshot and measures the zero-contribution case. The parity matrix
separately covers contributing cars and horns. The probe's fixed simulation cadence and batching
are deliberate isolation; these numbers do not estimate an entire phone frame or a live-call
frequency. Near sources pay the added bound check before their original calculation.

## Ordinary-play frame traces

Every invocation uses the same unmodified engine and flags, with normal loss and meter behavior:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path . -- \
  --frame-trace --after 12 --no-title --seed 4242 \
  --walk 3s2e2w2e2w1e --no-telemetry
```

These runs are screenshot-free, without bursts or invincibility. The observer omits the first
five seconds of active-play raw-clock warmup. The analysis takes positive intervals ending no
later than six seconds after the first retained anchor, rejecting short captures or gaps:

```sh
jq -f docs/evidence/m159-frame-traces-2026-09-19/six_seconds.jq \
  docs/evidence/m159-crowd-rejection-2026-09-19/before_a.json
```

| Trial | Intervals | p50 ms | p95 ms | p99 ms | Maximum ms | Over 60 Hz budget |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| before_a | 545 | 9.569 | 23.919 | 24.171 | 24.795 | 56 |
| before_c | 541 | 9.592 | 23.939 | 24.220 | 24.780 | 51 |
| before_d | 576 | 9.324 | 16.668 | 26.050 | 26.307 | 29 |
| after_a | 676 | 9.090 | 12.242 | 25.219 | 26.098 | 12 |
| after_b | 695 | 8.972 | 10.467 | 16.710 | 25.809 | 9 |
| after_c | 699 | 8.760 | 10.313 | 16.536 | 26.158 | 5 |

`before_b` is preserved but rejected: it retains only 30 samples spanning 0.324 active seconds.
The automated input exits normally at its requested time; the active day stops contributing
samples early. With telemetry disabled this record does not identify the loss cause. The
comparison therefore excludes an incomplete active window, not an inconvenient timing outlier.
All complete trials have one segment, no dropped samples, and moving player positions. First
positions differ by at most one walking step; final x positions vary by about nine pixels.
Frame-dependent crowd interactions are not an exact replay.

Host: Apple M2, macOS, Godot 4.7.2 stable official `ed1daf0bf`, OpenGL on Metal with
`gl_compatibility`/`opengl3`, 1280×720 window and viewport, reported refresh 60 Hz, VSync enum 1,
no FPS cap, main-thread rendering. Readout is on, graph and telemetry off. The raw JSON records
the environment at both ends. The experiment order is workload-before, before_a/b/c/d,
workload-after, after_a/b/c; runs are serial, with other agents' Godot/CPU-heavy work paused.
Ordinary desktop activity remains uncontrolled, and the local thermal-status query fails to
report a thermal state. No thermal or system-idle guarantee is inferred.

These whole-game distributions improve in this batch, but are not a randomized crossover and
include route divergence and an early-ending baseline. The conservative claim is the reproducible
reduction in the isolated query workload. Long intervals remain: neither perceived smoothness nor
the elimination of stutter is established. The earlier toggle trials remain inconclusive. Phone
CPU attribution, threadless atlas timing, release events and memory/residency comparisons remain
separate work. No shipping pacing or atlas-policy decision follows.

## Verification

`./tools/check.sh` passes. Focused `test_crowd.gd`, `crowd_contributions`, `halo`, `frame_trace`
and `meters` suites pass, with no engine errors in their final runs. The meter fixture explicitly
selects the physics camera callback required by project interpolation, removing its pre-existing
engine override warning. Both retained workload logs have zero parity failures; the rejecting
comparison confirms all non-timing rows match. `./tools/lint.sh` and `git diff --check` pass.
The unfiltered suite is left to CI. The separately documented ground-reference/runner diagnostic
defects are not fixed or represented as clean validation here.
