# Handoff

**Where to pick up.** This file says what is true right now and what to do next. It holds no
history — that is [DECISIONS.md](DECISIONS.md), which is fetched when you need to know *why*.

**Read this, then [TODO.md](TODO.md).**

## The state of the tree

`main` is `f17db54`, green and playable. Nothing is half-built. One branch is open —
`feature/timeless-docs`, which is M40.

```sh
./tools/test.sh          # 179912 checks, 0 failures, ~200s
./tools/check.sh         # boots the project, fails on any script error
./tools/run.sh           # plays it
./tools/telemetry.sh     # what the last run actually did, in order
```

A filtered run (`./tools/test.sh crowd events`) prints `PARTIAL RUN` and is not a green build.

## What to do next

### 1. M40 — the docs say only what is true · in progress, `feature/timeless-docs`

**The player's instruction is that this comes before any other implementation.** Two jobs, and the
restyle is the smaller one: a correctness pass that finds sentences no longer true, and a style pass
that puts everything in the present tense with the history moved to `DECISIONS.md`.

**Done:** `DECISIONS.md` exists and holds the history; `HANDOFF.md` and `TODO.md` are the current
state and the queue; `CLAUDE.md` is a 132-line index over eleven skills in `.claude/skills/`, one
per operational task, each loaded before that task.

**Left, and this is the next thing to pick up:** the timeless scan of the code comments and the
design docs. `tuning.gd` is done as the worked example (113 → 79 references); **556 references
across 45 source files** and about 240 across `EVENTS`, `CITY`, `MECHANICS` and `TELEMETRY` remain.
The file-by-file counts and the method are in `TODO.md` under M40, "Next step".

It is a judgment call per block rather than a find-and-replace: **keep the reason a thing is the way
it is and the trap that makes it easy to get wrong; drop the milestone number, the former value and
the narration of the fix.**

**And re-audit the numbers separately afterwards** — a stale claim survives a rewrite perfectly well
if nobody checks it against the code.

### 2. M55's resistance half — designed, not built

Everything else in M55 is done. The resistance work is fully specified and has nothing open:

- **The hold is gone.** Touching a mark completes it. `E` comes out of `project.godot`,
  `contact_point.gd`, `tests/test_resistance.gd`, `docs/MECHANICS.md` and `docs/ARCHITECTURE.md`.
- **A task is two steps** — pick up the instruction, perform it the next day — so the day brief
  carries the resistance's words and is the mechanism rather than a courtesy. The first mark is day
  4; the calendar in the entry is exact.
- **Five tasks**: the yeller, the package carried home, the checkpoint, the poster crew's wall, the
  protest. All five need one shared piece of plumbing — a contact that rides on an `EventInstance`
  rather than on a tile.
- **Every mark is guarded** by an `alley_robbery` standing 66–176px off it, which is the band its
  own radii fix. Which side she approaches from decides whether he wakes.

### 3. M53 — a junction is made of the streets that meet at it

The lattice draws a full crossroads wherever two corridors cross, whether or not the arms are
streets. One arm is the sea; others open onto precinct paving and park grass. The crowd walks all of
it and vanishes where somebody is looking. `CityMap.absent_segments`, `built_over` and the map edge
already say which arms exist — nothing that draws a junction asks.

### 4. M54 — the robber stops at walls, and three rows that never arrive

A pursuing `EventInstance` moves by setting its own position, and nothing in the event system
collides with the city. Plus `cyclist`, `loose_dog` and `cat_dash`, whose whole content is a moving
thing meeting her, and which never do. Its resistance bullet is absorbed by M55.

### 5. M56 — the resistance is noticed

The city gets more dangerous the further into the subquest you are. Two rungs: `police_patrol`
escalates without ever killing, the abduction van escalates and does. Two precedents it sets and
does not resolve — the first authored event with a **victim**, and a lethal field that **follows
her**, which is the one shape M28's spacing rule cannot be stated about.

## Older items still open

- **M25** — patrols for acts III and IV, where the streets are deliberately empty and the threat
  should follow rather than sit.
- **M26** — teaching the controls. Its first half (deleting the interact key) is M55's.
- **M43's last two** — the pursuit cool-off and dying at high excitement on a quiet street. Both
  need a played run.
- **M48**, **M10** (polish), and M50's step 3 (placeholders as a variety ledger).

## What to distrust

What is untested by a human, listed so nobody mistakes arithmetic for a verdict.

- **The difficulty has been felt by a human once**, and that was a verdict on one density pass and
  one act I. The sleepiness numbers, the nerve economy, and whether the arterial is crossable are
  all still arithmetic checked by `tests/test_balance.gd` and unfelt. **Nobody has ever got past day
  4**, so the whole of acts II–IV is seen by nobody.
- **Five nerves is a number nobody has played against.** It was raised from three after a run ended
  on day 3 — but two of those nerves went on a **defect**, so the number was raised against a
  difficulty that no longer exists.
- **A spoiled park is nine things and nobody has stood in one.** The coverage is measured — 91% of a
  courtyard, 99% of a four-block zone — and what is not measured is whether it reads as *the park is
  busy today* or as somebody having tipped an event budget into a field. It is also the one place
  where `EVENT_SPACING_SAME` does not apply.
- **The robber and the pacing man have never been met by a person.** The robber is the most
  mechanically complicated row in the catalogue — a field, a trigger, a notice, a stand-off and a
  break-off — and every number on him is a rig's. The pacing man is a man with no body on a 64px
  footway, avoided by the meter alone.
- **A street that is solid has been walked by a rig and by nobody.** About two thirds of the
  catalogue has a body. The open question is not density but whether being stopped reads as *cross
  the street* or as an obstacle course. The gap between a kerbed van and the frontage is smaller
  than the pram, which is intended and is also the exact shape of *"no line to walk"*.
- **Most of the silhouettes have never been seen in play.** Only five are reachable before day 4.
  The two to distrust are the ones that are more than a picture: the **robber's two postures**,
  where the whole claim is that *waiting* and *coming* are told apart at an alley's length, and the
  **protest**, a 110px wall of bodies on a crossing.
- **A flock has been walked through by a rig and by nobody.** The gradient is measured — +35 through
  the middle, +8 eighty pixels off it, nothing at the rim — and it is the only row where the cost
  table and the thing the player meets are computed differently.
- **Calm ground is more than twice as fast as anybody has played it.**
  `SLEEPINESS_CALM_ZONE_MULTIPLIER` is 21 and a four-block zone fills the meter in **11.3s from
  empty**, against a 10.8s lap of one. That margin is what decides whether a day is winnable once
  the park is reached, and the last human verdict on the difficulty was given when the same
  constant was 12.
- **There is no audio at all.** Less urgent than it sounds: audio is redundancy, so the game must
  already be fully playable without it.
- **Dev flags are always on.** `--seed`, `--day`, `--spawn`, `--follow`, `--meters`, `--overview`,
  `--day-length`, `--screenshot`, `--after`, `--walk`, `--flee`, `--press` ship in the build. They
  should be gated behind a debug build before release.
- **There is no main menu.** There is a title screen — the doorstep with the traffic and the events
  running behind it, `space` to begin — but it is a title, three lines of controls and two keys: no
  options, no seed box, no load game.

## The rule that matters most before starting anything

**The first tool call of a design task is a search for the words, not a plan.** Grep `TODO.md` and
the playtest files for the noun. Three separate things in one session turned out to be already
written down and never built — the interact key (filed in playtest 02), the alley roulette, and M40
itself. The code is evidence of what was built; it is never evidence of what was agreed.
