# velvet-trout — Landing is auto-merge and one timer, not a wait · 2026-11-04 · not from an entry

The player did not want a polling monitor kept running just to trigger a merge, preferred
auto-merge, and said a timer is enough to check back that it went through (inbox #1068 in
gentle-walrus).

**What it was.** `tools/land-prs.sh` turned on auto-merge (or merged a clean PR), then polled each
pull request every 30 seconds, up to 90 minutes, until it merged, one PR at a time, then pulled
main and pruned the branch. A background process was held open for the whole of that wait.

**What it is now.** The script runs its pre-merge checks (a closed PR, a conflict, a red check, an
edit to the old single-file queue), turns on auto-merge or merges a PR GitHub already calls clean,
prints per PR what it did and the check that confirms it, and exits. It has no wait loop, no
`--timeout`, no polling interval, and neither pulls main nor prunes. The caller sets one one-shot
timer; at it the PR shows MERGED and is pruned with `tools/prune-merged.sh`, or a red check or a
conflict is fixed (**committing**).

Auto-merge is safe against a push after the approval because the ruleset `main approvals` dismisses
stale approvals when new commits are pushed, which the player set on 2026-11-04 (inbox #1068 in
gentle-walrus).

**Open to overturn:** the timer is one shot of about 25 minutes, roughly one CI run; the number is
the filer's proposal, not the player's.
