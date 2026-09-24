---
name: playtest-feedback
description: How to handle playtest feedback and design decisions — write it down in full before building, search the repo before designing, never silently overturn what the player asked for, and how a parked option comes back. Load this BEFORE responding to any playtest, design instruction, or request that changes what the game does.
---

# Feedback and decisions

## The first tool call of a design task is a search, not a plan

**Search `docs/TODO.md` and the playtest files for the thing being asked** — not for a milestone
number, for the *words*. `grep` the noun. A request that has been made before is already written
down in the player's own sentence, usually with the measurement, the constraints and the three
things to get right sitting under it.

**And search the docs before believing the code.** The code is evidence of what was **built**; it is
never evidence of what was **agreed**. A decision can sit written down and unbuilt for twenty
milestones, and a session that checks only `src/` will confidently tell the player their own
decision never happened.

**A code comment is positive; the queue is normative.** *(2026-09-24, playtest 128: "The code
comment is positive, the queue is normative. The code only describes what is, not what should
be. That's a general rule.")* A docstring saying a thing "takes no picture" or "is drawn in code"
describes what was built, however deliberate it sounds; it is never a decision that competes with
`TODO.md`. Where the two disagree, build what the queue says and rewrite the comment with the
code. That disagreement is not an open question for the player.

Two costs, and the second does the damage:

- **The player pays to say it again.** Every re-report is time spent describing something the
  project already agreed to, and it is indistinguishable from the project not having listened.
- **A question goes back that the repo could have answered.** Asking is right when the answer does
  not exist; asking when it does is the overturn rule's shape in miniature.

When a finding turns out to be a re-report, **say so in the entry and close it *from* the older
one** rather than writing a second design for it — two entries for one request is how the next
reader loses the half with the measurement in it.

## Write it down with all of its detail, before doing anything about it

**Every piece of playtest feedback goes into `docs/playtests/PLAYTEST-NN.md` in full — the player's own words,
and every specific they gave — before a line of code is written.** Then it becomes a `docs/TODO.md`
item, and only then does it get implemented.

The failure mode is specific and it is not laziness: **a finding arrives as a complaint plus a
design**, the complaint is the part that is easy to restate, and the design is the part that took
the player thought. **Record the design even when you are about to fix the complaint**, and record
it even when you disagree with it — a note saying "asked for X, built Y instead, because Z" is a
decision somebody can overturn. Nothing else is.

The test of whether it was written down is not "did I mention it" — it is whether **somebody opening
the repo cold could build the thing that was asked for** from what is on disk.

**A playtest also closes what it covered in `docs/REVIEW.md`.** That file is the list of things
waiting on a person; when a run has looked at one, the verdict is in the playtest file and the
item leaves the list in the same commit, whether the verdict was *fine* or a new finding. An item
that stays after its run has been played is asked for twice.

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

## Evidence lives in the repo

**Every log, telemetry map or screenshot a doc points at gets copied into `docs/evidence/` in the
same commit as the sentence that points at it.**

`user://telemetry/` is a **scratch directory the player has to be able to empty**, and nothing
prunes it — every `tools/shot.sh` and `tools/check.sh` run adds to it and the game deletes none of
it, so emptying it is the player's routine maintenance. A finding whose evidence lived only there
stops being checkable on a perfectly ordinary Tuesday.

Evidence cannot be recovered by replaying: **a run log is a record of what a player did, so it is
not a function of the seed.** Regenerating gives a different run with the same city.

**Copy the whole `<run>/` folder under `docs/evidence/`.** A run *is* a folder —
`user://telemetry/<day>/<run>/`, holding `run.log` and its `maps/`, `auto/` and `asked/`
pictures — and **the run folder's own name carries the time, the seed and the commit**, since no
single file inside it does. That name is self-describing on purpose, so the copy does not need its
`<day>/` ancestor to be identifiable. A lone picture lifted out of it is evidence with its
ancestry left behind: nothing in the copy says which run it came from or what the code was when it
was taken.

## A playtest is a scarce resource

**Do not ask for one on a build known to be incomplete.** A half-finished build spends the player's
nerves rediscovering things already written down, and the report that comes back is
indistinguishable from the project not having listened.
