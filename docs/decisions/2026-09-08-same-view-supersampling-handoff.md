## Same-view supersampling handoff — 2026-09-08

The player requested a break after the analysis and instructed committing and pushing everything.
The supersampling draft was preserved separately on `feature/illustrated-supersampling`, commit
a2f2eb3, in `.claude/worktrees/illustrated-supersampling/`; it was not integrated into the actor PR
branch. It removed that branch's zoom option and introduced debug `--illustrated-render-scale 2`.
Main's renderer-facing viewport size and global canvas transform were scaled without changing the
logical camera/input space; a topmost ColorRect shader averaged 2×2 samples before the screen blit.

The exact [Godot 4.7 GLES3 source](https://github.com/godotengine/godot/blob/4.7-stable/drivers/gles3/rasterizer_gles3.cpp#L416)
forced nearest filtering for the final render-target-to-screen copy. An explicit destination
rectangle supported fitting a larger target, but did not itself provide weighted downsampling.
The draft's box prefilter addressed that distinction; no rendered evidence established its
correctness. CanvasItem texture filtering was separate from the final screen sampler.

Review identified unresolved defects: using the full window as the destination lost KEEP
letterboxing; `ViewportTexture.get_size()` did not establish the renderer's actual image size;
dimension caches could miss engine resets; reload restoration needed the original attachment;
and a headless post-draw diagnostic could remain suspended. A display run still needed to verify
all overlays were sampled, camera and HUD framing matched, and pointer/portrait/resize/reload
behavior stayed aligned. The worker's check.sh passed; presentation/orientation/stroller reported
74 passing assertions but Canvas/ObjectDB leak warnings, so this was not clean verification.
The illustrated visuals run reported 218 passing assertions and expected malformed-manifest
diagnostics. Lint and diff checks passed. The draft remained explicitly unvalidated.

A [baseline screenshot](../evidence/archive/session-captures/2026-09-08/illustrated-supersampling-baseline.png)
and its [whole capture run](../evidence/archive/session-captures/2026-09-08/rig-213228-seed2468684785-v0.7.0-54-gbb03202/)
were preserved for comparison. The command used screenshot delay 4.2, `--illustrated --seed
2468684785 --spawn square --walk 0.5s --press snapshot_burst 0.7` on bb03202. The fractional walk
script was rejected and ignored, leaving the player idle; this was not walking evidence.
The PNG was 1280×720 and the burst retained 24 original timed frames. A matching render comparison
should omit that invalid walk argument and retain the same seed, spawn, framing and capture delay.
No supersampled display capture was taken before the requested break.
