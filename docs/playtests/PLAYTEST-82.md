# Playtest 82 — 2026-09-19

Said in conversation on 2026-09-19, with no run attached. It answers the question
[PLAYTEST-80](PLAYTEST-80.md) left open about resuming a game — what *"that exact state"* has
to cover inside a day — and the answer moved while it was being given, so every sentence is
kept in the order it was said.

## What a resumed game comes back to

The question put to the player offered three answers: everything, including each walker and
car; everything but the crowd, which would be re-seeded around her as at dawn, recommended; or
the run and the day only, resuming at that day's dawn.

> "Include everything in the state. We don't want to be able to cheat by closing the window and
> restarting from a safer position"

> "Like if I walk in front of a car I shouldn't be able to quit and resume without the car being
> there"

> "If that is too hard then we do start at dawn. But that has a potential to be exploited"

> "Unless we give a penalty of ending the current day losing a nerve"

> "No penalty when exciting at a next day/win/lose screen" — corrected at once to "Exiting"

> "I guess we can do it that way"

Asked which of the two gets built — the exact snapshot with dawn as its fallback, or dawn with
the nerve penalty — the player chose **dawn with the nerve penalty**.

*Asked for "that exact state" on 2026-09-19 (playtest 80) and for everything in the state, the
crowd included · overturned by the player the same day to a restart at dawn that costs a nerve,
because the exact snapshot is the largest option and the penalty closes the same exploit.*

What is asked for, as statements:

- **The requirement underneath both answers is that quitting is never an escape.** Closing the
  window in front of a car, or with the meter about to fill, must not hand back a safer
  position. The recommended middle option failed exactly this, which is why it was refused.
- **A save holds the run and the day, not the moment.** A game closed in the middle of a day
  comes back at that day's dawn.
- **Coming back from the middle of a day costs what losing it costs**: the day ends and a nerve
  goes, as a lost day does.
- **Closing at a next-day, win or lose screen costs nothing.** The day is over there, so there
  is nothing to escape from.

What the exact snapshot would have been, recorded so it is not designed a second time: her, both
meters, the day's clock, every event instance, pursuits, the errand, each of some two hundred
walkers and the cars with their lanes, turns in progress, queues and signal phases, and the
random state — with every later change to the crowd owing the save format its compatibility.
What would make it worth discussing again is the penalty reading as unfair in play: a nerve
lost to a browser crash or an accidental tab close.

## An agent never lands in a saved game

> "Also make sure that agents don't accidentally work on saved states so they don't get
> confused"

Every checkout of this project — the player's folder and each agent's worktree — shares one
`user://` directory, so the player's save is in reach of any game an agent starts. An agent
that opened it would capture or measure the player's day 9 while believing it had started
day 1, and would overwrite the player's save on the way out. M162's entry already says a
dev-flagged run never resumes and never saves; this widens it to every way an agent starts the
game: the test runner, `tools/check.sh`'s boot, a headless run, and a `tools/run.sh` with no
other flag, which gets a flag of its own to say so.

## A save shows itself

> "Also show a small save symbol for a few seconds after saving" — "That way it's clear when a
> state was saved"

Saving is implicit, so nothing else tells the player it happened. A small symbol appears for a
few seconds each time the save is written. It is not a danger cue and names no key; it is
drawn as an SVG first, like every other picture.

Two details the first answer left open, decided in `TODO.md` under M162 and open to overturn: losing
focus and then continuing in the same session costs nothing, since nothing was escaped — the
penalty belongs to *opening* a game whose save says a day was under way; and the save is
written at dawn and at each day's end as well as on focus loss and quit, since a process that
is killed never gets to write its quit save, and a penalty that a force-quit avoids is no
penalty.
