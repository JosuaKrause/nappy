# Handoff

**Where to pick up.** This file says what is true right now and what to do next. It holds no
history — that is [DECISIONS.md](DECISIONS.md), fetched when you need to know *why* — and no
progress-tracking, which lives there too.

**Read this, then [TODO.md](TODO.md).**

## The state of the tree

**`main` is green and playable, and one feature branch is open with M56 half-built on it** —
`git branch` names it, and M53's carriageway work has landed on the same branch. Nothing is broken
and nothing is half-written: the branch's items are each finished and committed, and the milestone
simply has items left. Trust the tools over any sentence here:

```sh
./tools/test.sh          # the full headless suite, ~200s; must be 0 failures
./tools/check.sh         # boots the project, fails on any script error
./tools/lint.sh          # the governed docs, for sentences that go stale on their own
./tools/run.sh           # plays it
./tools/telemetry.sh     # what the last run actually did, in order
```

A filtered run (`./tools/test.sh crowd events`) prints `PARTIAL RUN` and is not a green build.

**There is a GitHub remote** (`origin`), and completed work may be pushed to it without asking —
see the **committing** skill for what *completed* means. `main` may never carry an unfinished
milestone.

## What is on the open branch

**M56's mechanism and its non-lethal rung.** A row declares how it answers to the resistance with
`EventDef.heat_response` — `NONE`, `PRESSES` or `HUNTS` — and `EventCatalogue.heated(def, level)`
derives that row's shape at a progress level and keeps it. Because progress is a bounded integer,
**every heated shape of every row is validated on boot**, which is the only way the fairness
contracts can be about the dangerous version of an event rather than the harmless one.
`EventScheduler.build_day()` takes the heat as an argument, so a rig can plan a fully heated day
without a run having happened.

**Both upper rungs of the ladder are built.** `police_patrol` carries `PRESSES`: more of them, more
expensive to stand near, and from half progress it **investigates** — a pursuer that also has a
route runs the route until it notices her, then follows. It never becomes lethal at any heat.
`abduction` carries `HUNTS`: while she is close enough to watch, it takes a bystander of its own —
a scripted figure the event draws, never a `CrowdAgent` — and past three of four it stops idling for
strangers and comes after her instead, at 130px/s from a 180px trigger, still `hard_fail`.
`tests/test_heat.gd` asserts both over the response rather than over the rows that carry them.

**A pursuer is exempt from the rule that nothing else happens inside a lethal event's field**, and
the exemption is stated over `pursues` rather than holding by accident of the `WALL` role.

## What to do next

**The game is published.** `https://nappy.josuakrause.com/` serves it, and
`.github/workflows/deploy.yml` rebuilds and republishes on every push to `main` — gate, export,
upload, publish, in that order, so a red build never reaches the site. **A merge to `main` is now a
release**, which is the one thing to know before making one.

**Start with [PLAYTEST-19.md](PLAYTEST-19.md).** It is a played run on the deployed build, nine
findings, and it is the freshest thing in the repo. Its findings are already filed against the
milestones that own them.

1. **M64 — nothing off the path.** The largest of the nine and the one the game is most about: every
   event in the catalogue is a reason to cross the street and none is a reason not to go somewhere,
   so the corridor is cheapest and nothing off it is dangerous. **Design the rows before placing
   anything** — that order is the instruction, not a preference.
2. **M65 — the chalk mark.** It is announced before it is found and cannot be found once it is
   announced. Two halves of one thing.
3. **Finish M56** — "other dangers like this", then the measurement against the nerves.

M53's remaining piece is a drawing: nothing goes into a precinct now, and **nothing draws a
bollard**, so a street that meets one simply stops. It is stated in [TODO.md](TODO.md) under M53.

## Open beyond the order

Unordered, full entries in [TODO.md](TODO.md): **M61** (fields as ellipses whose eccentricity comes
from movement speed), **M62** (checkpoints and barricades dividing the map into regions), **M50**
(the corridor's density; placeholders step 3; the four-street building), **M47** (the 2×2 courtyard
complex; calm-area adjacency; multi-block calm re-derived for 121 blocks; the main road as a soft
block), **M45** (closures that point), **M48** (bodies drawn wider than their pavement), **M43**
(the tutorial dog after day 3; the one-contact cliff at 90; `RUN_TAUGHT_DAY` 3 → 2), **M49** (the
fence, the vanishing border-walkers), **M25** (patrols for the empty acts), **M26** (teaching the
controls), a shortlist of small items, and **M10** (polish).

## What to distrust

What is untested by a human, listed so nobody mistakes arithmetic for a verdict.

- **The whole of the heat is unfelt.** Every number in it was set by design and checked by a rig:
  nobody has walked a city at full resistance progress, and the item that would tell you whether it
  is fair — measuring it against the five nerves — is the one still queued. It makes the back half
  harder *precisely for the player doing well at the optional path*, and **nobody has ever reached
  act III**.
- **An investigating patrol has never been seen.** The claim is that a police car breaking off its
  route to follow her reads as *being noticed*. That is a screenshot question and no screenshot has
  been taken.
- **The van's victim reads as a man standing next to a van.** A screenshot of the scene is in
  `docs/evidence/` and it is the weaker of the two taken: the figure is upright and unheld, so the
  whole of *being taken* is carried by it walking in and disappearing over 2.5 seconds, which a
  still cannot show and nobody has watched. The hunting half came out better — end-on, closing,
  and not comic.
- **A hunting van drives along the footway.** A pursuer steers straight at her over any walkable
  tile, which every pursuer in this game already does; this is the first time the thing doing it is
  a van. Whether that reads as menace or as a bug is a question for somebody watching it.
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
- **Nobody has measured the web build, only confirmed it runs.** It boots and plays at the live
  address; what has not been checked is frame rate at the game's scale on a machine that is not the
  one it was built on, and whether a stranger arriving at the page understands what it is.
- **The touch controls have never been touched.** The stick and the run button are built, tested and
  screenshotted on a desktop — which proves only that they stay *off* where they should. Whether a
  thumb can hold the 20px line between two pavement lanes, whether the catch radii feel right, and
  whether `RUN` is legible at phone DPI are all unknown. The landscape declaration is inert in an
  ordinary browser tab: it lives in a PWA manifest that is not written unless the full PWA export is
  turned on.
- **There is no way to open the pause on a touch-only device.** `pause` is bound to a key alone, and
  nothing draws an on-screen button for it, so a phone player reaches the pause screen only when the
  between-days summary brings it.
- **There is no main menu.** There is a title screen — the doorstep with the traffic and the events
  running behind it, `space` to begin — but it is a title, three lines of controls and one key on
  the web (two on the desktop, where `q` also quits): no options, no seed box, no load game.
- **Nothing draws a bollard**, so a street that meets a precinct simply ends against the paving. The
  city and the crowd both explain a precinct by saying a driver meets a bollarded street, and there
  is no bollard anywhere in the game.

## The rule that matters most before starting anything

**The first tool call of a design task is a search for the words, not a plan.** Grep `TODO.md` and
the playtest files for the noun. Three separate things in one session turned out to be already
written down and never built — the interact key (filed in playtest 02), the alley roulette, and M40
itself. The code is evidence of what was built; it is never evidence of what was agreed.

**And the second rule is that the plan is yours and the implementation is an agent's.** The
**orchestrating** rules load at the start of every session and say when that is not true.
