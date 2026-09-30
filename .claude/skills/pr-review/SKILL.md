---
name: pr-review
description: How every pull request is reviewed before it may merge — adversarially, by a reviewer that did not write it, semantic correctness first (the player's words, recorded decisions, the queue), then code, with the findings posted on the PR and a verdict against its current head. Load this BEFORE reviewing a PR, briefing a review agent, or deciding a PR is ready to merge.
---

# Reviewing a pull request

**Every pull request goes through an adversarial review before it is ready to merge.**
*(2026-09-26: "also all PRs must go through a (adversarial) review before ready to be merged.")*
No exception for size or kind: a one-line fix, a docs PR filing a playtest, a hook, the
orchestrator's own queue moves, though a queue update's review has a shape of its own (see "A queue
update is reviewed for faithfulness and merged first"). **Ready to merge** means a review by a reviewer that did not write
the change has posted the verdict *ready* on the PR, against the PR's current head. Green CI and an
author's report of "done and verified" are inputs to the review, never a substitute for it.

**A push after the review is reviewed too.** Whatever lands on the branch after the verdict (a
fix for a finding, a merge of `main` that needed resolving) gets a review of the delta since the
reviewed head before the PR merges. The one exception is a merge of `main` whose result is Git's
own, with nothing resolved or edited by hand (`git show --remerge-diff <merge>` prints nothing):
nothing the branch says changed, and the merger's own semantic reconciliation under
**merging-main** covers what `main` brought.

**A merged PR can be reviewed after the fact** the same way. Its summary names both the head
commit and the merge commit, the verdict it would have had, and for each finding the follow-up it
needs (which file, what change), since the PR itself can no longer be fixed.

## Adversarial means the reviewer's job is to find what is wrong

The reviewer assumes the work is wrong somewhere and looks for where. It does not restate the
author's report, and it treats every claim in the PR description (a test that fails before the fix,
a count, "nothing else touches this") as unverified until it has checked it. **"I found nothing"
is a verdict only after it says what was checked.** A review that reads like the description is
not a review.

**The reviewer is not the author.** In Claude Code it is a fresh agent with no share in writing
the change. The orchestrator does not review its own queue and playtest PRs; it hands them to a
review agent like any other. In Codex, use its delegation tools with the same fence.

## Semantic correctness first

*(2026-09-26, after a post-mortem: "a PR review should not only check for code correctness but
also verify that a work item is semantically correct".)* Correct code that builds the wrong thing
passes every other check this repo has. So before reading the diff for bugs, the reviewer reads the
player's own words the PR cites (the playtest, not the queue entry's paraphrase of it; for a PR with
no playtest, the quote in its queue entry, its brief or its own description) and every decision
the change touches, and
answers these. Each "no" is a finding:

- **Is this what the player asked for?** Nothing they asked for is left out, and every case they
  described is covered and shown, not only the first. Nothing is built beyond their words unless
  it is marked: a mechanism under "Proposed, not asked for" (**playtest-feedback**), which the
  player agreed to if it changes what they see across the game, or a small choice the PR
  description names as open to overturn (**orchestrating**, "Forks come back"). An unmarked
  addition is a finding; so is a game-wide one the player never agreed to.
- **Does it keep what is already decided?** No record under `docs/decisions/` and no doc rule is
  overturned, narrowed or rewritten in passing. A doc sentence the PR changed says what the player decided, not
  what the PR happened to build.
- **Would the player recognise it in the pictures?** A visible change is judged on its pictures
  against their words, before its code. A visible change with no pictures is a finding.
- **Does the finished work leave the queue inside this PR?** *(2026-09-26: "reviews should check
  that work items are properly removed from the queue *inside* the PR that finished it".)* Every
  item the PR completes is gone from the queue in this diff, with its record written, and every
  item it only partly does is still there and says what is left. An item left queued after its work
  merges is how a finished thing gets picked up again with a different approach; an item removed
  for work the PR did not do is how an ask disappears.
- **Is every defect already found in this change fixed inside it?** Nothing merges carrying a
  defect that was already found: a finding from a playtest, a review or the player about work
  whose PR is still open is built into that PR, never queued against it (`docs/decisions/`, M90,
  the controls do what the hand does, where PLAYTEST-35's findings on the open branch went in).

## Then the code

Read the changed code in context at the PR's head, under the skills that govern the files it
touches (the path table in `CLAUDE.md`). Look for:

- a correctness bug, with a concrete input that shows it;
- a test that cannot fail, or does not test what its name says. Where the PR claims a test fails
  before the fix, check that claim, by reading or by running that one suite on the pre-fix code;
- a contract from the skills broken (fairness, telegraph, "checked before accepted", present-tense
  docs, names are content);
- a doc the change made false and left as it was;
- anything the description claims that the diff does not do.

The reviewer does not edit the branch, check it out in a worktree an agent is using, or merge. It
may run a suite from a checkout of its own, and never runs `git grep`
over a folder that holds images (see **using-tools**).

## The findings go on the PR

**A review's findings are posted as comments on the PR, anchored to the lines they are about,
never only reported in the conversation.** *(2026-09-09: "reviewing a PR should result in comments
in the PR so they can be picked up and resolved".)* A finding in a chat message is read once by
whoever asked and is gone for the person who has to fix it; a comment on the diff is a thing the
author, or an agent sent to the branch, can pick up one at a time and resolve, and its thread
records what was decided about it.

Each comment carries what a finding needs to be acted on without the reviewer present: what is
wrong, a concrete case where it fails or misleads, and what the fix is where one is clear. Post the
inline comments as **one** review with a short summary rather than one comment per finding; a
finding with no line to hang on — a missing doc, a missing test, a missing picture — goes in the
summary. **The summary ends with the verdict, *ready* or *not ready*, and the head commit it was
given against.** A review with nothing to say still says so, and what it checked.

**The review's GitHub event follows the verdict**: APPROVE when it is *ready*, REQUEST_CHANGES
when it is *not ready*, and COMMENT for an interim or partial review that gives neither verdict
yet. A review made in a cloud session is the one exception: it is always COMMENT (below).
*(2026-09-26, the player, once the four identities existed: "a reviewer app will be allowed to
approve pull requests".)* The verdict still lives in the review's own text either way — the
event is what GitHub shows beside it, not a replacement for writing it out. **The reviewer still
never merges**: merging is **committing**'s, under its permission rule, whatever the review's
event says.

**A reviewer bot's APPROVE counts toward `main`'s required approval** (**committing** says what
that requires), the same as the player's own.

**A review thread is resolved only by whoever opened it** — a reviewer bot resolves its own
threads once satisfied, a thread the player opened is the player's to resolve; the author of a fix
replies on the thread and never resolves it. *(2026-09-26, the player: "also add a note that only
whoever raised a concern can resolve it, too.")* **It is a convention, not a gate**: an unresolved
thread blocks neither an approval nor a merge, and no ruleset requires thread resolution.
*(2026-09-26: "but dont enforce that resolving all comments is required for approval. resolving is
more of a gentlement's agreement".)*

**The review posts under its author's own reviewer identity, mandatorily**: a Claude Code review
as `claude-reviewer`, a Codex review as `codex-reviewer`, on a docs-only pull request as much as on
one that changes code (the pull request's own writes are `claude-orchestrator`'s or
`claude-coder`'s by what it contains, **committing** says which) — never the player's own
account, except for a review made in a Claude Code cloud session (below). `uv run python
tools/agent-identity.py status claude-reviewer` or `... status codex-reviewer`
(**using-tools**) says whether the role is usable; the `gh` command that posts the review then
runs through `uv run python tools/agent-identity.py run claude-reviewer -- <command>` (or
`codex-reviewer`) instead of running it directly, so the comments and the review event show as
`claude-reviewer[bot]` or `codex-reviewer[bot]`. **When the role is not usable on the player's
machine (not created yet, not installed), the review stops there and is reported to the player
instead — it is never posted as the player there.** *(2026-09-26, asked what an agent does when
its identity is unusable, the player chose "Stop and tell me".)*

**In a Claude Code cloud session, where no role can work (`tools/agent-identity.py`'s module
docstring says why), the review posts under the player's own account** through the session's
GitHub tools (a pending review, its inline comments, then the submit). *(2026-09-30, asked after a
cloud review was held back: "post under my account if apps don't work here" · asked whether to
write that into the skill: "you fix it".)* Three things keep it from reading as the player's own
word:

- **Every comment and the summary end with the Claude Code attribution footer.**
- **The summary opens by saying it is posted from the player's account because the reviewer app
  cannot work in a cloud session.**
- **Its event is COMMENT, whatever the verdict.** An APPROVE from the player's account would be
  the player's own approval, which the `main approvals` ruleset (one approving review before a
  merge to `main`) accepts. A REQUEST_CHANGES would read as the player's own objection. The
  verdict is still written at the end of the summary, so it is still a verdict for this skill.
  The COMMENT event is the reviewer's proposal, open to overturn (`docs/decisions/`,
  quiet-chipmunk, a cloud session's review posts under the player's account).

A cloud *ready* therefore leaves `main approvals` unmet: the approval is the player's own, their
APPROVE or their admin bypass when they merge. **A thread a cloud review opens is Claude's**, even
though it shows under the player's name, so a later Claude review resolves it once satisfied, as
a reviewer bot resolves its own.

The fallback is for a review only; a commit, a push or a pull request keeps **committing**'s rule.

The same `PreToolUse` hook that makes committing's rule mechanical
(`.claude/hooks/github-write-guard.sh`) covers `gh pr review` too, denying it unless it is wrapped
in `run <role> --`; the session's GitHub tools are outside what it sees. **An admin action no bot
identity can perform** (a repository ruleset, a GitHub App's own permissions) **is the player's to
do directly, never something to wrap and retry.**

The conversation still gets the recap, since the player reads that first; the PR is where the
findings live.

## Briefing a review agent

The brief names the PR, its branch, the playtests and queue entry it answers, and anything the
orchestrator already knows is contested. It asks for this skill's order (semantic first, then code),
one review posted on the PR, and a report back: the verdict, each finding with its severity, and the
review's URL. Sonnet is enough for a small or mechanical PR; a PR that carries a design decision, a
drawing, or a change to the rules is reviewed by a stronger model.


## A queue update is reviewed for faithfulness and merged first

*(2026-09-27: "Task list updates should have priority and could use a weaker review agent (or no
review at all if you think that is safe)" · "Write it down how it makes sense. You might see some
gaps that I missed" · bouncy-heron, statement 4: "by faithfulness I meant having another agent
review that the wording I used (in the playtest file) and the actual scheduled work (in the todo)
matches" · statement 8, asked which model: "Sonnet now" · statement 9: "the reviewer still needs to
verify the correctness of those changes anyway. the CI is only a help".)*

**A queue update is a PR whose every changed file is under `docs/todo/`, `docs/review/` or
`docs/playtests/`**: filing a playtest, filing or rewording an entry or an item, moving a band. CI
calls it queue-only (`tools/ci_classify.py`) and runs its mechanical checks before the review
does. It is merged ahead of other work, since every brief is written from the queue on
`origin/main` (**orchestrating**) and a filing left open is a brief written from the older text. A
diff that also touches anything else, a skill or `CLAUDE.md` included, is not a queue update and
gets the full review above; the orchestrator's queue move on a PR that builds the work is reviewed
with that PR.

**Its review is Sonnet's, and it asks whether the queue says what the player said.** For each
entry or item the PR adds or rewords, the reviewer reads it beside the playtest statements it
cites, in the playtest file itself, and asks:

- **Does it claim anything the player's words do not say?**
- **Does it drop a specific the player gave?** A number, a place, a case they described, a word
  they chose.
- **Does it reinterpret an answer that could be read two ways**, rather than asking?
- **Is a mechanism or a band the player did not name marked as the filer's proposal**, under
  "Proposed, not asked for:" (**playtest-feedback**)?
- **Does it collide with a recorded decision without naming it?** `tools/decisions.sh <noun>` finds
  the records about each thing the entry changes; an entry that replaces one quotes it.

These five are the reviewer's reading of "the wording I used … and the actual scheduled work …
matches", proposed at filing (leafy-finch) and open to the player's correction. A "yes" to the
first, second, third or fifth, and a "no" to the fourth, is a finding. **A reviewer flags; it does not resolve**:
it says what does not match and where, and the filer takes it back to the player or to the words.

**It also verifies what CI checked, since a script sees that a thing exists, not what it says.**
The `gates` job's queue update step (`tools/ci_queue_update.py`) fails on an existing playtest
changed, on a deleted queue file with neither a record on `main` for its entry nor a `Dropped:
<path> — "<the player's words>"` line in the description quoting a playtest verbatim, and on a
deleted review item no playtest names; it puts `tools/queue.sh`'s line for every entry touched in
the job's summary. The reviewer checks that the step ran (CI called the PR queue-only), and then
what it could not:

- **A record that exists covers the item deleted**: it says the item's work was built, not only
  that the entry has a record.
- **A drop's quote says what the drop claims**: the player's words let the item go, rather than
  only mentioning it.
- **A review item's playtest answers it**, rather than only naming it.
- **Each entry sits in the band the description says**, from the job summary's lines.

**It is still a review.** Merging needs one approving review (**committing**), and a bot's approval
is the only one the orchestrator can get without the player. A push after the approval gets the
same review of its delta. Going first changes the order, not the permission: merging still needs
the player's go-ahead in the current session.
