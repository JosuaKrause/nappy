---
name: session-captures
description: Capture and preserve gameplay stills and animation bursts, with video conversion and timing provenance. Keep runtime evidence distinct from design guidance.
---

# Session captures

Everything under `docs/evidence/archive/session-captures/` is dated runtime evidence. It records a
particular build, seed, route and presentation state; it is not an approved visual reference.

For a new capture, use a display-capable session and a bounded command such as:

```sh
tools/shot.sh /private/tmp/nappy-shot.png 4 --seed 4242 --spawn arterial --walk 2s3e
```

Inspect the PNG, then copy it into `docs/evidence/archive/session-captures/YYYY-MM-DD/` with a name
that identifies its source and scenario. Add provenance in the dated folder only when needed; put
the reusable workflow here. If capture aborts or the environment is headless, report that
limitation instead of fabricating a frame. Update every in-repo link when moving an existing
capture.

## Animation sequences

Use Shift+P during desktop debug gameplay to record a bounded PNG burst; P remains the single
screenshot control. Each sequence lives in its own `asked/burst-<id>/` subfolder of the current
run. Preserve its numbered PNGs and `burst.json` timing record together. A still cannot establish
gait, sliding or smooth turns; inspect the ordered sequence and its actual capture times.

Run `./tools/clip.sh` to convert the newest completed burst using ffmpeg, or pass a burst folder
explicitly. The default MP4 is beside the sequence folder, named `burst-<id>.mp4`; conversion
preserves the original frames. Video is a viewing convenience, while the PNGs retain details
for frame-by-frame inspection. Do not assume the target capture frequency was achieved: use the
recorded timestamps when judging speed or stutter. Capture and encoding overhead are not proof
of a gameplay animation defect.

For a scripted check, trigger `--press snapshot_burst 1` through the existing screenshot rig.
Keep an external timeout and let the burst finish before the rig quits. This is one bounded
capture invocation, not authorization for repeated windowed runs. Preserve whole player run
folders when citing them in docs, including sequence folders, sidecars and sibling videos.
