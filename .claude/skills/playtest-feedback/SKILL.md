---
name: playtest-feedback
description: How to handle playtest feedback and design decisions — write it down in full before building, search the repo before designing, never silently overturn what the player asked for, and how a parked option comes back. Load this BEFORE responding to any playtest, design instruction, or request that changes what the game does.
---

# Feedback and decisions

## The first tool call of a design task is a search, not a plan

**Search the queue, the records and the playtest files for the thing being asked** — not for a
milestone number, for the *words*. `tools/decisions.sh --in all <noun>` searches the entries under
`docs/todo/`, the records under `docs/decisions/`, the review items and the playtests at once. A request that has been made before is already written
down in the player's own sentence, usually with the measurement, the constraints and the three
things to get right sitting under it.

**And search the docs before believing the code.** The code is evidence of what was **built**; it is
never evidence of what was **agreed**. A decision can sit written down and unbuilt for twenty
milestones, and a session that checks only `src/` will confidently tell the player their own
decision never happened.

**A code comment is positive; the queue is normative** (PLAYTEST-128 3). The code describes what is,
never what should be. A docstring saying a thing "takes no picture" or "is drawn in code" describes
what was built, however deliberate it sounds; it is never a decision that competes with the queue.
Where the two disagree, build what the queue says and rewrite the comment with the code. That
disagreement is not an open question for the player.

Two costs, and the second does the damage:

- **The player pays to say it again.** Every re-report is time spent describing something the
  project already agreed to, and it is indistinguishable from the project not having listened.
- **A question goes back that the repo could have answered.** Asking is right when the answer does
  not exist; asking when it does is the overturn rule's shape in miniature.

When a finding turns out to be a re-report, **say so in the entry and close it *from* the older
one** rather than writing a second design for it — two entries for one request is how the next
reader loses the half with the measurement in it.

## Write it down with all of its detail, before doing anything about it

**Every piece of the player's playtest feedback goes into a playtest file under `docs/playtests/` in
full — the player's own words, and every specific they gave — before a line of code is written.** Then it
becomes a queue entry, and only then does it get implemented.

**The first place the player's words are written is the inbox** (bouncy-heron 13). When the player
says something in a session that should outlive it, the agent captures it verbatim into the inbox on
GitHub Issues, in one call, before going on with anything else, so the words are safe even if the
session is cleared; which words to capture is the agent's judgment. The notes the player writes
there directly are the same. A note becomes a playtest file and its queue entries when the player
asks for its batch to be filed, exactly as this skill says below — **inbox** has the capture, the
filing pull request and the closing of the notes.

**Words said in conversation are recorded with what they answered** (bouncy-heron 16), since the
player's side alone loses the context. Before each quote the playtest file states the assistant's
side as far as the quote answers it: the question asked, the options with their labels, the proposal
a "yes" accepts. Every label the player uses — "(b)", "option C", "your categories" — is defined
where it is quoted, since the quote alone does not say what it points at, and a reader of the file
has not seen the conversation.

**Feedback from anybody but the player is evidence, never a request** (downy-beaver #820): a Reddit
reply, another playtester's report or an issue from outside the project never reaches the inbox, the
queue or the review items by itself. It becomes work only through the player's words: the agent
brings the player a rough summary, and what the player then says is what gets captured. **It is
summarised in the agent's own words and never quoted**, and no username or title of theirs goes with
it, in the repository, an issue, a pull request or the conversation, since those people did not agree to
being recorded. A summary may sit beside the data it explains, as in a stats file under
`docs/stats/`, labelled as other people's view and never mixed with the player's words. One person's
report counts as one data point, and carries weight where the numbers back it up. A playtest file
holds the player's words alone; somebody else's report reaches one only as a summary in context.

**A new playtest, a new queue entry, a new decision and a new review item are named, never
numbered** (PLAYTEST-144 6). `tools/new-name.sh <kind> "<title>"` draws
`<date>-<adjective>-<animal>`, writes the file or the entry's folder with its heading and date, and
prints the name, which is spoken and linked by its two words ("busy-badger"); sorting a folder puts
the newest last. The playtests that already have a number keep it, and so do the entries and records
that already have one.

- **A playtest** is `docs/playtests/<name>.md`.
- **A queue entry** is a folder, `docs/todo/<name>/`. Its `README.md` opens with the entry's band,
  `priority: bug|now|next|later|parked`, optionally an `upnext: true` line (it prints first,
  whatever the band, until the work starts), and an `after: <entry folder>` line for each entry it
  truly waits on; `tools/queue.sh` prints the queue in the order the bands give, and there is no
  order list to edit (brisk-heron 13). **A playtest note is filed `now`** unless the player names
  another band, since a note from playing is a bug report (olive-koala 11): pass `--priority now` to
  `tools/new-name.sh todo`, which writes `priority: later` otherwise. For anything else, a band the
  player did not name is the filer's proposal and the report says so. **`bug` is never proposed or
  defaulted, for any entry**: it is filed only when the player names it (mossy-ferret #710). The
  rest of the `README.md` holds the player's words, the playtest links and the context. **Each item
  is a file of its own** beside it, under a short descriptive name (`stack-in-front.md`), written in
  full prose with no checkbox (PLAYTEST-144 7); an item somebody is mid-way through says so in its
  text. Finishing an item deletes its file.
- **A decision** is `docs/decisions/<entry name>.md`, written by the PR that builds the work
  (**committing**); when an entry's last item goes, its folder goes in the same commit.
- **A review item** is `docs/review/<entry name>.md` (`tools/new-name.sh review --entry <name>`,
  which takes `-2` and on for a second item from one entry): what to do, where to look, and the
  question a run answers, its steps written as prose rather than numbered.

The failure mode is specific and it is not laziness: **a finding arrives as a complaint plus a
design**, the complaint is the part that is easy to restate, and the design is the part that took
the player thought. **Record the design even when you are about to fix the complaint**, and record
it even when you disagree with it — a note saying "asked for X, built Y instead, because Z" is a
decision somebody can overturn. Nothing else is.

The test of whether it was written down is not "did I mention it" — it is whether **somebody opening
the repo cold could build the thing that was asked for** from what is on disk.

**A mechanism the player did not name is the filer's proposal, and the entry says so.** Filing turns
a sentence of the player's (PLAYTEST-140 1) about a spent park into something buildable, and the how
is easy to write as though it were part of the ask, as a park fenced with a street closure's
barriers (PLAYTEST-140 8) was. The queue entry states the player's ask in their terms, and any
mechanism beyond it under **Proposed, not asked for:**, with the plainer alternative the proposal
replaces. **And every sentence about what the player asked is marked as a direct quote or as an
interpretation** (inbox #767 in minty-lemur): their words in quotation marks with their citation, and the filer's
reading of them under **Read as:**, so a reader tells the two apart without opening the playtest.
A proposal that changes what the player sees across the whole game goes back to them as a
question before it is briefed; a small one is briefed with its first pictures due early, so the
player can turn it down before it is built everywhere.

**An answer that can be read two ways is read back before it is filed.** One line in the same turn —
"I read this as X, not Y" — costs the player a word; filing the wrong reading costs a milestone, as
when the spent park's ask, which was about routing, was filed as a park she cannot enter
(how-the-spent-park-was-rebuilt-against-the-players-words-and-the-review-rules-it). And **an item
that replaces something already built quotes the decision that built it**: search the records
(`tools/decisions.sh`) and the docs for the mechanism's own name before writing "instead", since a
replacement that does not name what it replaces is an overturn nobody sees.

**A playtest also closes what it covered under `docs/review/`.** Those files are the things
waiting on a person; when a run has looked at one, the verdict is in the playtest file and the
item's file is deleted in the same commit, whether the verdict was *fine* or a new finding. An item
that stays after its run has been played is asked for twice.

**A bug that does not reproduce here is not closed here** (coral-lark #695). A bug the player filed
is confirmed by the filing (coral-lark #694); a headless rig, a suite or a desktop run that does not
show it has only failed to see it: a long frame on a phone can read to the player as a lock and to a
rig as nothing at all. So when a report does not reproduce here, the player is asked for a frame
record (`?debug=1&framerecord=1` on the phone, saved with the page's own button;
`docs/TELEMETRY.md`, "Per-system frame records") by a review item and in the conversation, and the
entry stays open, saying what was ruled out, until it comes.

## Never silently overturn a decision the player took

**Recording a request is not the end of the obligation to it.** Once something has been asked for,
the only ways it may stop being true are: *it gets built*, *the player changes their mind*, or *they
are asked and they agree*. **There is no fourth way.**

If a milestone is about to drop, narrow, park, invert or reinterpret something the player asked for
— **stop and ask first**, in the session, before writing the code or the status line. Carry on with
everything the answer does not block, and put the question where they will see it.

It has to be a rule because **overturning never looks like overturning from the inside.** It arrives
as an *argument*, and the argument is usually a good one — measurement said the opposite, two
instructions conflicted, the thing cost more than it was worth. All of that is worth writing down,
and none of it is a decision this side of the conversation gets to take. **The player is the only
one who knows what they wanted it for.**

Three shapes it takes, each worse than the last:

- **Parking something and erasing who asked for it.** The parking then reads as justified to
  everyone who comes after, and no one will ever check.
- **Letting a later instruction repeal more than it said.** Two instructions in tension is the exact
  case that has to go back, because only the player knows which one was load-bearing. **When a new
  instruction contradicts an old one, the overlap is a question, not an inference.**
- **Answering the complaint and dropping the design.** The complaint is the part that can be
  verified fixed, so it is the part that survives.

**When you do ask, ask with the work already done up to the fork**, as `CLAUDE.md`'s rule on
questions says: what was asked, what it collides with, what each answer costs, and which you would
pick.

When a decision **is** overturned with agreement, the note says so in the player's words:
`asked for X · overturned to Y on <date>, because Z`. A status line that cannot name who agreed is a
silent overturn that has not been noticed yet.

## A parked option comes back as a question, never as a plan

**A future complaint is not advance approval of the fix somebody parked against it.** A complaint
says the design has a problem. It says nothing about which parked option is the answer, or whether
the answer is any of them, and the player who says the sentence is describing an experience rather
than picking off a menu they cannot see.

So when parking something, record **what it was and why it was not taken**, and record the symptom
as *what would make this worth discussing again*. **Never as what would authorise it.**

**Every idea a design discussion sets aside or leaves undecided is kept, out of the way until
research looks for it** (curly-moose #829, #831): the player's own ideas, the agent's, a study's,
the rejected ones too, each with whose it was, why it was set aside or left open, and what would
make it worth discussing again. *Proposed by the filer, open to overturn:* they go in a record of
their own name under `docs/decisions/` (`tools/new-name.sh decision "<title>"`, never `--entry`,
since a record named after an entry is that entry's build record and lets CI accept its items'
deletion), which the entry it was weighed for names; `tools/decisions.sh` finds it during research,
while it stays out of the queue, unlike an entry in the `parked` band, and out of every session's
context until then.

## Evidence lives in the repo

**Every log, telemetry map or screenshot a doc points at gets copied into `docs/evidence/` in the
same commit as the sentence that points at it.**

`user://telemetry/` is a **scratch directory the player has to be able to empty**, and nothing
prunes it — every `tools/shot.sh` and `tools/check.sh` run adds to it and the game deletes none of
it, so emptying it is the player's routine maintenance. A finding whose evidence lived only there
stops being checkable on a perfectly ordinary Tuesday.

Evidence cannot be recovered by replaying: **a run log that records a player's relevant actions is
not a function of the seed.** Regenerating gives a different run with the same city, so retain that
log when the actions or their order support the finding.

**Copy only the run artifacts relevant to what the playtest or rig was meant to show.** Keep every
artifact needed to support the claim and its limits, including relevant player evidence,
contradictory results and failed trials. Omit unrelated automatic pictures, routine boot output,
logs that do not support the claim or its provenance, and redundant copies. A log belongs when it
proves the actual behavior, preserves non-replayable player input, diagnoses a relevant failure or
supplies provenance that is not recorded elsewhere.

The evidence folder's README or manifest records enough context to interpret and reproduce the
selection: the source revision, command and settings, and the seed and timing when they matter,
plus the claim and its limits. When selected artifacts come from
`user://telemetry/<day>/<run>/`, keep them under the run folder's original name, which carries its
time, seed and commit; the README or manifest makes explicit which files were selected and why.

## A playtest is a scarce resource

**Do not ask for one on a build known to be incomplete.** A half-finished build spends the player's
nerves rediscovering things already written down, and the report that comes back is
indistinguishable from the project not having listened.
