---
name: committing
description: The git workflow for this repo — one branch per milestone, one commit per TODO item, what a commit message must explain, and when to merge and delete. Load this BEFORE committing, branching, merging or writing a commit message.
---

# Git workflow

**The local repository is this side's to manage — branch, commit and merge without asking each
time.**

## Pushing

**Completed work may be pushed to `origin` without asking each time.** *Finished* is the whole of
the permission: a milestone merged to `main` with its gate green, or a branch whose items are done
and archived. It is not a licence to push a branch mid-item to see what happens.

Everything else about the local repository is unchanged — branch and commit freely — and the gate
before a push is the same one as before a commit: `./tools/check.sh`, the suites your change
touches, and `./tools/lint.sh` if a governed doc moved. **The full suite runs in CI on the pull
request**, on the merge result, which is the tree that actually matters.

**A half-built milestone's branch may be pushed as a branch**, which is backup rather than a claim.
What may not happen is `main` carrying an unfinished milestone: `main` is the thing a fresh clone
gets, and this project's own handoff tells that reader to trust the tools over any sentence.

## A pull request is self-contained

**A pull request carries every document its own changes make false.** Not a follow-up, not a
cleanup pass afterwards, not a note for the next session: the doc edit is part of the change and
lands in the same PR. That covers `docs/TODO.md` and `docs/HANDOFF.md` — the two that go stale
fastest, because one holds the queue the PR just shortened and the other describes the tree the PR
just moved — and it covers every other governed doc the change touches: `CITY`, `EVENTS`,
`MECHANICS`, `TELEMETRY`, `ARCHITECTURE`, `NARRATIVE`, `README`, `CLAUDE.md`, the skills, and the
docstrings on anything edited. **A PR that finishes a milestone also files that milestone's history
in `docs/DECISIONS.md` and removes its section from `TODO.md`**, because `TODO.md` holds open work
only and the entry stops being open the moment the PR merges.

**Why:** a PR is reviewed once, against a tree where the reason for each doc edit is visible in the
same diff. Deferred, the reason is gone and only somebody who already knows what changed can tell
which sentence went stale — which is nobody, a week later. Several PRs merged in a row each leaving
their own doc debt is how three files come to carry three different answers to one question, and
the pass that untangles it is a milestone rather than a review comment.

**The test is the same one the docs rule uses:** if `main` at the merge commit would hand a fresh
reader a sentence that is no longer true, the PR is not finished. Read `HANDOFF.md` and the
milestone's own `TODO.md` entry before proposing, not after.

The **session-cleanup** skill still runs at the end of a session — it catches drift that no single
change is responsible for, reassesses long-open items and re-reads the numbers. It is not where a
PR's own doc work goes.

## Branches

**One branch per milestone**, named `feature/<thing>`, merged to `main` with `--no-ff`. The merge
commits are the project's spine; keep them.

**Delete a branch as soon as it is fully merged, always, without being asked.** The merge commit is
what the project keeps; the branch pointer is scaffolding. Left alone they accumulate one per
milestone, and the cost is not clutter — it is that `git branch` stops being able to answer the only
question it is good for: **is there work that is not on `main`?**

```sh
git branch --merged main | grep -v '^\*' | grep -vw main | xargs git branch -d
```

`-d` and **never** `-D`: `-d` refuses anything not merged, so the command cannot lose work, and a
branch it refuses is exactly the one worth looking at. (On macOS `xargs` has no `-a` — feed it by
pipe or `< file`.)

## Commits

**One commit per `TODO.md` item, inside that one branch.** A milestone is a list of things that were
decided separately and are each true or false on their own, so each one gets a commit that can be
read, reverted or bisected by itself. A single commit at the end of a milestone throws that away and
makes the branch's own history unusable.

**But a branch is yours, and a messy commit inside one is fine.** *(2026-09-05: "unclean commits are
fine inside a branch since main is protected".)* `main`'s ruleset means nothing lands except through
a pull request with the `test` check green on the merge result, so **the branch cannot hurt anybody**
— the thing that has to be clean is what reaches `main`, and the merge commit is what the project
keeps. A half-finished item, a commit that does not build, a "wip" while you go and check something,
several small commits where the rule above wants one: all fine, none of it needs asking about.

So read the one-per-item rule as **what the branch should look like by the time it is proposed**,
not as a gate on each `git commit`. Tidy at the end if it is worth tidying; an interactive rebase is
not available in this environment, so in practice that means writing the good message on the commit
that finishes an item rather than reshaping history afterwards.

**Commit before stopping, and prefer a scruffy commit to a dirty tree.** Uncommitted work is the only
state that can actually be lost. An unfinished milestone is a branch with commits on it — say in the
message that an item is incomplete and where you stopped, and move on.

**And that includes a session that only writes docs.** A long design conversation produces the most
valuable and least recoverable thing in this repo — a brief in the player's own words, and the
reasoning around it — and it is exactly the work that feels too unfinished to commit, because the
design is still moving. **Commit each piece as it is settled.** A decision that is only in the
working tree is a decision that is only in the session.

**Commit the docs in the same commit as the code.** `docs/` is not a report written afterwards, it
is the design. If an implementation contradicts a doc, **the doc is wrong and gets fixed in that
commit.**

## Commit messages

**Explain why, and say what was tried and rejected.** When something was discovered
mid-implementation — "the first version parked every route against the city wall" — say so. That is
the part that is **not recoverable from the diff**, which is the whole test for whether a sentence
belongs in a commit message.

A message that restates the diff is worth nothing; the diff is right there.

## Before committing

Run the verification loop — see the **verify** skill. `./tools/check.sh`, the suites your change
touches, and a screenshot if you touched anything visual.

**Nobody runs the unfiltered suite locally as a gate.** It runs in CI on the pull request, against
the merge result, and `main`'s ruleset will not let anything land without it — so a local full run
buys an answer several minutes before the PR gives a better one. A `PARTIAL RUN` marker is the
expected state of a local run. The reasoning is in **verify**, which also names the two cases where
running it locally is still the fast thing to do.

Run `./tools/lint.sh` too if the commit touches a governed doc (`CLAUDE.md`, a skill, `README.md`
or anything under `docs/` besides `DECISIONS.md` and the `PLAYTEST-NN.md` files). A hit is a stop:
fix the sentence or commit nothing.

## Never commit

- **`.godot/`.** It is gitignored, which means a fresh clone has no `class_name` registry and every
  typed reference fails to parse until `check.sh` runs the import pass.
- **A doc that contradicts the code it ships with.**
