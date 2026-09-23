---
name: session-captures
description: Where gameplay stills, bursts and run folders are kept as evidence, and what a frame may be said to prove. Load BEFORE copying a capture into docs/evidence/.
---

# Session captures

Everything under `docs/evidence/archive/session-captures/` is dated runtime evidence. It records a
particular build, seed, route and presentation state; it is not an approved visual reference.

For a new capture, use a display-capable session and a bounded command such as:

```sh
tools/shot.sh /private/tmp/nappy-shot.png 4 --seed 4242 --spawn arterial --walk 2s3e
```

New evidence goes in `docs/evidence/<mNNN|playtest-NN>-<slug>-<date>/` as the whole run folder
under its original name (playtest-feedback, "Evidence lives in the repo"). `archive/session-captures/<date>/`
holds earlier captures. Update every in-repo link when moving one. If capture aborts or the
display is headless, report it instead of fabricating a frame.

## Animation sequences

Motion is a burst. What it writes and how `tools/clip.sh` converts it is in `docs/TELEMETRY.md`,
"Animation bursts". Judge speed from `burst.json`'s frame times, never the 12fps target; capture
and encode overhead is not an animation defect.
