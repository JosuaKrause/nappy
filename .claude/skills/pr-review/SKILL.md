---
name: pr-review
description: How every pull request is reviewed before it may merge — adversarially, by a reviewer that did not write it, semantic correctness first (the player's words, recorded decisions, the queue), then code, with the findings posted on the PR and a verdict against its current head. Load this BEFORE reviewing a PR, briefing a review agent, or deciding a PR is ready to merge.
---

# Reviewing a pull request

- **Every pull request is reviewed adversarially before it merges**, by a reviewer that did not write it; no exception for size or kind.
- **Ready means a *ready* verdict posted on the PR against its current head**; a later push gets a review of its delta.
- **Semantic correctness first**: the player's own words and the recorded decisions, then the code.
- **The findings go on the PR as one review**, anchored to their lines, ending with the verdict and the head commit.
- **The review posts as the reviewer identity, which alone approves, and never as the player.**
- **The reviewer never edits the branch and never merges.**
- **A review thread is resolved only by whoever opened it.**
- **Three *not ready* verdicts on one pull request mean the approach is rethought.**
- **A queue update is reviewed for faithfulness to the player's words, and merged first.**

**Every pull request goes through an adversarial review before it is ready to merge**
(how-the-spent-park-was-rebuilt-against-the-players-words-and-the-review-rules-it). No exception for
size or kind: a one-line fix, a docs PR filing a playtest, a hook, the orchestrator's own queue
moves, though a queue update's review has a shape of its own (see "A queue update is reviewed for
faithfulness and merged first"). **Ready to merge** means a review by a reviewer that did not write
the change has posted the verdict *ready* on the PR, against the PR's current head. Green CI and an
author's report of "done and verified" are inputs to the review, never a substitute for it.

**A push after the review is reviewed too.** Whatever lands on the branch after the verdict (a
fix for a finding, a merge of `main` that needed resolving) gets a review of the delta since the
reviewed head before the PR merges. The one exception is a merge of `main` whose result is Git's
own, with nothing resolved or edited by hand (`git show --remerge-diff <merge>` prints nothing):
nothing the branch says changed, and the merger's own semantic reconciliation under
**merging-main** covers what `main` brought. The ruleset may still dismiss the approval on such a
merge; the PR then needs a re-approval against the new head, not a review of new content
(**committing** says what the ruleset dismisses).

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

A review checks that a work item is semantically correct
(how-the-spent-park-was-rebuilt-against-the-players-words-and-the-review-rules-it), not only that
its code is. Correct code that builds the wrong thing passes every other check this repo has. So
before reading the diff for bugs, the reviewer reads the player's own words the PR cites (the
playtest, not the queue entry's paraphrase of it; for a PR with no playtest, the quote in its queue
entry, its brief or its own description) and every decision the change touches, and answers these.
Each "no" is a finding:

- **Is this what the player asked for?** Nothing they asked for is left out, and every case they
  described is covered and shown, not only the first. Nothing is built beyond their words unless
  it is marked: a mechanism under "Proposed, not asked for" (**playtest-feedback**), which the
  player agreed to if it changes what they see across the game, or a small choice the PR
  description names as open to overturn (the agent contract, "Forks come back, never guessed",
  `../orchestrating/references/agent-contract.md`). An unmarked
  addition is a finding; so is a game-wide one the player never agreed to.
- **Does it keep what is already decided?** No record under `docs/decisions/` and no doc rule is
  overturned, narrowed or rewritten in passing. A doc sentence the PR changed says what the player decided, not
  what the PR happened to build.
- **Does every citation it adds or changes say what the player said?** For each citation of the
  player's words a PR adds or changes in `CLAUDE.md` or a skill, the reviewer opens the cited
  statement and checks that it resolves to one file and one statement, and that the rule says what
  those words say. This review is where a rule's reading of the player is established, once, so no
  later reader re-checks it (woolly-penguin #759).
- **Would the player recognise it in the pictures?** A visible change is judged on its pictures
  against their words, before its code. A visible change with no pictures is a finding.
- **Does the finished work leave the queue inside this PR?**
  (how-the-spent-park-was-rebuilt-against-the-players-words-and-the-review-rules-it) Every item the
  PR completes is gone from the queue in this diff, with its record written, and every item it only
  partly does is still there and says what is left. An item left queued after its work merges is how
  a finished thing gets picked up again with a different approach; an item removed for work the PR
  did not do is how an ask disappears.
- **Is every defect already found in this change fixed inside it?** Nothing merges carrying a
  defect that was already found: a finding from a playtest, a review or the player about work
  whose PR is still open is built into that PR, never queued against it (`tools/decisions.sh M90`,
  the controls do what the hand does, the record of PLAYTEST-35's findings built into the open
  branch).

## Then the code

Read the changed code in context at the PR's head, under the skills that govern the files it
touches (the path table in `CLAUDE.md`). Look for:

- a correctness bug, with a concrete input that shows it;
- a test that does not test what its name says, builds a real object it does not test
  (inbox #1159 in gray-dolphin), or holds nothing in one of the four ways
  **writing-tests** names (an unreachable setup, a design decision read back, a check that
  cannot fail, a duplicate; inbox #1097 in curly-rabbit). `tools/check_test_only_members.py`, CI's
  check that fails a test reading a public member nothing else under `src/` reads (its `--help`
  says what it counts), covers part of the first and the own-file rule of
  inbox #1098 in curly-rabbit. Whether a kept line's reason holds is the reviewer's to read, and so
  is the rest. **A diff that touches the list `tools/test_only_members.txt`, the checker or the
  checker's own exemptions is reviewed as `references/test-only-members.md` says**: it holds what
  CI leaves to the reviewer there, and the procedure for a diff that changes the checker, which CI
  exempts from its rule that the list only shrinks. Where the PR claims a
  test fails before the fix, check that claim, by reading or by running that one suite on the
  pre-fix code;
- a contract from the skills broken (fairness, telegraph, "checked before accepted", present-tense
  docs, names are content);
- a design that breaks **designing-classes**: a dependency pointing up a layer, a mode copied
  instead of configured, or a component fetching what it should be handed (the
  player's), or one fact derived in more than one place (inbox #1156 in gray-dolphin); and, from that skill's
  proposal (plush-kestrel), a fix keyed on one row's id or
  picture instead of landing in the shared mechanism, raised as a proposal-backed finding, not as
  the player's rule;
- an answer to the architecture questions (`references/architecture-questions.md`, under the
  description's `## Architecture questions`) that does not match the change: the reviewer checks
  each answer against the diff and `tools/check_layers.py --list` on the head, and an answer either
  contradicts, or that leaves out a piece or a dependency the diff adds, is a finding (plush-egret
  #892). So is a break added to `tools/layer_map.py`'s list, or a file moved to another layer
  there, that no answer justifies. CI sees only that the answers are there and that the code keeps
  to the map as it stands;
- a doc the change made false and left as it was;
- anything the description claims that the diff does not do.

The reviewer does not edit the branch, check it out in a worktree an agent is using, or merge. It
may run a suite from a checkout of its own, sparse unless the PR's evidence or references are what
it is checking (`../orchestrating/references/worktrees-and-disk.md`, "The worktree", says what a
sparse worktree leaves out; `tools/agent-setup.sh --detach <ref> <name>` makes it, detached at the
PR head, with no branch and no brief), and never runs `git grep` over a folder that holds images
(see **using-tools**). **A review checkout is removed once the review is posted, with
`tools/agent-setup.sh --remove <name>`**: a plain `git worktree remove`, never forced, of the
detached checkout of that name under `.claude/worktrees/`, which refuses one that has a branch, is
locked, or holds a changed, untracked or non-regenerable ignored file (its `--help` has the whole
list). The checkout has no branch, so `tools/prune-merged.sh`, the script that retires a merged
branch and its worktree, never takes it.

## The findings go on the PR

**A review's findings are posted as comments on the PR, anchored to the lines they are about, never
only reported in the conversation** (woolly-finch 11). A finding in a chat message is read once by
whoever asked and is gone for the person who has to fix it; a comment on the diff is a thing the
author, or an agent sent to the branch, can pick up one at a time and resolve, and its thread
records what was decided about it.

Each comment carries what a finding needs to be acted on without the reviewer present: what is
wrong, a concrete case where it fails or misleads, and what the fix is where one is clear. Post the
inline comments as **one** review with a short summary rather than one comment per finding; a
finding with no line to hang on — a missing doc, a missing test, a missing picture — goes in the
summary. **The summary ends with the verdict, *ready* or *not ready*, and the head commit it was
given against.** A review with nothing to say still says so, and what it checked.

**The review's GitHub event follows the verdict**: APPROVE (tall-egret) when it is *ready*,
REQUEST_CHANGES when it is *not ready*, and COMMENT for an interim or partial review that gives
neither verdict yet. The verdict still lives in the review's own text either way — the event is what
GitHub shows beside it, not a replacement for writing it out. **The reviewer still never merges**:
merging is **committing**'s, under its permission rule, whatever the review's event says.
The repository states a standing permission to merge only; starting reviewers and posting their verdict reviews
is covered by a line in the player's `~/.claude/settings.json`. A refused spawn or post is reported to the player as **committing**
("Merging") says, never worked around.

**A reviewer bot's APPROVE counts toward `main`'s required approval** (**committing** says what
that requires), the same as the player's own.

**A review thread is resolved only by whoever opened it** — a reviewer bot resolves its own threads
once satisfied, a thread the player opened is the player's to resolve; the author of a fix replies
on the thread and never resolves it (woolly-finch 32). **It is a convention, not a gate**: an
unresolved thread blocks neither an approval nor a merge, and no ruleset requires thread resolution
(woolly-finch 33).

**Which GitHub identity writes what is committing's** ("Who a commit and a pull request are
from"), with how a write is wrapped and what the write guard denies. What is this skill's own: **a
review posts as its author's reviewer identity, mandatorily, and that identity alone approves**
(busy-ibis 9): `claude-reviewer` in Claude Code and `codex-reviewer` in Codex, on a docs-only pull
request as much as on one that changes code. **When the role is not usable, the review stops there
and is reported to the player instead — it is never posted as the player** (tall-egret): its
findings are never sent as a `gh pr comment` or any other write the guard's prompt would let
through as the player. **A review's text is written to a file first and passed to the API with
capital `-F`** (`-F body=@file`; **committing**, "Text handed to a write goes through a file",
spells the calls that make the file): lowercase `-f` (`--raw-field`) sends the literal text `@file`
as the body, and the review then has to be edited.

The conversation still gets the recap, since the player reads that first; the PR is where the
findings live.

## Three verdicts of *not ready* mean the approach is rethought

When a pull request's reviews have come back *not ready* three times (woolly-penguin #759), the
approach is rethought, including whether the chosen solution is the right way at all. The count is
per pull request.

**Who writes it is decided case by case** (inbox #842 in minty-dolphin). The orchestrating session asks the
builder for the rethink when it judges the builder has the context and the capability for it, and
otherwise writes it itself or starts a fresh planning agent for it; a builder on a small model
(Haiku) is the player's example of one that may not.

How the rethink runs:

- **What counts:** every *not ready* verdict, full reviews and reviews of a delta alike, a queue
  update included. The count starts again after a rethink is written down.
- **What else the rethink asks:** whether the brief asked for the right thing, whether the design or
  the reading of the player's words is wrong, and whether the work should be split, restarted or put
  to the player. It decides *how* the open findings get fixed, never whether: the pull request still
  does not merge with a found defect open ("Is every defect already found in this change fixed
  inside it?", above).
- **With no orchestrator** (a Codex session working alone), the session that owns the pull request
  writes the rethink.
- **A builder's rethink is checked:** the orchestrating session checks it against the player's
  words and the queue before it stands.
- **Where:** the rethink and what it decided go in the pull request's conversation before any
  further commit; a change of approach that touches what the player asked for goes to the player as
  a question first.

## Briefing a review agent

The brief names the PR, its branch, the playtests and queue entry it answers, and anything the
orchestrator already knows is contested. It asks for this skill's order (semantic first, then code),
one review posted on the PR, and a report back: the verdict, each finding with its severity, and the
review's URL. **Which model reviews is decided by the orchestrating skill's model table**, whose
rows for a review go by what the pull request carries, apart from the one case this skill fixes
itself: a queue update's review is Sonnet's (bouncy-heron 8; "A queue update is reviewed for
faithfulness and merged first"). The one other model this skill names, Haiku under "Three verdicts
of *not ready* mean the approach is rethought", is the player's example of a builder and not of a
reviewer. A reviewer waits for CI and reads it as **committing** says ("CI's state is read through
GraphQL"), at most every ten minutes.

## A queue update is reviewed for faithfulness and merged first

**A queue update is a PR whose every changed file is under `docs/todo/`, `docs/review/` or
`docs/playtests/`**: filing a playtest, filing or rewording an entry or an item, moving a band. CI
calls it queue-only (`tools/ci_classify.py`) and runs its mechanical checks before the review does.
It is merged ahead of other work (woolly-finch 35), work on how the project is worked on included
(**orchestrating**), since every brief is written from the queue on
`origin/main` (**orchestrating**) and a filing left open is a brief written from the older text. A
diff that also touches anything else, a skill or `CLAUDE.md` included, is not a queue update and
gets the full review above; the orchestrator's queue move on a PR that builds the work is reviewed
with that PR.

**Its review is Sonnet's, and it asks whether the queue says what the player said** (bouncy-heron
8). For each entry or item the PR adds or rewords, the reviewer reads it beside the playtest
statements it cites, in the playtest file itself, and asks:

- **Does it claim anything the player's words do not say?**
- **Does it drop a specific the player gave?** A number, a place, a case they described, a word
  they chose.
- **Does it reinterpret an answer that could be read two ways**, rather than asking?
- **Is a mechanism or a band the player did not name marked as the filer's proposal**, under
  "Proposed, not asked for:" (**playtest-feedback**)?
- **Does it collide with a recorded decision without naming it?** `tools/decisions.sh <noun>` finds
  the records about each thing the entry changes; an entry that replaces one quotes it.
- **Does every sentence about what the player asked say whether it is their words or a reading?**
  Their words go in quotation marks with their citation, and the filer's reading of them under
  `Read as:` (**playtest-feedback**); a reading written as though the player had said it is a
  finding (inbox #767 in minty-lemur).

A "yes" to the first, second, third or fifth, and a "no" to the fourth or sixth, is a
finding. **A reviewer flags; it does not resolve**: it says what does not match and where, and the
filer takes it back to the player or to the words.

**It also verifies what CI checked, since a script sees that a thing exists, not what it says**
(bouncy-heron 9). The `gates` job's queue update step (`tools/ci_queue_update.py`) fails on an
existing playtest changed, on a deleted queue file with neither a record on `main` for its entry nor
a `Dropped: <path> — "<the player's words>"` line in the description quoting a playtest verbatim,
and on a deleted review item no playtest names; it puts `tools/queue.sh`'s line for every entry
touched in the job's summary. The reviewer checks that the step ran (CI called the PR queue-only),
and then what it could not:

- **A record that exists covers the item deleted**: it says the item's work was built, not only
  that the entry has a record.
- **A drop's quote says what the drop claims**: the player's words let the item go, rather than
  only mentioning it.
- **A review item's playtest answers it**, rather than only naming it.
- **Each entry sits in the band the description says**, from the job summary's lines.

**It is still a review.** Merging needs one approving review (**committing**), and a bot's approval
is the only one the orchestrator can get without the player. A push after the approval gets the
same review of its delta. Going first changes the order, not the permission: merging
still follows **committing**'s permission rule.

## Proposed, not asked for

These rules above are the filer's proposals and readings, not the player's words, and hold until
the player corrects them. The citation is the player's word each one extends, or the record that
proposes it:

- **A refused reviewer spawn or review post is reported to the player and never worked around**
  ("The findings go on the PR"; curly-rabbit #1094).
- **How the rethink after three *not ready* verdicts runs**: what counts, what else it asks, who
  writes it with no orchestrator, that a builder's rethink is checked, and where it goes ("Three
  verdicts of *not ready* mean the approach is rethought"; woolly-penguin #759).
- **A queue update merges ahead of work on how the project is worked on** ("A queue update is
  reviewed for faithfulness and merged first"): both are to go first (woolly-finch 35; inbox
  #1305), and the order between them is the filer's, since a brief for either is written from the
  queue.
- **The first five questions of a queue update's review**, the reviewer's reading of faithfulness
  (bouncy-heron 4), the filer's proposal (leafy-finch).
- **A fix keyed on one row's id or picture is raised as a proposal-backed finding** ("Then the
  code"), since the rule it breaks is **designing-classes**' proposal (plush-kestrel).
