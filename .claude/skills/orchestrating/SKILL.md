---
name: orchestrating
description: How implementation work is delegated to sub-agents — delegating is the default, Sonnet agents in isolated worktrees, one milestone per agent, and what a task description must contain for the result to be mergeable. Injected automatically at the start of every session, because who does the work is decided before the first tool call.
---

# Orchestrating sub-agents

**Implementation of a specified milestone is delegated to a Sonnet agent in an isolated git
worktree; the orchestrating session designs, specifies, merges and maintains the queue.** The split
holds because the two jobs want different things: implementation wants fresh context and a fenced
scope; orchestration wants the whole queue, the player's words, and the authority to merge.

## Delegating is the default, and implementing by hand is the decision

**Before writing code in `src/` or `tests/`, the question is not "can I do this" but "is this
specified enough to hand over".** If it is, hand it over.

The three cases where the orchestrating session implements directly, and they are narrow:

- **The design is still moving.** An open fork, a "draft and put back" item, or anything where the
  next decision is the player's — an agent cannot hold a conversation with them.
- **The change is a sentence.** A stale line in a doc, a constant, a one-line fix. Specifying it
  costs more than doing it, and a prompt long enough to be unambiguous is longer than the diff.

  **This one drifts, and it drifts while the work is going well.** It is claimed for a change that
  turns out to touch four files, want a test, and need a decision about where a new helper lives —
  by which point the prompt would have been shorter than the diff, and the argument for doing it by
  hand was made before any of that was known. Two checks, either of which fails it: **is it more
  than one file**, and **does it need a test**. A fix that needs a test is a fix somebody has to
  verify, and verification is exactly what an agent's report is for.

  The tell is the phrase *"while I'm in here"*. The cost is not the diff — it is that the
  orchestrator's context fills with implementation detail that an agent would have held instead,
  and the next design decision is taken with less room to take it in.
- **It is the queue or the archive.** `TODO.md`, `HANDOFF.md`, `DECISIONS.md` and the playtests are
  the orchestrator's, always — see "What the orchestrator keeps".

**Everything else is an agent's**, and a milestone that is not ready for one is a milestone whose
`TODO.md` entry is not finished yet. That is the same test the feedback rules already impose:
*somebody opening the repo cold could build the thing that was asked for.* Writing the brief until
an agent can take it is not overhead on top of the work — it **is** the orchestrating half of it.

**A milestone with an open design question is not ready for one.** The question goes to the player
first, and "draft and put back" items never go to an agent at all.

**This file loads at the start of the session, before the first tool call**, because that is when
the question is live. Every later trigger is too late in one direction or the other: an `Agent`
spawn is the decision already going the right way, and a first edit to `src/` is it already going
the wrong one. It is the one rule in this project that cannot be hung on a file.

## The task description is the contract

A vague prompt returns work that cannot be merged. Every agent prompt contains, explicitly:

- **A read-first list, in order**: `CLAUDE.md`, the milestone's `TODO.md` section, the
  `DECISIONS.md` sections that carry its design, and the specific docs and source files it will
  touch. The agent starts cold; everything it needs must be named, not assumed.
- **The branch name** (`feature/<thing>`), and the committing rules restated: one commit per item,
  messages that explain why, docs move in the same commit as the code.
- **A scope fence**: the files it may touch, and the files it must not — always including
  `docs/TODO.md`, `docs/HANDOFF.md`, `docs/DECISIONS.md` and the playtests (queue maintenance and
  archiving belong to the orchestrator), plus anything another live agent owns. Two agents editing
  one file is a merge conflict scheduled in advance; when a shared file is unavoidable, tell each
  agent exactly which lines are theirs.
- **The verification gate is CI's, and nobody runs the full suite locally to satisfy it.** An agent
  runs `./tools/check.sh`, `./tools/lint.sh` if it moved a governed doc, and **the suites its own
  change touches** — `./tools/test.sh seals events`, seconds rather than minutes. Its `PARTIAL RUN`
  marker is expected rather than a failure, and the same is true of the orchestrator's own runs.

  **Why: every branch reaches `main` through a pull request**, and `main`'s ruleset requires the
  `test` check, which runs the doc lint, the boot check and the unfiltered suite **on the merge
  result**. That is a better tree than either side can test locally — two green branches can still
  be wrong together, and the merge result is the thing that catches it — so a local full run buys
  an earlier answer about a worse tree, at several minutes inside the context that can least afford
  to wait. **A red PR goes back to the agent with the failing output**, which is the same loop and
  costs one message.

  **Ask for a local full run only when the suite is the thing being changed**: the test rigs, or
  something every suite loads, where a red PR would be uninformative noise for everybody looking at
  it. **Say which of the two the agent is in, in the prompt** — an agent left to judge it will run
  the whole thing to be safe.
- **Headless first.** Verification lives in the test rigs, not in watching the game. Windowed runs
  (`tools/run.sh`, repeated `tools/shot.sh`) open on the player's own screen; at most one or two
  `shot.sh` calls at the end for evidence. A windowed run is also the least reliable thing an agent
  can lean on — the **verify** skill carries the rig traps that make one look like it worked when
  it did not.
- **Forks come back, never guessed.** If the design is ambiguous, or two recorded instructions
  conflict, the agent implements the unambiguous part and states the fork precisely in its report.
  Where the design is merely silent on a small detail, it chooses the smallest implementation
  consistent with the contracts **and says so in the commit message**, so the choice is visible
  and cheap to overturn.
- **What the final report must contain**: per item, what was built and how it was verified; every
  choice made where the design was silent; every fork left open. The report is the merge review's
  input — an outcome it does not mention is an outcome that did not happen.
- **Do not merge, do not delete the branch.** The orchestrator merges `--no-ff`, reruns the gate on
  the merged tree, removes the worktree, deletes the branch, and moves the finished entry to
  `DECISIONS.md` — with the agent's silent choices recorded as open to overturn, not narrated as
  settled.

## Running agents in parallel

**One repo takes several agents at once when each works in its own git worktree** (spawn with
worktree isolation; each gets a full checkout under `.claude/worktrees/` and its own branch, and
the path-triggered rules hook works there unchanged). What makes it safe is not the worktrees —
merging is what collides — so parallelism is planned at the file level, before spawning:

- **Partition by files, not by topic.** List what each milestone will touch and spawn together
  only sets that are disjoint. Docs count: two agents "on different features" that both rewrite
  `docs/MECHANICS.md` are one merge conflict split across two reports.
- **A shared file gets line-level ownership or a sequence.** When two concurrent milestones both
  needed `.claude/settings.json`, one agent was told "add your block, do not touch the existing
  one" and the other "change only the matcher string" — both merged clean. When that carve-up
  cannot be stated, run those milestones sequentially instead.
- **Overlapping the event catalogue, `tuning.gd` or a shared test file means sequential.** Those
  are the repo's convergence points; two agents adding rows or checks to the same file will not
  auto-merge.
- **Merge one at a time, and let CI gate each.** As each agent lands: push its branch, open a pull
  request, and merge it once the `test` check is green — GitHub runs that check on the merge result,
  which is exactly the "two green branches can still be wrong together" case. **A second agent's PR
  needs its branch brought up to date with the new `main` before it can merge**, since the ruleset
  requires strict status checks, and that re-run is the gate on the second merge. Then remove the
  worktree (`git worktree unlock` first if the harness locked it) and delete the branch.
- **Sweep the harness's own branches at the end.** Each spawn also leaves a `worktree-agent-*`
  branch pointing at the worktree's base; after the feature branches are merged, `git worktree
  prune` and delete them with `git branch -d` (never `-D` — a refusal is a branch worth looking
  at).
- **Tell each agent who else is alive** and which files those agents own, so a scope fence is a
  sentence in the prompt rather than a discovery in the diff.

## What the orchestrator keeps

- **The queue and the archive.** Agents never tick, prune or archive; two writers on `TODO.md` is
  how a queue lies.
- **The merge order** when agents run in parallel — overlapping areas run sequentially instead;
  disjoint file sets are what makes parallel safe in a single repo.
- **The player's questions.** An agent's fork, silent choice, or measurement lands back with the
  player through the orchestrator, in the entry where the next reader will look for it.
