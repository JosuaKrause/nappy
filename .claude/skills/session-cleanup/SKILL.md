---
name: session-cleanup
description: The end-of-session hygiene pass — make every document true again, move what is now history into a decision record, prune the queue and the review items, and write the handoff. Load this at the END of every session, before the final report, and whenever asked to tidy the docs.
---

# End-of-session cleanup

**Run this at the end of every session.** A session adds decisions, closes items and moves numbers,
and every one of those makes some sentence somewhere false. Left alone for a few milestones the
project reaches the state this pass exists to prevent: **three files carrying three different
answers to the same question, and no way to tell which is current.**

It is a short pass when it is done every time and a milestone when it is not.

The standard it enforces is `CLAUDE.md`'s "Documentation is written in the present tense": every
document states what is true now, keeps the reason and moves the incident to a decision record.

## The pass

### 1. Did anything this session make a document false?

Check what the session touched, then check what claims things about it. The usual suspects:

- **`docs/HANDOFF.md`** — the tree state and what is queued. No pull request edits it, so it is
  wrong about everything that merged since the last session's end; step 7 rewrites it.
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
when, and put it in a decision record rather than in a rule.

### 2a. Grep for what pointed at anything you moved

**A reference is not visible from the file being moved.** If this session renamed, split or
relocated anything, search the repo for its old name before finishing — hooks, `.codex/`, `tools/`
and settings included:

```sh
rg -n "<old name>" --glob '!docs/decisions/**' --glob '!docs/playtests/**' --glob '!docs/evidence/**'
```

`rg` rather than `git grep`: the evidence folders hold tens of gigabytes of pictures, and a
`git grep` without `-I` reads every one of them.

### 2b. The drift guard

**If `src/autoload/tuning.gd` or `src/events/event_catalogue.gd` changed this session**, grep the
governed docs for the name of every constant or row that moved and re-check every quoted figure
against it: when the code changes, nothing else rereads the sentence that quoted its old value.

### 3. Move what is now history

Anything that stopped being current this session goes to **a decision record under
`docs/decisions/`** — the entry's own when it has one, else a new one from `tools/new-name.sh
decision "<title>"`: decisions taken with the options rejected and why, ideas rejected outright,
and changes that happened with the measurement that justified them. Dated, and naming the entry
and playtest that produced it.

**The test:** every fact lifted out of a docstring or a rule must be findable with
`tools/decisions.sh` by searching for the symbol or the noun it was attached to.

**The playtest files are never rewritten**, not even into the present tense: they are the only
record of what was said, and the records cite them.

### 4. Prune the queue

In `docs/TODO.md` and the entries under `docs/todo/`:

- **Remove what got done.** A finished item's file is deleted; a finished entry's folder goes, its
  link leaves `TODO.md`'s order and its record is a decision under the entry's name; nothing is
  ticked. `tools/lint.sh` names a link in the order to a folder that is gone.
- **No status words in headings.** A heading names the work, never its state.
- **Reassess anything long open.** An item nobody has touched in ten milestones is either still
  wanted, superseded, or already done by something else. Say which, in the entry. An open item with
  no reassessment date is an item that will be read as current forever.
- **An open item keeps a pointer** to its decision records, so picking it up does not mean
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

The items under `docs/review/` and the untested list in `docs/REVIEW.md` hold what waits on a
person: **committing** says when a PR adds a review item and **playtest-feedback** when a
playtest deletes one; close every item a playtest this session covered, and check both happened
for this session's work.

### 7. Leave the handoff true

`docs/HANDOFF.md` is the last thing to write and the first thing the next session reads, and this
pass is the only thing that writes it *(2026-09-26: "handoff only at the end of a session")*:
pull requests do not, so rewrite it from the tree and the open pull requests as they stand. It says the
tree state, what is queued in order, and nothing else. **If it is wrong, everything downstream of it
is wrong too.**

### 8. End with a fresh-context restart prompt

Every session handover ends with a copy-paste prompt the player can use to start the next session
with a genuinely fresh context. Do not require the next session to have read this conversation or
to resume an old agent transcript. The prompt tells it to fetch and inspect live PR state, then read
`CLAUDE.md`, `docs/HANDOFF.md`, `docs/TODO.md` and the named work-item sources before acting.

Name every open thread by PR number and short title, branch or worktree when relevant, current
checkpoint, exact next action, remaining gate and verification already completed. Restate the
scope fences and merge authority that matter. If delegation should continue, say to start fresh
agents with self-contained briefs rather than resuming the session's agents. Keep the prompt
self-contained and current at the moment of handover; the final report may summarize it, but the
copy-paste block must stand on its own.
