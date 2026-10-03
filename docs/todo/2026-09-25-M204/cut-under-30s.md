**The cut, under 30s**: the choice in action; early dangers up to the charging dog; the
title; three 1s segments through black — army trucks beside the mother, the father walking
to a gatehouse, the mother running with the baby in her arms from pursuing guards; the
zoom out. Nothing a player never sees. The player renders the final video.

Review the final ordering, per-shot parent choices, captions, title and fades with the
player. PLAYTEST-139 describes parent choices as "chosen at random but fixed" and
assigns mother/father/mother to the three later-day glimpses. The existing drafted
caption words remain available for that review: "Every walk is a choice.",
"Not every street is safe.", and "One family. A whole city." The title is "Nappy".
Neither their removal nor replacement is an accepted editorial decision.

`tools/trailer/shots.json` uses the requested bird-flock and dog scene recipes.
**Proposed, not asked for:** its draft shot lengths and omitted recipe caption overlays
remain editorial choices to reconcile with the player before the finished render.
Still capture for scene composition does not decide caption timing or the final cut.

Verify the actual trucks and the visibly running, carrying mother in the final movie.
The sources are saved recipes, so the acceptance test is the requested on-screen
action, not reproducing the earlier seed-based setup. The original failed render and
its measured behavior are recorded in
[M204 and M214, trailer tools](../../decisions/2026-09-26-M204-and-M214-the-trailer-and-its-recording-tools.md).

Establish loaded-render reproducibility with `tools/trailer.sh --check all` using the
current recipe sources, including camera motion and their chosen cut-in times.
Statement 1 asks for "the same output every time". Compare busy and quiet runs and
retain relevant failures as well as passing comparisons; stills and headless action
checks do not establish pixel reproducibility under load.

Investigate the standalone screenshot path combining `--start-escape` with `--walk`
or `--after`. Recipe capture advances and freezes on its own simulation clock, so a
working recipe still does not close that separate standalone-path report.
