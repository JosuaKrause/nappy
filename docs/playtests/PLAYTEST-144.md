# Playtest 144 — One file per queue entry and per decision, a handoff only at the end, and names instead of numbers

2026-09-26. Said in conversation, in answer to a count of which files conflicted in the repo's
merges since 2026-09-01: of 590 merges, 136 conflicted, 86 of them in `docs/DECISIONS.md`, 57 in
`docs/TODO.md`, 23 in `docs/HANDOFF.md` and 12 in `docs/REVIEW.md`, against 6 in the most
conflicted code file.

## What the player said

> "we can do one file per queue entry/decision and handoff only at the end of a session. CI
> shouldn't require up to date PRs anyway -- not sure why you were seeing that. it shouldn't be
> active. also what do you think about sequential numbers? this requires some coordination across
> PRs. would it be possible to use random words eg Mgray-busy-badger to create random but memorable
> tasks? it would be hard to find the latest ones since they won't be alphabetical so you'd have to
> look at the timestamp."

## The statements

1. **Each queue entry is a file of its own, and so is each decision.** Two PRs then never edit the
   same queue or decisions file. → M223.
2. **`docs/HANDOFF.md` is written only at the end of a session**, not by each PR. → M223.
3. **A PR behind `main` merges as it is.** The ruleset's required check is not strict, and
   nothing in the repo claims otherwise. The orchestrating skill and `tools/land-prs.sh` said the
   ruleset required an up-to-date branch, and are corrected on their own PR.
4. **Sequential milestone numbers need coordination across PRs.** The player proposes random but
   memorable names, such as `Mgray-busy-badger`, found by timestamp rather than alphabetically.
   → M223.

## Then, on how the names work

Offered: a date in the file's name with two words after it, the same with three words, or three
words alone with the date inside the file. The player chose the first:

> "Date file, 2 words": `docs/todo/2026-09-26-busy-badger.md`, spoken and linked as
> "busy-badger".

5. **A new queue entry is named by two random words, an adjective and an animal, after the date it
   was filed**, and the file keeps that name when it becomes a decision. Sorting the folder puts
   the newest last. Existing entries and records keep their M-numbers. → M223.

And, in the same conversation:

> "that numbering should be for everything that currently has a strict sequential number"

6. **Everything the repo numbers in sequence takes the same kind of name**: a new playtest file as
   well as a new queue entry and its decision, e.g. `docs/playtests/2026-09-26-quiet-heron.md`.
   Files that already have a number keep it. → M223.

> "maybe todos can be files, too? that way completing a task is just deleting the file and no
> awkward - [ ] is necessary. the item can be written in full"

7. **Each item of a queue entry is a file of its own**, written in full prose with no checkbox, and
   completing it deletes the file. An entry is then a folder: its own words and context in one
   file, one file per item beside it. → M223.

The proposal the player was answering, as the orchestrator put it: a queue entry is a folder
named by date and two words, each of its items a file with a descriptive name deleted when done; a
decision is a file under the entry's name; a new playtest is named the same way; an evidence folder
takes its entry's name; existing M-numbers and PLAYTEST-NN files keep their names; statement
numbers inside a playtest stay numbers; releases keep their version numbers; `HANDOFF.md` stays
one file written at the end of a session, and `TODO.md` keeps only its header and "The order".
Asked whether `docs/REVIEW.md`, the list of things waiting on a person and the fourth biggest source
of conflicts, becomes files as well:

> "yes, let's do review, too. rest sounds fine."

8. **Each review item is a file**, under `docs/review/`, named after the entry it came from, and a
   playtest that covers it deletes it. An item's steps are not numbered, and its name is its
   entry's. → M223.
