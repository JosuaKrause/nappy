# Handoff

**Where to pick up.** This file says what is true right now and what to do next. It holds no
history — that is [DECISIONS.md](DECISIONS.md), fetched when you need to know *why* — and no
progress-tracking, which lives there too.

**Read this, then [TODO.md](TODO.md).**

## The state of the tree

`main` is green and playable; no branches are open; nothing is half-built. Trust the tools over any
sentence here:

```sh
./tools/test.sh          # the full headless suite, ~200s; must be 0 failures
./tools/check.sh         # boots the project, fails on any script error
./tools/run.sh           # plays it
./tools/telemetry.sh     # what the last run actually did, in order
```

A filtered run (`./tools/test.sh crowd events`) prints `PARTIAL RUN` and is not a green build.

## What to do next

The order, set on 2026-09-01. Each entry's full brief is in [TODO.md](TODO.md); the design work
behind the newest one is in [PLAYTEST-18.md](PLAYTEST-18.md).

1. **M55's resistance half** — designed, nothing open. The hold goes, a task becomes two steps,
   five tasks, every mark guarded.
2. **M53** — a junction is made of the streets that meet at it.
3. **M54** — the robber stops at walls, and three rows that never arrive.
4. **M56** — the resistance is noticed.
5. **M59 — the chatting mother.** A 5-second conversation that costs 25 excitement awake and only
   time asleep. Position in the order is provisional; the design is the player's.

## Open beyond the order

Unordered, reassessed 2026-09-01, full entries in [TODO.md](TODO.md): **M50** (the corridor's
density is a catalogue question; placeholders step 3; the four-street building), **M47** (the 2×2
courtyard complex; calm-area adjacency; multi-block calm re-derived for 121 blocks; the main road
as a soft block), **M45** (closures that point), **M48** (bodies drawn wider than their pavement),
**M43** (the tutorial dog after day 3; the one-contact cliff at 90; `RUN_TAUGHT_DAY` 3 → 2),
**M49** (the fence, the vanishing border-walkers), **M25** (patrols for the empty acts), **M26**
(teaching the controls), a shortlist of small items, and **M10** (polish, now including a web
build).

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
  `--day-length`, `--screenshot`, `--after`, `--walk`, `--flee`, `--press`, `--ending` ship in the
  build. They should be gated behind a debug build before release.
- **There is no main menu.** There is a title screen — the doorstep with the traffic and the events
  running behind it, `space` to begin — but it is a title, three lines of controls and two keys: no
  options, no seed box, no load game.

## The rule that matters most before starting anything

**The first tool call of a design task is a search for the words, not a plan.** Grep `TODO.md` and
the playtest files for the noun. Three separate things in one session turned out to be already
written down and never built — the interact key (filed in playtest 02), the alley roulette, and M40
itself. The code is evidence of what was built; it is never evidence of what was agreed.
