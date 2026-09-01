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

## The standard this enforces

**Every document states what is true now and only what is true now.** No "used to be", no "since
M33", no "this was wrong for twelve milestones", no caveats about what a sentence meant before.

**Keep the reason a thing is the way it is; move the incident that taught it.** "A negative-width
`Rect2` is normalised on the way through, so the sprite lands a full width to one side" is a rule.
"M12c spent a day on this" is history.

**The test is a reader, not a diff:** somebody who opens any single file and believes every sentence
in it is wrong about nothing.

## The pass

### 1. Did anything this session make a document false?

Check what the session touched, then check what claims things about it. The usual suspects:

- **`docs/HANDOFF.md`** — the tree state, the branch, what is queued. This file is wrong more often
  than any other because it is the one that talks about *now*.
- **`CLAUDE.md` and `.claude/skills/`** — did a rule change, or a file get renamed out from under
  one?
- **The design docs** — `CITY`, `EVENTS`, `MECHANICS`, `TELEMETRY`, `ARCHITECTURE`, `NARRATIVE`,
  `README`. A stale sentence here is indistinguishable from a design.
- **Docstrings on anything edited.**

### 2. Never quote a number with a short shelf life

**Do not put a check count, a commit hash you are not currently standing on, or a measured figure
into a doc unless the doc's job is to record that measurement.** Say what the command is, not what
it prints. This repo once carried three different answers to "how many checks does the suite run".

Where a measurement *is* the point — a density, a cost, a ratio — say what it was measured over and
when, and put it in `docs/DECISIONS.md` rather than in a rule.

### 2a. Grep for what pointed at anything you moved

**A reference is not visible from the file being moved.** If this session renamed, split or
relocated anything, search the repo for its old name before finishing. Six documents pointed at
`CLAUDE.md` sections by name and all six were wrong within the hour of those sections becoming
skills — correct when written, stale immediately, and invisible from the diff that caused it.

```sh
grep -rn "<old name>" --include='*.md' --include='*.gd' . | grep -v DECISIONS.md
```

### 3. Move what is now history

Anything that stopped being current this session goes to **`docs/DECISIONS.md`**: decisions taken
with the options rejected and why, ideas rejected outright, and changes that happened with the
measurement that justified them. Dated, and naming the milestone and playtest that produced it.

**The test:** every fact lifted out of a docstring or a rule must be findable in `DECISIONS.md` by
searching for the symbol or the noun it was attached to.

**The playtest files are never rewritten.** `docs/PLAYTEST-NN.md` are primary sources — a player's
own words on a date — and putting one in the present tense would destroy the only record of what was
said. `DECISIONS.md` cites them.

### 4. Prune the queue

In `docs/TODO.md`:

- **Tick what got done**, and move the completed entry's narrative out to `DECISIONS.md`. A ticked
  item is history the moment it is ticked.
- **Check the headings.** A milestone heading that says "not started" over merged work is the
  cheapest possible lie and the easiest to miss.
- **Reassess anything long open.** An item nobody has touched in ten milestones is either still
  wanted, superseded, or already done by something else. Say which, in the entry. An open item with
  no reassessment date is an item that will be read as current forever.
- **An open item keeps a pointer** to its `DECISIONS.md` section, so picking it up does not mean
  reconstructing the reasoning.

### 5. Check the rules did not drift out of their skill

If this session established a working rule, it belongs in a skill or in `CLAUDE.md` — **not only in
an assistant's memory**, which is invisible to everybody else who opens the repo. If a skill has
grown past what it is about, split it rather than letting `CLAUDE.md` grow.

### 6. Commit, merge, delete

Commit each piece as it is settled; a decision that is only in the working tree is only in the
session. If a branch is fully merged, delete it — see the **committing** skill.

### 7. Leave the handoff true

`docs/HANDOFF.md` is the last thing to write and the first thing the next session reads. It says the
tree state, what is queued in order, and nothing else. **If it is wrong, everything downstream of it
is wrong too.**
