---
name: committing
description: The git workflow for this repo — one branch per milestone, one commit per TODO item, what a commit message must explain, and when to merge and delete. Load this BEFORE committing, branching, merging or writing a commit message.
---

# Git workflow

**The local repository is this side's to manage — branch, commit and merge without asking each
time.**

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

**Commit before stopping.** Work that is finished and green does not sit in the working tree waiting
to be asked about: an unfinished milestone is a branch with commits on it, not a dirty tree.

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

Run the verification loop — see the **verify** skill. `./tools/check.sh`, `./tools/test.sh`
unfiltered, and a screenshot if you touched anything visual. **A filtered test run prints
`PARTIAL RUN` and is not a green build.**

Run `./tools/lint.sh` too if the commit touches a governed doc (`CLAUDE.md`, a skill, `README.md`
or anything under `docs/` besides `DECISIONS.md` and the `PLAYTEST-NN.md` files). A hit is a stop:
fix the sentence or commit nothing.

## Never commit

- **`.godot/`.** It is gitignored, which means a fresh clone has no `class_name` registry and every
  typed reference fails to parse until `check.sh` runs the import pass.
- **A doc that contradicts the code it ships with.**
