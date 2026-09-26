## Pull requests are squash-merged — 2026-09-19

The player, looking at a commit view that listed every branch commit: "I'm pondering whether we
should move to squash merges?" … "commit messages shouldn't really contain information that
isn't written elsewhere as well" … on the squash message: "I prefer \"Pull request title and
description\"" … "I deactivated the other modes". Until then every milestone was merged
`--no-ff` and the merge commits were called the project's spine.

**Weighed.** For merge commits: per-item revert and bisect inside a milestone, and reasoning
kept in branch commit messages. Against: branches carry WIP commits and merges of `main`, so a
bisect inside one is rarely clean; the reasoning is in `DECISIONS.md` anyway; and GitHub's
commit view has no first-parent mode, so `main` read as noise there. The squash message
"title and commit details" was rejected because it copies that noise onto `main`; "title and
description" keeps the one text that is curated before a merge.

**What changed with it.** `git branch -d` refuses a squash-merged branch, so branch cleanup
asks GitHub for the PR's state and compares the merged head with the local tip before `-D`.
Evidence links pinned to a branch commit rest on GitHub keeping `refs/pull/<n>/head`; the
player confirmed it: "I think images will survive if you use the commit hash" … "only branch
names disappear". A check that fetched one link after each merge was drafted and dropped on
that answer.
