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

New evidence goes in `docs/evidence/<name>/`, named after the queue entry or the playtest it
belongs to (`2026-09-27-busy-otter`, from `tools/new-name.sh`; the entries and playtests from
before names give `<mNNN|playtest-NN>-<slug>-<date>`), as the whole run folder under its original
name (playtest-feedback, "Evidence lives in the repo"). A second folder for the same entry takes
`-2` and on. `archive/session-captures/<date>/`
holds earlier captures. *(2026-09-23: the player chose this over copying a single named PNG into
the dated archive folder, which had drifted from playtest-feedback's "copy the whole `<run>/`
folder" and from how every current evidence folder is actually named.)* Update every in-repo
link when moving one. If capture aborts or the display is headless, report it instead of
fabricating a frame.

## Animation sequences

Motion is a burst. What it writes and how `tools/clip.sh` converts it is in `docs/TELEMETRY.md`,
"Animation bursts". Judge speed from `burst.json`'s frame times, never the 12fps target; capture
and encode overhead is not an animation defect.

**A short clip is committed only when a pull request needs it to show motion; a recording of a
whole run never is.** *(2026-09-25: "no videos should be checked in of course" · "short clips like
that are fine if they're needed to convey something in a PR".)* A burst's MP4 belongs in an
evidence folder when a still cannot show what the PR changed — a turn, a gait, a pursuer arriving.
A review video of a rig run and the trailer are made and watched locally and stay out of the
repository.
