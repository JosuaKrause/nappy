---
name: session-cleanup
description: The end-of-session hygiene pass — make every document true again, move what is now history out to DECISIONS.md, prune the queue, and leave the handoff accurate. Load this at the END of every session, before the final report, and whenever asked to tidy the docs.
---

# End-of-session cleanup

**Run this at the end of every session.** A session adds decisions, closes items and moves numbers,
and every one of those makes some sentence somewhere false. Left alone for a few milestones the
project reaches the state this pass exists to prevent: **three files carrying three different
answers to the same question, and no way to tell which is current.**

It is a short pass when it is done every time and a milestone when it is not.

The standard it enforces is `CLAUDE.md`'s "Documentation is written in the present tense": every
document states what is true now, keeps the reason and moves the incident to `DECISIONS.md`.

## The pass

### 1. Did anything this session make a document false?

Check what the session touched, then check what claims things about it. The usual suspects:

- **`docs/HANDOFF.md`** — the tree state and what is queued. This file is wrong more often
  than any other because it is the one that talks about *now*.
- **`CLAUDE.md` and `.claude/skills/`** — did a rule change, or a file get renamed out from under
  one?
- **The design docs** — `CITY`, `EVENTS`, `MECHANICS`, `TELEMETRY`, `ARCHITECTURE`, `NARRATIVE`,
  `README`. A stale sentence here is indistinguishable from a design.
- **Docstrings on anything edited.**

### 2. Never quote a number with a short shelf life

`CLAUDE.md` states the rule. Run `./tools/lint.sh` rather than relying on the eye to catch a
break of it: it scans the governed docs for exactly these shapes (a commit hash, a branch name, a
check count, a ticked box, a status word in a heading) and fails loudly on a hit.

Where a measurement *is* the point — a density, a cost, a ratio — say what it was measured over and
when, and put it in `docs/DECISIONS.md` rather than in a rule.

### 2a. Grep for what pointed at anything you moved

**A reference is not visible from the file being moved.** If this session renamed, split or
relocated anything, search the repo for its old name before finishing — hooks, `.codex/`, `tools/`
and settings included:

```sh
git grep -n "<old name>" -- ':!docs/DECISIONS.md' ':!docs/playtests/'
```

### 2b. The drift guard

**If `src/autoload/tuning.gd` or `src/events/event_catalogue.gd` changed this session**, grep the
governed docs for the name of every constant or row that moved and re-check every quoted figure
against it: when the code changes, nothing else rereads the sentence that quoted its old value.

### 3. Move what is now history

Anything that stopped being current this session goes to **`docs/DECISIONS.md`**: decisions taken
with the options rejected and why, ideas rejected outright, and changes that happened with the
measurement that justified them. Dated, and naming the milestone and playtest that produced it.

**The test:** every fact lifted out of a docstring or a rule must be findable in `DECISIONS.md` by
searching for the symbol or the noun it was attached to.

**The playtest files are never rewritten**, not even into the present tense: they are the only
record of what was said, and `DECISIONS.md` cites them.

### 4. Prune the queue

In `docs/TODO.md`:

- **Remove what got done.** A finished entry leaves `TODO.md` and its record goes to
  `DECISIONS.md`; nothing is ticked.
- **No status words in headings.** A heading names the work, never its state.
- **Reassess anything long open.** An item nobody has touched in ten milestones is either still
  wanted, superseded, or already done by something else. Say which, in the entry. An open item with
  no reassessment date is an item that will be read as current forever.
- **An open item keeps a pointer** to its `DECISIONS.md` section, so picking it up does not mean
  reconstructing the reasoning.

### 5. Check the rules did not drift out of their skill

If this session established a working rule, it is in a skill or in `CLAUDE.md` (see its "Notes
belong in the repo"). If a skill has grown past what it is about, split it rather than letting
`CLAUDE.md` grow.

### 6. Commit and propose

Commit each piece as it is settled; a decision that is only in the working tree is only in the
session. Push the branch and create or update its PR. Merging follows **committing** (explicit
permission in this session), and so does retiring a merged branch.

### 6a. Leave the review list true

`docs/REVIEW.md` holds what waits on a person: **committing** says when a PR adds an entry and
**playtest-feedback** when a playtest removes one; check both happened for this session's work.

### 7. Leave the handoff true

`docs/HANDOFF.md` is the last thing to write and the first thing the next session reads. It says the
tree state, what is queued in order, and nothing else. **If it is wrong, everything downstream of it
is wrong too.**

### 8. End with a fresh-context restart prompt

Every session handover ends with a restart prompt the player can use to start the next session
with a genuinely fresh context. **The prompt goes into `.claude/restart-prompt.md`, a local file
that git ignores, and never into the chat**: copying long text out of the CLI corrupts it
*(2026-09-26: "make a note to not write the local handoff in the chat since CLI c&p is broken
write it to a local file and don't check it in")*. Each handover overwrites the file, and the
report in the chat names its path. Do not require the next session to have read this conversation or
to resume an old agent transcript. The prompt tells it to fetch and inspect live PR state, then read
`CLAUDE.md`, `docs/HANDOFF.md`, `docs/TODO.md` and the named work-item sources before acting.

Name every open thread by PR number and short title, branch or worktree when relevant, current
checkpoint, exact next action, remaining gate and verification already completed. Restate the
scope fences and merge authority that matter. If delegation should continue, say to start fresh
agents with self-contained briefs rather than resuming the session's agents. Keep the prompt
self-contained and current at the moment of handover; the final report may summarize it, but the
file must stand on its own.
