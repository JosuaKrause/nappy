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

New evidence goes in `docs/evidence/<words>-<slug>-<date>/`, where `<words>` are the two words of
the queue entry or playtest it belongs to (`busy-otter-roof-cases-2026-09-27/`), and an entry or
playtest from before names gives its number instead (`m203-roof-cases-2026-09-26/`,
`playtest-144-phone-v0.18.0-2026-09-26/`) *(PLAYTEST-144, the table the player accepted:
"`docs/evidence/busy-badger-slug-date/`, taking the entry's name")*. The slug says what it shows,
so two folders for one entry differ by their slugs. When selected artifacts come from a telemetry
run, keep them under that run folder's original name. `archive/session-captures/<date>/` holds
earlier captures. Update every in-repo link when moving one. If capture aborts or the display is
headless, report it instead of fabricating a frame.

**Retain what the run or rig was meant to show, not everything it happened to write.** Keep the
stills, burst frames, timing sidecars, maps or log excerpts that support the intended claim and its
limits. Keep relevant primary player evidence, contradictory results and failed trials; selection
must not turn mixed evidence into a clean success. Leave unrelated automatic screenshots, generic
boot output, irrelevant logs and redundant copies in scratch space. A complete `run.log` belongs
only when its ordered behavior, non-replayable player input, diagnostics or otherwise unrecorded
provenance supports the claim.

Every evidence folder has a README or manifest that names the claim and its limits and records the
source revision, command and settings, plus the seed and timing when they matter. It also says
which run artifacts were retained and why, so a selected still has enough ancestry to interpret
without requiring unrelated neighbors from the same run.

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
