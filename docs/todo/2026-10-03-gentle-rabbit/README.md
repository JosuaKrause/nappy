priority: parked

# gentle-rabbit — Shrink the repository's history once no PR is open · filed 2026-10-03

> "10% is nice but we need to choose a good point for this since it will require a force push and
> there are too many PRs for that open right now; let's table it"

[busy-ibis](../../playtests/2026-10-03-busy-ibis.md), statements 4 and 5; busy-wombat's "we might do
a git filter later on but not yet". Parked until the player picks a moment with few open PRs and
no agent at work, since every way of shrinking the history rewrites it and needs a force push.

**What was measured on 2026-10-03** (the git history, `.git`, is about 1.1 GB, shared once by every
local worktree; GitHub reported the repository at about 1 GB):

- About 1.03 GB of the history is `docs/evidence/` still on `main`, almost all PNG; `git gc` cannot
  touch it, since it is reachable, and PNGs do not compress further.
- About 110 MiB is files no longer on `main` (about 73 MiB deleted before, about 37 MiB by #461).
  A `git filter-repo` dropping only those saves that much — the 10% the player named.
- Moving `docs/evidence/` out of the history — to Git LFS (`git lfs migrate import --everything`),
  or to a repository of its own — shrinks `.git` to tens of MiB.

**What any rewrite costs:** every commit hash changes; the records that cite hashes, the `v0.x`
tags, Codex's clone and every open PR's branch are redone or re-cloned; commit-pinned image links in
PR descriptions keep working only because GitHub keeps the old commits under `refs/pull/*`, which
is also why GitHub's reported size does not shrink until GitHub's support runs a cleanup.

**Git LFS:** the player believes there is no LFS quota and that it is not free (statement 5).
GitHub's billing documentation gives a Free account 10 GiB of LFS storage and 10 GiB of bandwidth a
month; the evidence fits the storage, but each clone that pulls it costs about 1 GiB of bandwidth,
and with no payment method on file LFS is disabled for the rest of the month once bandwidth runs
out. LFS would need `git lfs install` on each machine, a `.gitattributes` rule, the migration and
force push, `lfs: true` only on the CI jobs that need evidence, and a re-clone of Codex's checkout.

**What is already done instead:** sparse worktrees (the **orchestrating** skill) keep the evidence
out of every worktree whose task does not need it, which is where the disk went; that needs no
rewrite.
