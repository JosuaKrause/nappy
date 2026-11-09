# Worktrees and disk

How an agent's worktree is made and why it is sparse, the one case for the harness's own isolation,
why its branch never starts from a docs branch, and the disk check before a batch. **orchestrating** keeps the rule (a sparse worktree from
`tools/agent-setup.sh`, and a low-disk warning stops new work); read this before making a worktree
by any other route, before a checkout, import, build or capture batch, and on any disk warning.

## The worktree

**Create sparse worktrees before materializing files, with `tools/agent-setup.sh`** (busy-ibis 3).
It runs the disk preflight, `git worktree add --no-checkout --no-track` onto a new branch from
`origin/main` (so the branch inherits no upstream), enables non-cone sparse checkout and only then
materializes HEAD. The patterns are the `gates` job's sparse checkout in `.github/workflows/ci.yml`
— the one list, which keeps back what the repository's own checks read from `docs/evidence/` (the
SVGs `lint.sh` validates and the experiment scripts `pycheck.sh` runs) — followed by
`!/docs/reference/` and `!/docs/style-references/`; `--include <path>` adds a folder back for a task
that needs it (evidence, references or style references are the point of some tasks). A tools-only
task may omit runtime art/assets too. Worktrees share history, so clone depth does not avoid
repeated working files.

The orchestrator runs the tool, which creates the worktree under `.claude/worktrees/<name>` (the
path-triggered rules hook loads only for paths inside the project, so a worktree under `$TMPDIR`
gets no rules), and starts the agent in it; the brief carries the `worktree:` line and the agent's
`agent:` line the moment its id is known, as for any agent started into an existing worktree.

A review agent's scratch checkout is made sparse with `tools/agent-setup.sh --detach <ref> <name>`:
the same patterns, detached at `<ref>`, with no branch and no brief, so `agent-status.sh` never
counts it as an agent. **committing** ("Branches") says how it is removed.

**The Agent tool's own worktree isolation is not used unless a task needs the folders the sparse
checkout leaves out.** It makes a full checkout, since `.claude/settings.json` sets neither its
`worktree.sparsePaths` (which can only include whole folders) nor a `WorktreeCreate` hook. Where it
is used, two things follow. The spawn is made from the main checkout, never from a worktree that
has just been removed: the harness resolves `HEAD` in the shell's current directory before it
creates the agent's worktree, so a shell still standing in a deleted worktree fails every spawn.
And each such spawn leaves a `worktree-agent-*` branch pointing at the worktree's base, which
`tools/prune-merged.sh` deletes once its worktree is gone, keeping a live agent's.

## Branching from a docs branch

**An agent branches from `main`, never from an open docs branch.** When a milestone's entry
is still in an unmerged docs pull request, wait for it to merge before spawning rather than
telling the agent to branch from the docs branch. That pull request reaches `main` as one
squashed commit, so the agent's branch keeps the docs commits as ancestors `main` never had.
When `main` is merged back, every file those commits added meets `main`'s squashed copy: an
identical one merges silently, one amended since conflicts on a file the agent never edited, and
an item file the branch has since deleted comes back from `main`'s side without any conflict,
reopening finished work. Each is still a three-way review, and the last is found only by
looking.

## Disk

Before checkout, import, build or capture batches, check free space on the destination volume
against the estimated peak working set plus explicit headroom (`tools/lib_disk_headroom.sh` holds
the measured estimates, worktrees' included, and the tools that write a batch source it and refuse
or warn by themselves); an unknown peak or inadequate room means measure or reduce the batch before
starting.

**A low-disk warning from a tool, or a check that leaves less than the reserve, stops new work**
(quiet-yak #496). It is guidance, not a hard hook. The orchestrator starts no new agent or worktree
and an agent starts no new task, build or capture batch until the space is sorted out by
**session-cleanup**'s storage steps (the worktree inventory, job-owned scratch, then `df` again);
work already running may finish, an agent reports the warning in its report and does not leave it
in a log, and the warning is reported to the player if the space cannot be found.

Record scratch paths and cleanup ownership in the brief, and follow **session-cleanup**'s job-owned
storage rules. Release a finished agent's brief only after its processes stop and useful artifacts
are retained (`tools/agent-setup.sh --release <branch>` adds `cleanup: ready`); retirement refuses an
unreleased brief.
