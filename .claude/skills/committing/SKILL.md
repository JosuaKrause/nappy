---
name: committing
description: The git workflow for this repo — one branch per work item, one commit per TODO item, what a commit message must explain, and when to merge and delete. Load this BEFORE committing, branching, merging or writing a commit message.
---

# Git workflow

**Manage local branches and commits autonomously. Merging a PR requires explicit permission in
the current session** — see "Merging".

## Pushing

**Always push branch work and create or update its pull request before ending the session.**
*(2026-09-09: "always create prs don't leave branches locally only"; "or have branches on the
remote without pr without good reason".)*
Do not leave work only on a local branch or leave a remote work branch without a PR unless there
is a specific good reason, documented in the final report. Use a draft PR when the work is
unfinished, and include the PR link in the final report. This is standing authorization; no
separate request to push or open the PR is needed.

**A ready-for-review PR carries the completed work and its verification** (see "Before
committing"). An unfinished draft may be pushed with failing or outstanding checks, stated in the
PR; backing it up does not claim that it is ready to merge. Unfinished work stays out of `main`,
which is the tree a fresh clone receives.

## Merging

**Merging a PR requires explicit permission in the current session.** This includes enabling
auto-merge, manually merging, and asking an agent or monitor to merge. Permission from another
session does not carry over. Finishing implementation, opening a PR and green CI do not imply
merge permission. Leave the PR open and report its link when permission has not been given.

**A PR merges only after its review.** A review under **pr-review** has posted the verdict
*ready* on the PR against its current head, or against a head whose later pushes were reviewed
too; a merge of `main` whose result is Git's own needs no second review (**pr-review**).
*(2026-09-26: "all PRs must go through a (adversarial) review before ready to be merged.")*
Merge permission and green CI do not replace it.

When merging is explicitly authorized, check mergeability and let CI gate the merge. Resolve
conflicts under the **merging-main** skill before enabling auto-merge. **Squash-merge**
(`gh pr merge <n> --squash`) and retire the branch (see "Branches"). A dependent wait belongs to
a background agent, not a polling loop in the orchestrating session.

## The squash commit is the pull request's title and description

**Every pull request reaches `main` as one squashed commit whose message is the PR's title and
description**; the repository's squash defaults are set to exactly that. *(2026-09-19: "commit
messages shouldn't really contain information that isn't written elsewhere as well"; on the
message a squash carries: "I prefer \"Pull request title and description\"".)* So `git log` and
`git blame` on `main` show one reviewed text per work item, and a branch's own commits — the
WIP ones and the merges of `main` among them — are scratch that never lands.

**Re-read the description immediately before merging, because it is about to become permanent.**
It says what the PR carries as it now stands, the verification with its outcomes, and every
choice left open to overturn; a description written when the PR opened and not since is a
commit message about a different diff. Nothing may live only in a branch commit message: the
reasoning a later reader needs is in `DECISIONS.md`, and the description summarises it.

## A pull request is self-contained

**A pull request is a completed work item, and a broken one is fixed on its own branch, never
by a second PR.** *(2026-09-14: "we're not merging broken things -- fixes go in the same PR
*always*"; "a PR is a *completed* workitem"; "we don't merge PRs that are broken, we fix PRs, not
by creating new PRs".)* When review, a playtest or the player finds that a PR built the wrong
thing or built it wrong, the correction is committed on that PR's branch and the PR's description
is updated to say what it now carries. A follow-up PR for the fix would either merge the broken
work first or leave two PRs that only make sense together, and neither is a completed item.

**And the unit is the work item, not the milestone number.** *(2026-09-14: "why do you keep
creating new PRs for things that should go in the same PR?")* One question splits into several
numbered entries as it is worked — a probe, the thing the probe found, the fix for it — and each
number is still the same item until the player has what they asked for. The fix for what a PR's
probe found goes on that PR, whatever number the queue gave it; a new PR is for a new question.

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

**The test is the same one the docs rule uses:** if `main` at the squashed commit would hand a fresh
reader a sentence that is no longer true, the PR is not finished. Read `HANDOFF.md` and the
milestone's own `TODO.md` entry before proposing, not after.

**And every doc the change owes is in the PR before it merges. This is a hard requirement.**
*(2026-09-09: "why do you keep updating handoffs and todos *after* a PR has landed? the updates
*must* go in the PR … that's a hard requirement" — and, on the shape of it: "the requirement is not
for docs to be updated before the PR opens. it's for the docs to be updated *before* it
**merges**".)* `HANDOFF.md`, `TODO.md`, `DECISIONS.md` and every other doc the change touches are
committed on the branch by the time the merge button is pressed. Pushing them onto an open PR is
fine; filing them in the next PR, or in a cleanup afterwards, is not — once the squashed commit
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
handoff about work that is finished. Before merging, grep `HANDOFF.md` for the item's number and
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

Link the commit instead, and **embed a picture with image syntax, never as a bare URL**:

```
![what the picture shows](https://raw.githubusercontent.com/<owner>/<repo>/<full-commit-sha>/docs/evidence/x.png)
```

*(2026-09-23: "the images don't show up inline"; "while they do show up inline for the other
prs".)* GitHub renders a bare URL in a description as a link, so the player has to open every
picture to see it, which is exactly what a visual review is meant to spare them.

**A pull request that went through several visual passes opens with the current proposal**, its
pictures embedded, and lists the superseded passes last as plain links. *(2026-09-23: "it's not
clear what the current proposal is".)* A description that grows a section per pass reads as a
history, and the reviewer has to work out which picture is the one being asked about.

A branch commit's URL survives both the squash and the branch's deletion because GitHub keeps
every pull request's commits reachable under `refs/pull/<n>/head`. **The hash has to be the one
the file was committed in or a later commit on the branch**, so write the description after the
evidence commit exists — `git rev-parse HEAD` — and if the evidence is amended, update the link.
*(2026-09-19: "images will survive if you use the commit hash"; "only branch names disappear".)*

The alternative that does not depend on the repository at all is uploading the image to GitHub as an
attachment, which is what dragging a file into the PR text box does; it cannot be done from `gh`, so
it is the fallback for a description written by hand rather than the rule.

## Reviewing a pull request

**Every pull request is reviewed adversarially before it is ready to merge**, and the findings go
on the PR as comments. How is the **pr-review** skill's.

## Branches

**Before merging main into an existing PR or branch, read
[merging-main](../merging-main/SKILL.md).** It requires showing theirs, ours and base for each
conflict, reviewing semantic alignment for every merge (clean or conflicted), and renumbering
the branch's colliding identities in every numbered namespace, including milestones, TODOs and
playtests, without combining unrelated records. Side-selection shortcuts
such as `--ours` and `--theirs` do not satisfy that review.

**One branch per work item** (which may span several milestone numbers), named
`feature/<thing>`; `main` receives it as one squashed commit.

**Delete a branch as soon as its pull request is merged, always, without being asked.** The
squashed commit is what the project keeps; the branch pointer is scaffolding. Left alone they
accumulate one per work item, and the cost is not clutter — it is that `git branch` stops being
able to answer the only question it is good for: **is there work that is not on `main`?**

**Git cannot see a squash as a merge, so the PR's state is the check, not `git branch -d`.**
`-d` refuses every squash-merged branch, which makes its refusal say nothing. Ask GitHub, and
delete only on its answer:

```sh
[ "$(gh pr view <branch> --json state -q .state)" = MERGED ] \
  && [ "$(gh pr view <branch> --json headRefOid -q .headRefOid)" = "$(git rev-parse <branch>)" ] \
  && git branch -D <branch>
```

The second test is what keeps `-D` from losing work: a local branch whose tip is not the commit
the PR merged has commits nobody pushed, and that is the branch worth looking at. A harness
`worktree-agent-*` branch has no PR and points at its worktree's base, so `-d` still answers
for it.

**`tools/prune-merged.sh <branch>...` is that check, executable, and the way a merged branch is
retired.** It refuses unless the pull request is MERGED and the local tip is its merged head, then
removes the branch's worktree (never with `--force`, so git refuses a dirty one), the local branch
and the remote branch if GitHub left it, and sweeps the harness's `worktree-agent-*` branches
whose worktree is gone. Run it from the main checkout. **Use it rather than the bare commands**:
Claude Code's auto-mode classifier refuses `git worktree remove` and `git branch -D` as
destructive however the check came out, and `.claude/settings.json` allows this script by name
because it cannot delete anything the check did not clear.

**A PR stacked on another is retargeted to `main` before its base branch goes.** The repository
deletes a merged head branch on GitHub by itself; for a branch deleted by hand (`git push
--delete`, or `--delete-branch` on the merge), run `gh pr edit <upper> --base main` first, since
GitHub closes a pull request whose base branch is deleted. Either way, the upper branch still
carries the lower one's original commits after the squash, so merge `main` into it under the
**merging-main** skill before it is reviewed again; its diff against `main` is then its own work
only.

## Commits

**One commit per `TODO.md` item, inside that one branch.** A milestone is a list of things that were
decided separately and are each true or false on their own, so each one gets a commit a reviewer
can read by itself on the pull request. The commits are for the review and for the branch while it
is open: `main` receives the squash, so nothing on `main` is reverted or bisected finer than a pull
request, and an item that must be revertible alone is a pull request of its own.

**But a branch is yours, and a messy commit inside one is fine.** *(2026-09-05: "unclean commits are
fine inside a branch since main is protected".)* `main`'s ruleset means nothing lands except through
a pull request with the `test` check green on the merge result, so **the branch cannot hurt anybody**
— the thing that has to be clean is what reaches `main`, and the squashed commit is what the
project keeps. A half-finished item, a commit that does not build, a "wip" while you go and check something,
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

**And it is never the only place that sentence is written.** A branch commit message does not
reach `main`; what it says that matters later is also in `DECISIONS.md`, and in the PR
description that becomes the squashed commit.

A message that restates the diff is worth nothing; the diff is right there.

## Before committing

Run the verification loop — see the **verify** skill, which owns it: `./tools/check.sh`, the
suites your change touches, and a screenshot if you touched anything visual. The full suite is CI's
on the pull request, not a local gate.

Run `./tools/lint.sh` too if the commit touches a governed doc (`CLAUDE.md`, a skill, `README.md`
or a top-level `docs/*.md` besides `DECISIONS.md`). A hit is a stop:
fix the sentence or commit nothing. And `./tools/pycheck.sh` if it touches `tools/*.py`,
`pyproject.toml` or `uv.lock` — see the **python-tooling** skill.

## Never commit

- **`.godot/`.** It is gitignored, which means a fresh clone has no `class_name` registry and every
  typed reference fails to parse until `check.sh` runs the import pass.
- **A doc that contradicts the code it ships with.**
