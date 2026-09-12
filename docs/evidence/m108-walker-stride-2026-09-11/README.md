# M108 — every living thing that moves has a stride, walkers first

Evidence for the walker's second gait frame (`docs/DECISIONS.md`, "M108 — Eight-direction entity
graphics · the crowd walkers", extended here with the alternation) and its runtime binding in
`CrowdAgent._advance_walker_gait()`/`_walker_gait_frame()`.

## Source review

`walker-stride-native.png` and `walker-stride-3x.png` render all five authored views — front,
back, side, front_diagonal, back_diagonal — with frame a beside frame b, body tinted (sage,
`Palette.COATS[5]`) and trim above, straight from the SVG source text through the
`tests/probes/m108_walker_stride_sheet.gd` probe (`tools/test.sh probes/m108_walker_stride_sheet.gd`).
Every row shows the same coat and head in both columns and the legs visibly crossed in the b
column; the front/back/side coat and head sit a pixel higher in the b column too, the same lift
the mother's own gait-b frames carry.

## Gameplay burst

`run/rig-220957-seed4242-v0.8.2-624-gc5860ee-dirty/` is the whole telemetry run folder from:

    tools/shot.sh /tmp/m108-walker-burst/final.png 6 --seed 4242 --spawn arterial --press snapshot_burst 1.5

`--invincible` does not exist on this branch's base (`c5860ee`; checked `src/dev/dev_flags.gd`),
so the run is kept to 6 seconds total rather than relying on it. `--spawn arterial` places the
camera at the busiest pavement in the city (`src/main.gd`'s own comment: "the busiest pavement in
the city, for looking at the crowd's noise floor"), and `--press snapshot_burst 1.5` taps the
burst key 1.5s in. The burst itself is `Telemetry.BURST_DURATION_SECONDS` (3.0s) at
`BURST_TARGET_FPS` (12), landing 28 frames in `run/.../asked/burst-4079262-001/` (also converted
to `burst-4079262-001.mp4` beside it via `tools/clip.sh`). Standing still at the arterial for the
whole run also lets the meter run away — `run.log` shows the burst completing at 4.5s and the day
ending at 9.9s ("lost_crying … She started crying. There is no settling her now."), which is the
arterial's own noise floor doing exactly what its doc comment says it does, not a stride defect,
and it happens well after every walker frame below was already captured.

**Frames where the feet visibly pass:** open `frame-0001.png` through `frame-0006.png` and look
at the screen region roughly `(790,150)`–`(860,310)` (1280×720 capture) — a front-facing walker
queued behind slow-moving traffic near the arterial crossing holds the legs-crossed, feet-passing
pose (gait frame b) for that whole span, directly below a second walker in the ordinary legs-apart
rest pose (gait frame a) at roughly `(790,50)`–`(860,150)` in the same frames. The pair sitting
side by side in one frame is the plainest way to see both poses without forcing either: the queued
walker's own `velocity()` is nonzero but small (it is following the walker ahead of it rather than
fully stopped), so its `_walker_gait_phase` advances slowly enough to hold frame b for the whole
burst rather than completing a visible flip in 3 seconds — the same "the window is too short to
photograph on purpose without forcing it" limitation `docs/DECISIONS.md`'s crowd-walker entry
already notes for the diagonal views. Faster walkers elsewhere in the same burst (for example the
pavement at the bottom of the frame, visible from `frame-0001.png` onward) cover real ground
between frames, which is the more general evidence that the stride is tied to distance covered
rather than to a fixed timer.
