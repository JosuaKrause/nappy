---
name: session-cleanup
description: The end-of-session hygiene pass — make every document true again, move what is now history into a decision record, prune the queue and the review items, and write the local restart prompt. Load this at the END of every session, before the final report, and whenever asked to tidy the docs.
---

# End-of-session cleanup

- **Every document the session touched, or made false, states what is true now**; `./tools/lint.sh` finds the volatile facts.
- **What stopped being current goes to a decision record**, findable with `tools/decisions.sh`; a playtest file is never rewritten.
- **The queue holds open work only**: finished items and their entries are gone, each band is still true, no heading carries a status.
- **Everything is committed, pushed and on a pull request** before the session ends.
- **Every item under `docs/review/` a playtest covered is closed.**
- **A job removes its own scratch and nothing else**; merged branches are retired with `tools/prune-merged.sh`.
- **Nothing checked in says where the session stopped.**
- **The restart prompt goes into `.claude/restart-prompt.md`, never into the chat**, rewritten whole in its fixed layout, and records no merge or release permission.

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
rg -n --hidden "<old name>" --glob '!.git' --glob '!docs/decisions/**' --glob '!docs/playtests/**'
```

`--hidden` is what reaches `.claude/` and `.codex/`; `rg` skips binary files and gitignored paths
(the agent worktrees among them) on its own. Not `git grep`: without `-I` it runs the pattern over
every image and video under `docs/evidence/`, which grows past gigabytes, and the Bash hook denies it.

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

- **Remove what got done.** A finished item's file is deleted; a finished entry's folder goes and
  its record is a decision under the entry's name; nothing is ticked. Every `after:` line that
  `tools/queue.sh` prints as `<name>, closed` names an entry that has closed since, and goes now:
  the pull request that closed it left the line alone so as not to edit a second entry.
  `tools/lint.sh` names an `after:` that names neither an open entry nor a record, and a link in
  `TODO.md` to a folder that is gone.
- **Every entry's band is still true.** `tools/queue.sh` prints the order the bands give; an entry
  the player has since put first, or set aside, moves with a one-line edit to its `priority:`
  line, and an `after:` whose wait the entry's own text no longer states goes. An `upnext:` line on
  an entry an open pull request is already building goes too.
- **No status words in headings.** A heading names the work, never its state.
- **Reassess anything long open.** An item whose file no commit has touched in thirty days
  (`git log -1 --format=%cs -- <the item's file>` prints the date of the last one) is either still
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
session. Push the branch and create or update its PR. Merging follows **committing** (the
orchestrating session's standing permission), and so does retiring a merged branch.

### 6a. Leave the review list true

The items under `docs/review/` hold what waits on a person: **committing** says when a PR adds a review item and **playtest-feedback** when a
playtest deletes one; close every item a playtest this session covered, and check both happened
for this session's work.

### 6b. Finish the job's storage cleanup

**A completed job cleans up its own scratch immediately, and the session verifies that it did.**
A job removes only what it recorded as its own, keeps its logs and the evidence asked for, and
never force-removes or unlocks another job's checkout. **Merged branches and their worktrees are
inventoried with `tools/prune-merged.sh --all`** and retired with `--all --apply`, through the
wrapped line **committing** ("Branches") gives; a finished agent's brief is released first
(`cleanup: ready`), and **the script deletes a released brief as it retires the brief's branch**,
the brief in the main checkout's `.claude/briefs/`, and keeps one that is not released.
**Free space is read from `df`, before and after**, since `du` counts
shared blocks more than once. `references/storage.md` has the rest; read it before removing
anything a job did not record as its own, after a browser run, and before multiplying worktrees or
starting a large build or capture batch.

### 7. There is no checked-in handoff

**Nothing in the repository says where a session stopped**, since every agent has its own thread to
work on and no session hands over to another (polite-marten). The pick-up state is live — `gh pr
list`, `tools/agent-status.sh`, `tools/queue.sh`, the inbox (`uv run python tools/inbox.py list`,
**inbox**), the Nappy board (**board**) and the items under `docs/review/` answer it at the moment they are asked — and what a
document would have said about it is stale the moment another thread merges. So the session's end
writes nothing checked in about itself: the durable part of what it learned is already in a skill, a
doc, an entry, a review item or a record by the steps above, and the rest is the restart prompt
below. `tools/decisions.sh handoff` has the reasons.

### 8. End with a fresh-context restart prompt

Every session handover ends with a restart prompt the player can use to start the next session with
a genuinely fresh context. **The prompt goes into `.claude/restart-prompt.md`, a local file that git
ignores, and never into the chat**: copying long text out of the CLI corrupts it (woolly-finch 31).
Each handover overwrites the file, and the report in the chat names its path. The file is
rewritten whole in a fixed layout, so the next orchestrating session reads it top to bottom the same
way every time and checks each row against `gh pr list` and `tools/agent-status.sh` (**CLAUDE.md**).
A layout made for reading, old entries removed routinely and a systematic way of reading the file
are what the player asks of it (frosty-owl #1065); this is the layout:

1. a header saying the file is rewritten in place and how to read it: whole, then the live-state
   commands, which win where they differ;
2. `## Open threads`, a table with the columns Thread | Worktree / branch | Checkpoint | Next action;
3. `## Waiting on the player`;
4. `## Open inbox notes`;
5. `## Board bookmarks`;
6. `## Plan`;
7. `## Fences`.

**`## Plan` holds what is already decided about what comes when** (inbox #1235 in gentle-owl): the phases in
order, what starts each (a merge, an agent's report, the player's go-ahead), what runs in parallel
within one, and where the next release falls with what it waits for. Each line rests on the player's
words or a recorded decision and cites it, and the readings settled on the player's words that wait
to be written into a queue item are listed with their citations, so no later session puts them back
to the player as questions. An open point is listed only when it truly is open.

A handover writes one row per open thread, and a thread whose pull request merged or was dropped
has no row, since the pull request and its record hold it. Nothing is carried over as a log, so the
file stays short enough to read whole, and a top that still describes finished work would read as
work in flight. **The file stays under 10 KB** (`wc -c .claude/restart-prompt.md`), since it is
read whole at every session start: a file over the bound is cut before the handover ends, a row to
its pull request, checkpoint and next action, and whatever explains the work to where it belongs
(the pull request's description, the queue item, a record). The file is also kept current during the session, whenever that is cheap, so a session
cut off without a handover leaves a file a fresh one can reorient from; this step rewrites it whole
(inbox #986 in brisk-pelican). Do not require the next session to have read this
conversation or to resume an old agent transcript. The prompt tells it to fetch and inspect live PR
state (`gh pr list`, `tools/agent-status.sh`) and the inbox (`uv run python tools/inbox.py list`),
then read `CLAUDE.md` and `docs/TODO.md`, run `tools/queue.sh`, and
read the named work-item sources before acting.

Name every open thread by PR number and short title, branch or worktree when relevant, current
checkpoint, exact next action, remaining gate and verification already completed (the verification
goes in the Checkpoint column and the remaining gate in the Next action column). **List the open
inbox notes** by issue number and title, as `tools/inbox.py list` prints them at the handover, so
the next session knows what the player has written and nobody has filed yet (**inbox**). Give the
Nappy board's last read `rev` and last comment `seq` for each of its two tabs, Main and Review, so
the next session reads only what changed since (**board**). Restate the scope fences that matter. If
delegation should continue, say to start fresh agents with self-contained briefs rather than
resuming the session's agents, and the next session is not required to resume
one. It may resume an agent a restart
stopped, by a message to the id on its brief, while `tools/agent-status.sh` reports it warm
(**orchestrating**, "Recovering from an interruption"). Keep the prompt self-contained and current at the moment of handover;
the final report may summarize it, but the file must stand on its own.

**The restart prompt never records a merge or release permission** (polite-marten). The
orchestrating session's merge permission is standing in `CLAUDE.md` (inbox #1063 in gentle-walrus), so there is
nothing to record; any other permission (a release, or a merge granted to another session) is given
in a session and ends with it (**committing**, "Merging" and "Releasing"), so a sentence carrying
it forward is either a grant nobody gave the next session or an invitation to act on one; the next
session asks the player.

## Proposed, not asked for

These rules above are the filer's proposals, not the player's words, and hold until the player
corrects them. An entry cites the player's word it extends where there is one, and says so where
there is none:

- **Thirty days without a commit to its file is what makes an item long open** (step 4). The
  player has named no interval.
- **The restart prompt's seven-part layout** (step 8; frosty-owl #1065).
- **The restart prompt stays under 10 KB** (step 8). The player has named no bound.
- **The next session may resume an agent a restart stopped, while it is reported warm** (step 8),
  which is **orchestrating**'s proposal. The player's words are that a cold agent is not resumed
  (woolly-finch 5) and that a warm one is reused while rebriefing would cost more
  (inbox #896 in plaid-raven); neither is about an agent a restart stopped.
