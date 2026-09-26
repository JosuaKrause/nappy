# Crowded-scene frame profiling

**The measurement record is retained; the current follow-up is plan only.** The player asks to
write down the [separate-animation plan and full analysis](scenery-animation-separation.md).
Do not start implementation or additional measurements until the player resumes them.
This is the measurement method for M159, a slow frame names the frame that was slow. The source is
[Playtest 145, measure the work in a crowded scene](../playtests/PLAYTEST-145.md).

## Question and deliverable

Find a normal crowded location with cars and pedestrians and measure where each frame's time
goes. Desktop measurements are sufficient for this investigation; neither reproducing a desktop
stutter nor obtaining phone access is a prerequisite. The connection to current mobile stutter
is a hypothesis to assess, not an established result.

Deliver a table of subsystem CPU time per rendered frame and per physics tick, with median,
tail and maximum costs, call counts and actual active/visible entity counts. Preserve the raw
samples, scene setup, engine/build identity, launch commands and analysis beside the report.
Identify expensive work and proposed optimization targets; this investigation does not change
gameplay, population, tick rates or visual behavior. The wider optimization request remains open.

## Measurement sequence

1. Fetch current remote state and inspect existing investigation worktrees before editing.
   Read `CLAUDE.md`, `HANDOFF.md`, the M159 entry in `TODO.md`, and the relevant skills. Reuse
   any sound partial work after inspecting it. Start fresh agents if the old ones are cold.
2. Import and boot the measurement checkout with `tools/check.sh` before running a probe.
   A bare launch with a stale class/import cache is not performance evidence.
3. Select a reproducible busy arterial or intersection in an ordinary day. Start by inspecting
   day 1 with seed 4242 and the existing `--spawn arterial` rig. This is a candidate setup,
   not a verified crowded location. Record cars, pedestrians and events both active and visible;
   verify that the player and traffic actually move during the retained window.
4. Prefer the engine's script profiler and existing raw frame trace. Obtain every-frame script
   timings through the remote debugger if practical; verify the installed engine's protocol.
   If only the local profiler is usable, explicitly label its once-per-second sampled frames.
   Do not report that output as every frame or use startup-inclusive totals as gameplay cost.
5. Separate warmup and day setup from a bounded active-play window. Repeat the same scene and
   route, one timed process at a time, with equal retained active windows. Keep normal source
   scans and loss conditions: no `--invincible`. Use dev flags or `--no-save` to protect saves.
   Reject paused, summary-screen or prematurely ended windows and retain the rejection reason.
6. Measure the groups below, then use a narrowly scoped headless probe only where a costly
   group needs further decomposition. The probe should reuse real crowd state and preserve
   its traffic/movement ordering. Label it as isolated CPU work, not a rendered frame.
7. Retain one or two bounded rendered runs when needed for drawing and render submission.
   Headless runs do not measure drawing or GPU cost. Keep telemetry/debug presentation settings
   explicit; normal-play cost and diagnostic overhead need separate labels.
8. Summarize what dominates typical frames and what dominates expensive frames. Distinguish
   measured attribution, code-derived hypotheses and unmeasured GPU/browser/display time.
   Record findings in `DECISIONS.md` with raw evidence, narrow the open queue item, and propose
   any behavior-preserving optimization with its required before/after and parity checks.

## Attribution groups

| Group | Entry points and work to separate |
| --- | --- |
| Crowd motion | `CrowdAgent._process`: walking, steering, turns, recycling, gait and redraw decisions |
| Traffic and contact | `Crowd._physics_process`: signals, lane queues, junction priority, door holds, player interactions |
| Baby and source fields | `Baby._physics_process` and `WorldContext.excitement_sources_at`: meter source queries and accumulation |
| Halo and danger prediction | `ExcitementHalo._process`: source selection, landed history, projected impact, halo assignment; caret callers that may repeat projections |
| Events | `EventManager._physics_process`: streaming/director/placement, warnings and contacts; `EventInstance._process` for live behavior |
| Script drawing | Crowd/event `_draw`, halo body tracing, UI and world draw-list rebuilding |
| Other script work | Player/camera, main loop, telemetry, debug readout and frame graph |
| Engine and rendering | Physics engine, render submission and residual frame interval, with GPU/presentation attribution only where directly measured |

Use exclusive/self times for additive totals, or non-overlapping outer callbacks. Inclusive
parent and child times must never be added together. Retain physics tick counts per rendered
frame so a frame with no tick is distinguishable from one with multiple ticks. Measure profiler
overhead or state it as an unresolved limit; a residual is not automatically GPU time.

## Code-derived candidates, not measured bottlenecks

`ExcitementHalo._process` gathers every active crowd agent and event, then performs several
passes over them each rendered frame. Its `expected_gross_at` calls can sample a nearby source
through a five-second horizon in quarter-second steps, plus the current position. This is a
reason to measure prediction separately from the baby's ordinary field sweep, not evidence
that it dominates.

Crowd movement runs at rendered-frame cadence while traffic/contact decisions run at physics
cadence. Preserve that distinction in the probe. Off-screen active agents can contribute CPU
work even when their pictures are not visible. Halo drawing traces the body's picture at
several offsets, so its draw cost also needs a separate reading.

## Reuse and verification

- `tests/probes/m159_contribution_cost.gd` provides a deterministic isolated crowd-query workload.
- `docs/evidence/m159-crowd-rejection-2026-09-19/README.md` explains its scope and earlier results.
- `src/telemetry/frame_trace.gd` and `docs/TELEMETRY.md` describe raw callback traces.
- `src/telemetry/frame_cost.gd` reads engine monitors whose process/physics values are previous
  second maxima, not this frame's own costs; do not use them for per-frame attribution.
- `src/dev/dev_flags.gd` supplies existing crowd/event/shadow/motion skip probes. Such toggles
  are diagnostic interventions and do not by themselves establish a causal timing delta.

The [measurement record](../evidence/entity-performance-2026-09-26/README.md) retains the native
every-frame breakdown, raw streams, analyzer outputs and rejected trials. It distinguishes
steady entity and prediction work from building-redraw spikes, and states the profiler's
material perturbation. The player's desktop stutter observation and separate-animation request
are in [Playtest 145](../playtests/PLAYTEST-145.md); the open implementation is M159's queue entry.
Repeat equal active windows when measuring an optimization and keep observer/profiler settings
explicit. Run the import/boot check and only the affected probes/tests; no local full-suite run
is needed for this investigation. Documentation-only verification is `tools/lint.sh` and a diff
check. Merging requires the player's authorization and independent review.
