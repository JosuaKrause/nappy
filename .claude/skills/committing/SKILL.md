---
name: committing
description: The git workflow for this repo — one branch per milestone, one commit per TODO item, what a commit message must explain, and when to merge and delete. Load this BEFORE committing, branching, merging or writing a commit message.
---

# Git workflow

**The local repository is this side's to manage — branch, commit and merge without asking each
time.**

## Pushing

**Always push branch work and create or update its pull request before ending the session.**
*(2026-09-09: "always create prs don't leave branches locally only"; "or have branches on the
remote without pr without good reason".)*
Do not leave work only on a local branch or leave a remote work branch without a PR unless there
is a specific good reason, documented in the final report. Use a draft PR when the work is
unfinished, and include the PR link in the final report. This is standing authorization; no
separate request to push or open the PR is needed.

**A PR that is ready to merge is armed with auto-merge, never watched.** *(2026-09-11: "don't
poll CI checks. arm PRs with auto merge".)* `gh pr merge <n> --auto --merge --delete-branch` hands
the wait to GitHub: the PR merges with a merge commit the moment its `test` check is green, and the
branch goes with it. Polling the check from a session spends the session's own time on a wait the
platform already does for free, and a session that stops before the check finishes has left the PR
unmerged for no reason. Arm it as the last step of proposing, and arm the next PR in a stack the
same way — a PR whose base was a branch has to be retargeted to `main` (or re-opened against it,
since GitHub closes a PR whose base branch is deleted) before it can be armed.

**Where something has to happen after the merge — a stacked PR retargeted, a worktree removed,
`main` pulled into the player's checkout — a background agent does the watching, never the
orchestrating session.** *(2026-09-11: "you can use an agent to poll a ci/merge to retarget prs
etc. but don't block the main agent for it".)* Give it the PR number, the exact tidy steps and a
90-second poll, and carry on; its report is the signal to act on.

**A ready-for-review PR carries the completed work and its verification.** Run `./tools/check.sh`,
the suites the change touches, and `./tools/lint.sh` if a governed doc moved. An unfinished draft
may be pushed with failing or outstanding checks, stated in the PR; backing it up does not claim
that it is ready to merge. **The full suite runs in CI on the pull request**, on the merge result.
Unfinished work stays out of `main`, which is the tree a fresh clone receives.

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

**And every doc the change owes is in the PR before it merges. This is a hard requirement.**
*(2026-09-09: "why do you keep updating handoffs and todos *after* a PR has landed? the updates
*must* go in the PR … that's a hard requirement" — and, on the shape of it: "the requirement is not
for docs to be updated before the PR opens. it's for the docs to be updated *before* it
**merges**".)* `HANDOFF.md`, `TODO.md`, `DECISIONS.md` and every other doc the change touches are
committed on the branch by the time the merge button is pressed. Pushing them onto an open PR is
fine; filing them in the next PR, or in a cleanup afterwards, is not — once the merge commit
exists, `main` has handed every reader a false sentence until something else lands. Before merging,
re-read the branch's own diff against the list above and ask what it left stale. The end-of-session
cleanup pass is for drift no single PR caused, not for finishing a PR's own doc work.

**A work item never merges while its `TODO.md` item is unresolved.** *(2026-09-09: "a workitem may
never merge if it's corresponding TODO item hasn't been resolved".)* Resolved means the entry is
gone from `TODO.md` and its record — what was built, the measurement, the rejected options — is
filed in `DECISIONS.md`, both on the branch. A PR whose own item still sits open in the queue is
not finished, however green its checks are; if the item is only partly built, the PR either
finishes it or its entry is rewritten on the branch to hold exactly what is still open, with the
built half filed in `DECISIONS.md`.

**And no handoff mentions it any more, since the work is done.** *(2026-09-09: "and there may be no
mention of it in any handoff still … since the work is done".)* `HANDOFF.md` holds the pick-up
state and nothing else, so a merged item has no line there — not a "built and unwalked" bullet, not
a distrust entry written for it, not its number. What a player should go and look at is a
`TODO.md` item, a `DECISIONS.md` record, or an entry in `docs/REVIEW.md`, never a sentence in the
handoff about work that is finished. Before merging, grep both handoffs for the item's number and
its nouns.

**And work that only a person can judge adds its entry to `docs/REVIEW.md` in the same PR.**
*(2026-09-11: "keep a document with items that need human review / test runs. That way you can
keep working without having to stop. And test runs can capture multiple items at once.")* The
entry says what to do, where to look, and the question a run answers; the record of what was
built stays in `DECISIONS.md`. It is the list a playtest is asked against, so an item missing
from it is an item no run will ever be asked to look at.

The **session-cleanup** skill still runs at the end of a session — it catches drift that no single
change is responsible for, reassesses long-open items and re-reads the numbers. It is not where a
PR's own doc work goes.

## A PR description never links a file by branch name

**An image or file in a PR description is linked by commit hash, never by branch.** *(2026-09-09:
"using branch names in pr descriptions will lead to stale links (eg for images etc)".)* A URL of
the shape `.../blob/feature/<thing>/docs/evidence/x.png?raw=true` or
`raw.githubusercontent.com/<owner>/<repo>/feature/<thing>/...` works while the branch exists and
returns a 404 the moment the branch is deleted — and this workflow deletes every branch as soon as
it is merged, so every such link in every merged PR is dead. The description is the one place the
before-and-after pictures live once the PR is closed, so a dead link there is the evidence gone.

Link the commit instead:

```
https://raw.githubusercontent.com/<owner>/<repo>/<full-commit-sha>/docs/evidence/x.png
```

A commit's URL survives the branch because `main` is merged `--no-ff`, so every commit on the branch
stays reachable from the merge commit. **The hash has to be the one the file was committed in or a
later commit on the branch**, so write the description after the evidence commit exists — `git
rev-parse HEAD` — and if the evidence is amended, update the link. A squash or rebase merge would
break this, and is one more reason this repository does neither.

The alternative that does not depend on the repository at all is uploading the image to GitHub as an
attachment, which is what dragging a file into the PR text box does; it cannot be done from `gh`, so
it is the fallback for a description written by hand rather than the rule.

## Reviewing a pull request leaves its findings on the pull request

**A review's findings are posted as comments on the PR, anchored to the lines they are about,
never only reported in the conversation.** *(2026-09-09: "reviewing a PR should result in comments
in the PR so they can be picked up and resolved".)* A finding in a chat message is read once by
whoever asked and is gone for the person who has to fix it; a comment on the diff is a thing the
author, or an agent sent to the branch, can pick up one at a time and resolve, and its thread
records what was decided about it.

Each comment carries what a finding needs to be acted on without the reviewer present: what is
wrong, a concrete case where it fails or misleads, and what the fix is where one is clear. Post the
inline comments as one review with a short summary rather than as one comment per finding, so the
author gets them together; a finding that has no line to hang on — a missing doc, a missing test
row — goes in the summary. **A review with nothing to say still says so** on the PR, so that
"no comments" is a verdict rather than an absence.

The conversation still gets the recap, since the player reads that first; the PR is where the
findings live.

## Branches

**Before merging main into an existing PR or branch, read
[merging-main](../merging-main/SKILL.md).** It requires showing theirs, ours and base for each
conflict, reviewing semantic alignment for every merge (clean or conflicted), and renumbering
the branch's colliding identities in every numbered namespace, including milestones, TODOs and
playtests, without combining unrelated records. Side-selection shortcuts
such as `--ours` and `--theirs` do not satisfy that review.

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
fix the sentence or commit nothing. And `./tools/pycheck.sh` if it touches `tools/*.py`,
`pyproject.toml` or `uv.lock` — see the **python-tooling** skill.

## Never commit

- **`.godot/`.** It is gitignored, which means a fresh clone has no `class_name` registry and every
  typed reference fails to parse until `check.sh` runs the import pass.
- **A doc that contradicts the code it ships with.**
