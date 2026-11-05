# velvet-trout — Landing is auto-merge and a background wait script · 2026-11-04 · not from an entry

The player did not want a polling monitor kept running just to trigger a merge, preferred
auto-merge, and said a timer is enough to check back that it went through (inbox #1068 in
gentle-walrus). After the first timer proved overly safe, the player asked to estimate better,
undershoot a little and poll the rest with a script, not an agent (inbox #1070 in gentle-walrus).

**What it was.** `tools/land-prs.sh` turned on auto-merge (or merged a clean PR), then polled each
pull request every 30 seconds, up to 90 minutes, until it merged, one PR at a time, then pulled
main and pruned the branch. A background process was held open for the whole of that wait.

**What it is now.** The script runs its pre-merge checks (a closed PR, a conflict, a red check, an
edit to the old single-file queue), turns on auto-merge or merges a PR GitHub already calls clean,
prints per PR what it did and the check that confirms it, and exits. It has no wait loop, no
`--timeout`, no polling interval, and neither pulls main nor prunes. The caller runs
`tools/await-merge.sh <the PRs>` in the background (the Bash tool's `run_in_background`, which
re-invokes the session on exit): it estimates when CI ends, sleeps until then, and polls every 20
seconds until each PR shows MERGED, and the PR is pruned with `tools/prune-merged.sh`; or it names
a red check, a conflict, a closed PR or the cap, and that is fixed (**committing**). This overturns
the "no polling" of inbox #1068 in gentle-walrus for the confirming tail only, as inbox #1070 in
gentle-walrus asks: nothing is held open to trigger
the merge, and a script, not an agent, polls the rest.

Auto-merge is safe against a push after the approval because the ruleset `main approvals` dismisses
stale approvals when new commits are pushed, which the player set on 2026-11-04 (inbox #1068 in
gentle-walrus).

**Open to overturn:** the numbers are the filer's proposal, not the player's: the estimate is the
shortest of the last three green runs on main per job, the latest unfinished job's end minus one
minute, then 20 seconds between polls and a cap of 30 minutes past the estimate. The player set the
rule itself, a script in the background in place of a fixed timer, in inbox #1070 in gentle-walrus.
