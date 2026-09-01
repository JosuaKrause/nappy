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

The order is in `TODO.md`'s M40 entry and is by where a reader lands: `DECISIONS.md`, then this
file, then `CLAUDE.md`, then the design docs, then the docstrings, then `TODO.md`.

The size, measured: 590 history references across 45 of 56 source files, 141 in `CLAUDE.md`, 528 in
the design docs, about a thousand in `TODO.md`.

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

## The rule that matters most before starting anything

**The first tool call of a design task is a search for the words, not a plan.** Grep `TODO.md` and
the playtest files for the noun. Three separate things in one session turned out to be already
written down and never built — the interact key (filed in playtest 02), the alley roulette, and M40
itself. The code is evidence of what was built; it is never evidence of what was agreed.
