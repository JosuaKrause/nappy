priority: later

# olive-lark — The frame-profile launcher runs a day that ends under it · filed 2026-11-22

**Found** by the agent of pull request #1636 (minty-quail, the baseline's reading after row 4b); `docs/evidence/minty-quail-baseline-2026-11-09/` holds the runs and says how they were made.

**What holds.** `tests/probes/entity_frame_profile.gd` launches the game on `--seed 4242 --day 1 --spawn arterial --walk north --no-title --no-focus-pause --no-save --no-telemetry --frame-trace --after 20`, and its analyzer (`entity_frame_profile_analyze.py`) accepts a run only if the day runs for the whole window and she covers about 552 px north. On main all six runs of the unmodified launcher (three profiled, three with the profiler disabled) were rejected, with callback-interval medians of 8.3 ms and the reasons `paused or ended day`, `northward net movement below 450 pixels; expected about 552`, `north input not held throughout retained window` and `profiler physics callback counts disagree with scene tick deltas`. The cause the baseline's evidence README found on the placement-closed tree is that the day ends: the placed rows on her line north (a leaf blower, then a homeless yeller) make her cry and lose the day at about 7.5 s, `lost_crying`, long before 20 s. A launcher copy with `--invincible` added is accepted every time; the evidence README says it is that copy's numbers that are comparable.

**The command that shows it:**

    # the launcher is a scene; its header names ENTITY_PROFILE_RENDERED and the collector
    # the six rejected summaries: docs/evidence/minty-quail-baseline-2026-11-09/raw/timed/frame_{profiled,disabled}_after_4b_{1,2,3}-summary.json.gz, accepted: false

**What the fix must hold.** The launcher's own game flags keep the day running for the whole window on any placement (`--invincible`, which stands the clock and the meter still and so changes what a frame includes, is a choice the entry states and the launcher's header names), so an unmodified launcher produces runs the analyzer accepts on the current tree; and the analyzer's reason for a rejected run names `lost_crying` or the day's end when that is the cause, instead of the four generic lines.
