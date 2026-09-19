# Raw post-draw measurements — 2026-09-19

These are diagnostic CPU callback intervals, not physical display presentation or GPU timings.
Each JSON contains its own schema, raw timestamps, frame IDs, same-callback counters, environment,
flags and summary. The neighboring log is that process's stdout. The telemetry-on run's complete
run folder is retained beside them; it contains its startup map and ordered log, with no `auto/`
or `asked/` captures. No trial requests a screenshot, burst or invincibility.

The initial seven trials measure commit 37042d184bcdb541047368a84ad1eaf1535f0b38. All runs use seed 4242,
Godot 4.7.2 stable official (ed1daf0bf), macOS, Apple M2, `gl_compatibility` / `opengl3`
(OpenGL on Metal), a 1280 × 720 viewport/window and a reported 60 Hz display. The render-thread
setting is 1. VSync's driver-reported enum is 1 (enabled), except the disabled-VSync trial's 0.
Metadata at both ends records the same display configuration. A VSync getter is not proof of
compositor pacing: callback rates can exceed the reported display refresh.

Godot consumes the pacing switches before `OS.get_cmdline_args()` exposes arguments, so these
files' `engine_flags` arrays are empty even for the VSync/FPS trials. Their effective VSync and
FPS-cap fields and the launch variations below establish the settings. The recorder's metadata
explicitly marks this incomplete argument list; these retained files identify the earlier
measured source above and are not rewritten to add fields it did not record.

## Recipe

Run each trial serially, with no headless suite running alongside it. The base invocation is:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path . -- \
  --frame-trace --after 20 --no-title --seed 4242 \
  --walk 3s2e2w2e2w2e2w2e2w1e --no-telemetry
```

The frame trace omits the initial five seconds of wall-clock warmup. The input harness walks
three seconds south, then reverses along the street; `--after 20` exits without a viewport
capture. Its input/exit clock is simulation delta; the measurement clock is raw monotonic time.
Every trial has moving positions in its retained samples. Frame-driven movement and crowd
interactions can diverge across pacing modes despite identical seed and inputs.

The trials run in the order below. Relative to the base invocation:

- `readout_off` adds `--press key:4 0.1` after `--`.
- `graph_on` adds `--layers 6` after `--`.
- `telemetry_on` omits `--no-telemetry`.
- `vsync_off` adds engine `--disable-vsync` before `--`.
- `cap60` adds engine `--max-fps 60` before `--`, keeping normal VSync.
- `baseline_repeat` repeats the base invocation unchanged.

The corresponding state columns confirm each intended layer/log setting throughout capture.
All buffers have zero dropped samples. The outer process watchdog is 40 seconds; all trials
exit normally and export before it expires.

## Whole retained captures

Times are milliseconds. The last column counts callback intervals strictly above 16⅔ ms; it
does not count physical dropped frames. The reported refresh budget equals the 60 Hz budget.

| Trial | Intervals | Span (s) | p50 | p95 | p99 | Max | Over 60 Hz budget |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| baseline | 478 | 6.968 | 13.801 | 26.753 | 28.221 | 28.803 | 77 |
| readout_off | 884 | 14.484 | 16.347 | 19.609 | 28.473 | 29.866 | 344 |
| graph_on | 689 | 14.500 | 21.081 | 25.421 | 31.482 | 36.617 | 640 |
| telemetry_on | 705 | 14.515 | 20.156 | 25.875 | 29.694 | 36.108 | 580 |
| vsync_off | 783 | 14.503 | 17.744 | 23.334 | 26.974 | 33.946 | 555 |
| cap60 | 860 | 14.512 | 16.646 | 19.776 | 25.848 | 29.148 | 423 |
| baseline_repeat | 869 | 14.501 | 16.633 | 18.113 | 26.258 | 31.721 | 421 |

The first baseline stops collecting active-play samples earlier than the other trials. Its
shorter capture must not be compared as if all seven summaries cover the same duration.

## Common first six seconds after warmup

Select positive intervals whose ending timestamp is at most 6,000,000 microseconds after their
capture's first anchor. Percentiles use nearest rank, exactly like the exporter. The final row
in each selection lands slightly before six seconds because the next callback crosses the cut.

| Trial | Intervals | p50 | p95 | p99 | Max | Over 60 Hz budget |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| baseline | 414 | 13.710 | 26.530 | 28.217 | 28.803 | 68 |
| readout_off | 374 | 15.906 | 28.109 | 28.828 | 29.866 | 106 |
| graph_on | 302 | 19.778 | 24.543 | 31.482 | 34.520 | 258 |
| telemetry_on | 311 | 19.297 | 24.356 | 26.696 | 32.638 | 236 |
| vsync_off | 292 | 21.017 | 25.213 | 31.777 | 33.946 | 275 |
| cap60 | 360 | 16.554 | 18.351 | 27.973 | 29.148 | 158 |
| baseline_repeat | 359 | 16.599 | 17.935 | 28.693 | 29.023 | 167 |

## What the evidence supports

The recorder attributes a long interval to its own callback. For example, the first baseline's
maximum ends at monotonic 11,414,566 µs, process/draw frame 500, with a 28,803 µs interval,
564 draw calls, 1,711 render objects, 50 live events, 156 cumulative picture loads and 16
collected atlases. Those counters come from that callback, not a later reporting frame.

The short trials do not isolate a cause. The first and repeated baselines differ despite
identical flags; their common-window medians are 13.710 and 16.599 ms, while boot city generation
also ranges from 0.445 to 0.786 seconds across the retained runs.
Machine-load drift and route divergence remain uncontrolled. The data cannot assign the graph,
readout, telemetry or VSync a causal cost from these single comparisons.

The capped trial averages about 59.3 callbacks/second over its complete retained window and
60.0 over the common window, so 60 fps is approximately sustainable in this short trial. It
still has long intervals; its common-window p99 is 27.973 ms. This is not a shipping pacing
decision, nor proof that a cap removes perceived stutter. A quiet-host repetition on the player's
laptop, and perception during the route, remain useful acceptance checks. Phone CPU profiling
and atlas-phase timing remain separate investigations.

## Four baseline repetitions with equal comparison windows

`repeat_a` through `repeat_d` measure the runtime source at
71db375929b1db9a0177104edd94b0d070cb25bc. Their dirty build marker comes from the new evidence
files, not runtime edits. Each process exits normally. They run serially, with the other agent's
Godot and CPU-heavy work held during the block. No test suite runs alongside them. The host is on
AC power with a full battery; `pmset -g therm` reports no recorded thermal or performance warning.
A process snapshot still shows WindowServer, GIMP and other desktop services doing work. This is
a reduction of our own contention, not a claim that the player's laptop is globally idle.

The exact invocation from the M159 worktree, identical for all four trials, is:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path . -- \
  --frame-trace --after 12 --no-title --seed 4242 \
  --walk 3s2e2w2e2w1e --no-telemetry
```

The shorter, twelve-second input ends before the early loss seen in the initial baseline. It
retains the same first twelve seconds of that input route. Each trial has five seconds of raw
wall-clock warmup, one uninterrupted active-play segment, zero omitted samples, and the same
six-second comparison window starting at its first retained anchor. Include only positive
intervals ending within that window; the callback crossing its end stays outside it. Input and
exit use simulation delta, so complete retained spans are 6.554, 6.604, 6.558 and 6.587 seconds;
those unequal tails are not used for the comparison. Every route moves and ends at
(2646.807, 2863.953) pixels. First retained positions differ by at most one 30 Hz walking step.

| Trial | Intervals in six seconds | p50 ms | p95 ms | p99 ms | Max ms | Over 60 Hz budget |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| repeat_a | 506 | 10.623 | 23.946 | 25.869 | 29.856 | 44 |
| repeat_b | 551 | 9.410 | 25.687 | 26.063 | 26.286 | 43 |
| repeat_c | 536 | 9.842 | 23.863 | 26.041 | 26.276 | 44 |
| repeat_d | 541 | 9.729 | 23.795 | 24.100 | 24.824 | 54 |

The display/renderer settings match the original normal-VSync baseline: 60 Hz reported refresh,
VSync enum 1, no FPS cap, Apple M2, OpenGL on Metal, 1280 × 720, and render-thread model 1.
The added metadata reports that the main thread owns rendering. Layer 4 is on, layer 6 and
telemetry are off throughout. The raw JSON and stdout for every repetition are retained.

Recompute any six-second row from this directory with `jq -f six_seconds.jq repeat_a.json`
(substitute the desired raw trace). The filter rejects a short trace or a gap within the window.

The median range is about 13% of the lowest median; the callback count varies by about 9%, and
the share over the 60 Hz budget ranges from 7.8% to 10.0%. Baselines therefore do not establish
the repeatability needed to rank modest toggle costs. No new toggle trials are interpreted.
The long-interval tail recurs, but the evidence does not identify its cause or establish perceived
smoothness. Neither a globally quiet host nor exact replay of frame-dependent crowd interactions
is established.
