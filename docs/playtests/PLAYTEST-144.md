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
words alone with the date inside the file. The player chose the first option, which read, label
and description verbatim:

> Date file, 2 words (Recommended) — File docs/todo/2026-09-26-busy-badger.md; spoken and linked
> as "busy-badger". Sorted by date for free; short to say; lint rejects a duplicate.

Then, in the same conversation:

> "so which items will now have random words and are separate files?"

> "prioritize the new system. and once each agent is done convert theirs to the new system"

> "merge the hook before the new system -- that has even higher priority"

The first was answered by the table quoted below. The other two set the order: the `git grep` hook
first, then M223, and each agent's work converted to the new layout as it finishes.

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

The proposal the player was answering, verbatim from the orchestrator's message:

> | Thing | Today | After M223 | Random words? |
> |---|---|---|---|
> | **Queue entry** (a milestone) | a `## M215 — …` section in `TODO.md` | a folder: `docs/todo/2026-09-26-busy-badger/` | **yes**: date + two words |
> | **Item of an entry** (today's `- [ ]` lines) | a checkbox line inside the section | one file per item in the entry's folder, written in full, deleted when done | no: a descriptive name like `stack-in-front.md`, since nothing outside its folder refers to it |
> | **Decision** (a record) | a `## …` section in `DECISIONS.md` | `docs/decisions/2026-09-26-busy-badger.md`, the same name as the entry it closes | **yes**: the entry's name |
> | **Playtest** | `docs/playtests/PLAYTEST-144.md` | `docs/playtests/2026-09-26-quiet-heron.md` | **yes** |
> | **Evidence folder** | `docs/evidence/m203-slug-date/` | `docs/evidence/busy-badger-slug-date/`, taking the entry's name | follows the entry |
>
>
> What keeps its number or form:
> - **Existing M1–M223 and PLAYTEST-01…144** keep their numbers. Old entries still move into
>   folders, e.g. `docs/todo/2026-09-26-M210/`, and old decisions into files, e.g.
>   `docs/decisions/…-M203.md`. Renaming them would be a diff nobody can review.
> - **Statement numbers inside a playtest** ("statement 3") stay numbers. They're local to one
>   file, so two PRs never compete for them.
> - **Releases** keep semantic version numbers (`v0.19.0`), and PR numbers are GitHub's.
> - **`HANDOFF.md`** stays one file, written only at the end of a session.
> - **`TODO.md`** keeps only its header and "The order", the priority list that points at entry
>   folders.
>
> **One gap:** `docs/REVIEW.md` … I'd make each review item a file under `docs/review/` too, named
> after the entry it came from, and delete it when a playtest covers it. Shall I add that to M223?

Asked whether `docs/REVIEW.md`, the list of things waiting on a person and the fourth biggest source
of conflicts, becomes files as well:

> "yes, let's do review, too. rest sounds fine."

8. **Each review item is a file**, under `docs/review/`, named after the entry it came from, and a
   playtest that covers it deletes it. Its name is its entry's. → M223. (That its steps are prose rather than
   numbered is the orchestrator's proposal, not the player's words.)

## Then, answering the reviews' open questions

Asked, among others: how the restart disc's fill should show under a thumb; whether the brief
between two days may drop "She fell asleep after m:ss"; whether the chalk mark's robber may stand
out of waking range at the far end of a long alley; whether the burning building's sidewalk body
stays; whether the counter's asks get queue entries. The player, in one message ("Robert" and
"river" are dictation for *robber*, as the player said after: "*robber not river", "*robber not
Robert"; "teller" is read as *yeller*):

> "373 this is already implemented for mouse. Just make it appear everywhere. Where does the
> decision to add a river after handing to the teller come from? You can keep the she feel asleep
> after xx:xx and then do the rest about the next day. Or we will have to split it into two
> screens. It's fine if the Robert doesn't get triggered every time. The fire goes on the
> building. The challenge is the fire truck not the fire. The file layout change needs to land
> before picking up new tasks. After that the telemetry changes are next. Split every file where
> appropriate. Even the review file. We overhaul all items that are currently relevant."

9. **The held restart's fill shows everywhere as it does for the mouse**, on a phone included.
   → M212, on PR #373.
10. **The brief between two days keeps "She fell asleep after m:ss"** for the day that ended, and
    the rest of it is the coming day's; or it becomes two screens. → M210.
11. **The chalk mark's robber stands at the far end even where he then never wakes.** → M213.
12. **The burning building's fire is drawn on the building, and the fire itself is no obstacle on
    the sidewalk: the danger is the fire truck.** → M218.
13. **The file layout (M223) lands before any new task is picked up, and the counter's asks come
    next.** → M223, M225.
14. **Every file is split where that is appropriate, the review file included, and every item
    still relevant is overhauled** in the new layout. → M223.

## Then, on the orchestrator's list of additions beyond the player's words

The orchestrator listed 27 choices made beyond the player's words across the open PRs, numbered,
for the player to reaffirm or overturn. The player:

> "can you elaborate on 9. Let's do chasing guard for the van. Robber for yeller is fine *if* it
> starts offsceeen. 13 is not okay. 17. Why? 18 wdym? For the roof I need to see examples. Explain
> 25. How can I check on a phone anyway? Screenshots? All other items looked good"

The items the answer names, as listed: 9, code comments citing "`DECISIONS.md`, M129, …" stay and
resolve through a search command (M223); 11, a chasing robber also after the van, the burnt shell
and the roadblock (M137); 13, the cyclist's smaller field makes him cheaper to pass, 16.0 to 12.1
(M207); 17, roof furniture is not carried onto an extended roof, and 18, a column against the map
edge stays blank (M203); 25, the day-6 handover ends the man shouting's charge at 36px, inside his
45px inner radius (M205).

15. **After the van (day 7) a guard chases her**; after the man shouting, the robber, which is
    fine only if he starts off screen. → M137.
16. **The cyclist must not become cheaper to pass** for the shorter warning. → M207.
17. **The roof cases are judged on pictures.** → M203.
18. **Every other listed addition is reaffirmed**: 1–8, 10, 12, 14, 19–24, 26 and 27. 9 and 25
    wait on the explanations asked for, and 15–18, the roof cases, on the pictures. Of 11, the
    answer names the van and the man shouting; the burnt shell and the roadblock go back to their
    waiting guard as the smallest reading, open to the player.
