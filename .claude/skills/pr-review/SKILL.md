---
name: pr-review
description: How every pull request is reviewed before it may merge — adversarially, by a reviewer that did not write it, semantic correctness first (the player's words, recorded decisions, the queue), then code, with the findings posted on the PR and a verdict against its current head. Load this BEFORE reviewing a PR, briefing a review agent, or deciding a PR is ready to merge.
---

# Reviewing a pull request

**Every pull request goes through an adversarial review before it is ready to merge.**
*(2026-09-26: "also all PRs must go through a (adversarial) review before ready to be merged.")*
No exception for size or kind: a one-line fix, a docs PR filing a playtest, a hook, the
orchestrator's own queue moves. **Ready to merge** means a review by a reviewer that did not write
the change has posted the verdict *ready* on the PR, against the PR's current head. Green CI and an
author's report of "done and verified" are inputs to the review, never a substitute for it.

**A push after the review is reviewed too.** Whatever lands on the branch after the verdict (a
fix for a finding, a merge of `main` that needed resolving, the orchestrator's queue move) gets a
review of the delta since the reviewed head before the PR merges. A merge of `main` that went in
without a conflict is the one exception: nothing the branch says changed, and the merger's own
semantic reconciliation under **merging-main** covers what `main` brought.

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
no playtest, the quote in its queue entry or its brief) and every decision the change touches, and
answers these. Each "no" is a finding:

- **Is this what the player asked for?** Nothing they asked for is left out, and every case they
  described is covered and shown, not only the first. Nothing is built beyond their words unless
  it is marked: a mechanism under "Proposed, not asked for" (**playtest-feedback**), which the
  player agreed to if it changes what they see across the game, or a small choice the PR
  description names as open to overturn (**orchestrating**, "Forks come back"). An unmarked
  addition is a finding; so is a game-wide one the player never saw.
- **Does it keep what is already decided?** No `DECISIONS.md` record and no doc rule is overturned,
  narrowed or rewritten in passing. A doc sentence the PR changed says what the player decided, not
  what the PR happened to build.
- **Would the player recognise it in the pictures?** A visible change is judged on its pictures
  against their words, before its code. A visible change with no pictures is a finding.
- **Does the finished work leave the queue inside this PR?** *(2026-09-26: "reviews should check
  that work items are properly removed from the queue *inside* the PR that finished it".)* Every
  item the PR completes is gone from the queue in this diff, with its record written, and every
  item it only partly does is still there and says what is left. An item left queued after its work
  merges is how a finished thing gets picked up again with a different approach; an item removed
  for work the PR did not do is how an ask disappears.

*(The case that taught it: a review of a park fenced with street-closure barriers found "no
correctness bug in the mechanism"; the player had asked only that the router not path through a
used park, and had decided long before that a used park is spoiled with events.)*

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
may run a suite from a checkout of its own, one Godot process at a time, and never runs `git grep`
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
inline comments as **one** review (event COMMENT) with a short summary rather than one comment per
finding; a finding with no line to hang on — a missing doc, a missing test, a missing picture —
goes in the summary. **The summary ends with the verdict, *ready* or *not ready*, and the head
commit it was given against.** A review with nothing to say still says so, and what it checked.

The reviewer never approves or requests changes through GitHub's buttons and never merges: the
verdict is in the review's text, and merging is **committing**'s, under its permission rule.

The conversation still gets the recap, since the player reads that first; the PR is where the
findings live.

## Briefing a review agent

The brief names the PR, its branch, the playtests and queue entry it answers, and anything the
orchestrator already knows is contested. It asks for this skill's order (semantic first, then code),
one review posted on the PR, and a report back: the verdict, each finding with its severity, and the
review's URL. Sonnet is enough for a small or mechanical PR; a PR that carries a design decision, a
drawing, or a change to the rules is reviewed by a stronger model.
