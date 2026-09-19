# Playtest 85 — When the save is written, and the designs for what playtest 84 found

**Date:** 2026-09-19

Said in conversation, with no run attached. It answers the three questions
[PLAYTEST-84](PLAYTEST-84.md) left open — the basement stairs, the steam, the pathing — and
changes when the save is written and what a saved game opens onto.

## What the player said

> "write the save when starting a day; not when the focus is lost etc. also if there is a saved
> game the title screen should go to the day brief screen instead of starting outright. the
> spawning shouldn't be a check. the pathing should start from the position. then obstacles can
> never happen. basement stairs are just not stairs. at the very least use the one tile upward
> facing stairs we had earlier. how would steam move? it doesn't make sense. have multiple fixed
> locations with steam that fully block the path and have them turn off an on in different
> intervals so it becomes a timing puzzle."

## What is asked for, as statements

### The save

- **The save is written when a day starts, and not on focus loss.** *Asked for "saving should be
  implicit (on focus loss or game quit)" on 2026-09-19 ([PLAYTEST-80](PLAYTEST-80.md)) ·
  overturned by the player the same day to a write when a day starts.* *"etc."* is read as the
  quit write as well.
- **With a saved game, the title screen leads to the day brief screen rather than straight into
  the day.** The title comes up on every boot; pressing start with a save on disk shows the day
  brief — the screen between days that `DaySummary` draws, with the day, the nerves and the
  resistance's brief on it — and continuing from there starts the day. Today a resumed boot
  skips the title and opens the pause screen over the day instead.

**One collision, asked of the player rather than inferred.** [PLAYTEST-82](PLAYTEST-82.md) says
*"No penalty when exiting at a next day/win/lose screen"*. If the *only* write is at a day's
start, a game closed on the summary of a day she has just won still holds that day's dawn save,
so reopening it replays the won day and charges the nerve a day left unfinished costs. Keeping
that sentence true needs a second write when a day ends.

### The service exit

- **Where she comes out is not checked against obstacles; the pathing starts from where she is
  put.** *"the spawning shouldn't be a check. the pathing should start from the position. then
  obstacles can never happen."* The finale's routes are planned from her actual position at the
  service exit, and everything the finale places is placed relative to those routes, so nothing
  can stand on her by construction. A check that rejects or moves a bad spawn is the rejected
  option.

### The basement's stairs

- *"basement stairs are just not stairs."* The two diagonal tread cells do not read as a stair
  at all.
- **The floor of what is acceptable is the one-tile stair the kit had earlier**:
  `assets/interior/stair_down.svg`, a single 32×32 tile seen from the front, treads drawn as
  horizontal lines narrowing away from her, which matches the player's own basement sketch in
  [PLAYTEST-55](PLAYTEST-55.md) — *"horizontal lines indicate a small stair leading down"*. It
  was removed when the diagonal tread kit replaced it. *"at the very least"* leaves a better
  stair open.

### The steam

- *"how would steam move? it doesn't make sense."* The drifting steam goes.
- **Several fixed vents, each fully blocking the corridor while it is on.** Not a lane to thread:
  while a vent blows there is no way past it.
- **Each turns on and off on its own interval, the intervals differing**, so the corridor is a
  timing puzzle: she waits for a gap and goes, and the gaps of successive vents do not line up
  by themselves.
