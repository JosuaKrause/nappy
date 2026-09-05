# Handoff

**Where to pick up.** This file says what is true right now and what to do next. It holds no
history — that is [DECISIONS.md](DECISIONS.md), fetched when you need to know *why* — and no
progress-tracking, which lives there too.

**Read this, then [TODO.md](TODO.md).**

## The state of the tree

**`main` is level with `origin/main` and nothing is half-written in its working tree.** `git branch`
and `git worktree list` are the truth about what is open.

One branch is unmerged and that is deliberate rather than in progress: **M64's measurement probes,
`tests/test_zz_m64_measure.gd` and `tests/test_zz_m64_density.gd`, are kept off `main` on a branch
of their own** so that *measure it again afterwards* means running the same thing rather than
reinventing it. They are the only files on it, they print rather than assert, and they are the
instrument the per-street density figures in `TODO.md` were read with.

Merge one at a time, `--no-ff`, and rerun the full gate on the merged tree between merges.

```sh
./tools/test.sh          # the full headless suite, ~200s; must be 0 failures
./tools/check.sh         # boots the project, fails on any script error
./tools/lint.sh          # the governed docs, for sentences that go stale on their own
./tools/run.sh           # plays it
./tools/telemetry.sh     # what the last run actually did, in order
```

A filtered run (`./tools/test.sh crowd events`) prints `PARTIAL RUN` and is not a green build.

**`check.sh`'s import pass rewrites `docs/ARCHITECTURE.md`'s file tree as a side effect**, turning a
run of spaces into a tab on whichever lines it feels like — the file's tree is indented with spaces
and it converts some of them every time. It is not a one-off; it has happened in three separate
sessions. **Run `git status` after `check.sh` and revert anything you did not mean to change**,
rather than assuming only the files you touched moved.

**The game is published, and a push is a check while a tag is a release.**
`https://nappy.josuakrause.com/` serves it. `.github/workflows/ci.yml` runs lint, check and the full
suite on every push and every pull request; `.github/workflows/deploy.yml` fires on a `v*` tag and
nothing else — gate, export, upload, publish, in that order, so a red build never reaches the site.
It re-runs the gate rather than trusting CI, because both workflows fire on the same push and neither
waits for the other, and because a tag can point at any commit.

**Cut a release with `tools/release.sh <major|minor|patch>`**, which reads the latest version tag and
prints what it would do. It only acts when given a second literal `push` argument, and it refuses a
dirty tree, any branch but `main`, and a `main` that is not level with `origin/main` — every refusal
fires in the dry run too, so the dry run tells the truth about whether the real thing would work.
Semver, and **`major` is reserved for a change that breaks or fundamentally alters the game**.

So pushing `main` no longer publishes. Completed work may be pushed without asking; see the
**committing** skill for what *completed* means. **Publishing is a separate, deliberate act**, and
the live site is whatever the newest tag pointed at — `git tag --list 'v*'` and `tools/release.sh`'s
own dry run say which. **The site currently serves a build nobody has played**: the sealed city and
everything under "What to distrust" reached it by measurement, not by a played day.

## What to do next

**The most useful thing anybody can do next is play a day.** Every finding of playtest 22 is built
and none of it has been walked: the sealing that closes the city off the path, the trunk that keeps
the doorstep joined to it, the ban on routing along the main road, and the thinning that leaves a
wrong turn open. It is arithmetic and rig runs all the way down, and the questions it raises —
*does a walled city read as a route decision or as a maze*, *is a thinned wall an invitation or a
mistake* — are the kind only a person answers.

**Read [PLAYTEST-22.md](PLAYTEST-22.md), then [PLAYTEST-21.md](PLAYTEST-21.md), then
[PLAYTEST-20.md](PLAYTEST-20.md)** for what has already been said about this ground. Playtest 21 is
a brief run whose complaint — the city *"feels way empty"* — the sealing answers. Playtest 20 is the
full seven-day run behind them, and its findings are filed against the milestones that own them.

**Read `DECISIONS.md` under M69 before touching routes, closures or the corridor**, because it
changed the ground every one of them stands on. Reachability is now `ReachabilityGrid` — the tile map
contracted into two-tile cells, one node per connected component of a cell's walkable tiles — the
day's route tree grows on it, and `ClosurePlanner` refuses a calm area's access streets outright.
`StreetNetwork` is still there and still owns the lattice and the structural route count; it is no
longer what answers *can she get there today*.

1. **M64 — off the path is closed, not dear.** **Its sealing is built**: `SealPlanner` puts a seal on
   every real street off the day's route tree, so the city can say *not this way at all* for the
   first time and the route decision stops having one correct answer. Off-path density measures
   0.330 events per street before and 2.173 after, with the on-tree figure unmoved; the record is in
   `DECISIONS.md` under M64.

   **Its fairness is now checked rather than hoped for.** The day's tree grows a trunk from the
   doorstep out to the nearest cell already on it, so the join between home and the corridor is tree
   ground and cannot be sealed; no branch is ever planned *along* the main road, though crossing it
   is free; and `tests/test_seals.gd` asks whether a calm area is reachable **with the whole main
   road removed**, because reachable along the spine — 0.6 excitement decay against an ordinary
   street's 1.0 — is not survivable. A fraction of the soft seals is dropped one body at a time so
   the guidance stops reading as guardrails. The record is in `DECISIONS.md` under M64.

   What is left is the eight seal pictures — variety, so no single barrier becomes the city's
   signature, each costing one appended candidate and no code — and the off-screen arrivals item.

   **Hard seals are act IV only**, because `barricade` is the sole catalogue row wide enough to span
   a street; days 1–11 seal soft, both pavements taken with the carriageway still walkable. Three of
   the eight pictures are act-I hard seals and are what closes that.
2. **M65 — the chalk mark.** Still the same two-part gap from playtest 19 — announced before it is
   found, unfindable once it is — with a third item added from playtest 20: a protester pointing
   toward the current objective, and made more common since a protester obstructs nothing.
3. **M56 — the resistance is noticed.**

**The instrument to judge any of it with now exists and was used this session.** The dusk map draws
the walk over the plan: where she went, which stretches she ran, and which events actually reached
her, against the corridor the day expected her to take. `docs/TELEMETRY.md` says what it draws.
Playtest 20's evidence is fourteen of them, one day and one dusk map for all seven days of a run —
read alongside the run's own log, they are what turned "barriers don't work" into the specific,
citable numbers now in `TODO.md` (the day-4 `charging_dog` killing her in 0.8s against every other
encounter's 1.5s; the chalk mark going unfound on all four days it existed, `resistance 0/4`). **A
rig can walk a route now**, so a picture of a specific route is cheap: `--walk` takes a script of
timed presses — `--walk 3s15e` is three seconds south then fifteen east — and the same script on the
same seed walks the same way every time.

M53's remaining piece is a drawing: nothing goes into a precinct now, and **nothing draws a
bollard**, so a street that meets one simply stops. It is stated in [TODO.md](TODO.md) under M53.

## Open beyond the order

Unordered, full entries in [TODO.md](TODO.md): **M61** (fields as ellipses whose eccentricity comes
from movement speed), **M62** (checkpoints and barricades dividing the map into regions), **M50**
(the corridor's density; placeholders step 3; the four-street building), **M47** (the 2×2 courtyard
complex; calm-area adjacency; multi-block calm re-derived for 121 blocks; the main road as a soft
block), **M45** (closures that point), **M43** (the tutorial dog after day 3; the one-contact cliff
at 90; `RUN_TAUGHT_DAY` 3 → 2), **M49** (the fence, the vanishing border-walkers), **M68** (tap to
walk as a switchable experiment), **M60**'s last two (the home arrow under a thumb, the browser smoke
pass), **M25** (patrols for the empty acts), **M26** (teaching the controls), a shortlist of small
items, and **M10** (polish).

## What to distrust

What is untested by a human, listed so nobody mistakes arithmetic for a verdict.

- **The city is walled off the path and nobody has walked it.** About 369 seal bodies a day stand on
  the 187 streets the day's tree does not use, and a day now plans four to five hundred events where
  it used to plan a hundred and thirty. Everything about it is measured and none of it is felt.
  **The specific worry, from a rig:** walking blindly away from the route on seed 2102613802, day 6
  meets a wall at the second street, cannot move for thirteen seconds, and loses the day at 17.6s
  with excitement at 100 — and the log says `crowd 28.0/s, events 0.0/s`, so it is the crowd shoving
  a stopped player, not the seals. A player who routes would not stand there. It is still the first
  time the wrong direction loses a day inside twenty seconds with nothing telegraphing it.
- **A wall with a gap in it is an invitation, and nobody has taken one.** A fraction of the day's
  soft seals lose one of their two bodies, so the street still looks obstructed and is walkable down
  the far side. The whole point is that a wrong turn stays open long enough to be taken and returned
  from — *"guide the player without having the player know they are being guided"* — and whether a
  half-open pair reads as an opening or as a barrier somebody forgot to finish is exactly the
  question the arithmetic cannot answer. The fraction is one constant and it is meant to move against
  a played day.
- **No day plans a route along the main road any more, and nobody has walked the city that makes.**
  Crossing the spine is untouched and free; running along it is refused when the tree is grown. The
  measured consequence is elsewhere and it is worth watching: the covering sets a one-shot is offered
  got **17 points narrower** — 45.7% of runs offered a single site before, 63% after — so an authored
  set piece is more often placed in one spot rather than on every route she might take. That is a
  fairness contract getting thinner, and it is a number rather than a complaint so far.
- **Every route the game plans is now grown on cells, and nobody has walked one.** The day's corridor
  is a chain of two-tile cells rather than a list of whole streets, so it can cut a corner through a
  park or take an alley — which is the point, and which also means the shape of a day's route is not
  the shape any played run has ever had. It is verified by the test rigs and by one dusk map read off
  a screenshot. **Whether a corridor that cuts through a park still reads as a route** is the
  question, and it is a played one.
- **No barrier is placed beside a calm area any more, and that is a third of the lattice.**
  `ClosurePlanner` refuses every access street of every calm area outright — a measured mean of 33.4
  of 264 streets a day. The intent is that a closure stops reading as broken; the risk nobody has
  looked at is the opposite one, that closures now cluster away from the places she actually walks and
  stop being met at all. M45's own trap in a new place: *a nudge that removes the decision is worse
  than a closure that does nothing.*
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
- **Every pavement obstacle moved this session and nobody has walked past one.** A stationary,
  unpinned body is now centred on the two-lane pavement band rather than standing at its lane's
  centre, and a spread on a north–south street is now laid along that street instead of across it. So
  `construction` genuinely blocks a 64px pavement — she needs 46px of clearance and the band gives 32
  — where before it left a free lane. That is the intent and it is also the first time an act I
  obstacle has been physically impassable in play. **Whether it reads as *cross the street* or as a
  wall dropped on the pavement is a played question**, and it is the one M64 is about to place a
  hundred and fifty of a day.
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
- **The touch controls have been played once, briefly.** One phone session on the deployed build
  produced one finding — the run lesson named a key the device has not got — and everything else
  about them is still unknown: whether a thumb can hold the 20px line between two pavement lanes,
  whether the catch radii feel right, whether `RUN` is legible at phone DPI, and whether the new
  pause button at the top right is reachable without covering something. The rotate prompt has never
  been seen on a phone either: it is a CSS overlay plus a best-effort `screen.orientation.lock`,
  and iOS Safari has no such API at all.
- **The social card has never been unfurled.** The Open Graph tags and the image copy into
  `build/web` are correct as far as a local check can tell, and nothing has pasted the address into
  a chat client to see what comes back.
- **There is no main menu.** There is a title screen — the doorstep with the traffic and the events
  running behind it, `space` or a tap to begin — but it is a title, three lines of controls and one
  key on the web (two on the desktop, where `q` also quits): no options, no seed box, no load game.
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
