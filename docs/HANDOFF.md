# Handoff

**Where to pick up.** This file says what is true right now and what to do next. It holds no
history — that is [DECISIONS.md](DECISIONS.md), fetched when you need to know *why* — and no
progress-tracking, which lives there too.

**Read this, then [TODO.md](TODO.md).**

## The state of the tree

**`main` has unpushed commits ahead of `origin/main` and is otherwise the only branch.** Nothing is
half-written in the working tree and no worktree is open (`git log` over what has not reached
`origin/main` says what those commits are, and the newest of them is M69's merge). Trust the tools
over any sentence here:

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
and it converts some of them every time. It is not a one-off: it happened twice in the session that
built M69 alone. **Run `git status` after `check.sh` and revert anything you did not mean to
change**, rather than assuming only the files you touched moved.

**The game is published, and a merge to `main` is a release.**
`https://nappy.josuakrause.com/` serves it, and `.github/workflows/deploy.yml` rebuilds and
republishes on every push to `main` — gate, export, upload, publish, in that order, so a red build
never reaches the site. Completed work may be pushed without asking; see the **committing** skill
for what *completed* means, and read the sentence above it before pushing, because pushing is now
publishing. Everything unpushed is gated — `check.sh`, `lint.sh` and the full unfiltered `test.sh`
ran clean on the merged tree — so it is safe to push whenever wanted. It just has not been, and
M69 changed how every day's routes and closures are computed, so **a played day before publishing is
worth more here than usual**: the whole milestone is verified by rigs and nobody has walked a city
whose corridor was grown on cells.

## What to do next

**Start with [PLAYTEST-20.md](PLAYTEST-20.md).** A full seven-day run, four findings, and it is still
the freshest thing in the repo. Its findings are filed against the milestones that own them; the
reachability gap has been built, and the record of what that turned into is `DECISIONS.md` under M69.

**Read that record before touching routes, closures or the corridor**, because M69 changed the ground
every one of them stands on. Reachability is now `ReachabilityGrid` — the tile map contracted into
two-tile cells, one node per connected component of a cell's walkable tiles — the day's route tree
grows on it, and `ClosurePlanner` refuses a calm area's access streets outright. `StreetNetwork` is
still there and still owns the lattice and the structural route count; it is no longer what answers
*can she get there today*.

1. **M64 — off the path is closed, not dear.** Now first in the order: every event in the catalogue
   is a reason to cross the street and none is a reason not to go somewhere. **It supersedes M50's
   gradient** — the corridor stops being the *cheapest* ground and becomes the *only way through*,
   with the picture varying instead of the price. The mechanism already exists: two ordinary
   obstacles facing each other leave no line to walk. What has to be decided first is how many ways
   through the day's route tree keeps open, because under this policy that number is the difficulty
   of the whole game. **Its precondition is built**: the tree now grows on cells, so sealing off the
   tree no longer seals every park crossing and alley in the city.
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
block), **M45** (closures that point), **M48** (bodies drawn wider than their pavement), **M43**
(the tutorial dog after day 3; the one-contact cliff at 90; `RUN_TAUGHT_DAY` 3 → 2), **M49** (the
fence, the vanishing border-walkers), **M68** (tap to walk as a switchable experiment), **M60**'s
last two (the home arrow under a thumb, the browser smoke pass), **M25** (patrols for the empty
acts), **M26** (teaching the controls), a shortlist of small items, and **M10** (polish).

## What to distrust

What is untested by a human, listed so nobody mistakes arithmetic for a verdict.

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
