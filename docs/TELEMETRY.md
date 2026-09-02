# Nappy — Telemetry

What a run writes down, why each line is there, and how to read one.

The short version: **a run log is a chronological plain-text file that records what the code
cannot recompute.** It exists because most open questions about the balance are questions about
what actually happens to a person playing, and nobody should have to have an opinion about those.

---

## Where the logs are

```sh
./tools/telemetry.sh          # print the newest run
./tools/telemetry.sh -f       # follow the run happening right now
./tools/telemetry.sh -l       # list them, newest first, with size and commit
./tools/telemetry.sh -p       # say what is stale; `-p yes` deletes it
./tools/telemetry.sh 3        # print the third-newest
./tools/stats.sh              # aggregate playtest runs: days won/lost, loss causes, most-met events
```

Underneath, one file per run in `user://telemetry/`:

```
~/Library/Application Support/Godot/app_userdata/Nappy/telemetry/   (macOS)
~/.local/share/godot/app_userdata/Nappy/telemetry/                  (Linux)
```

The absolute path is also printed to stdout at the start of every run. Both the script and
the print exist for the same reason: a trace nobody can find is a trace nobody reads, and on
macOS the directory is inside `~/Library`, which Finder hides by default.

Logs are named `run-<timestamp>-seed<N>-<commit>.log`. The newest fifty are kept and older ones are
pruned automatically — `check.sh` and `shot.sh` boot the game too, and the directory would otherwise
fill with two-line traces of runs that never started.

**The commit is in the name as well as on the first line**, because the question *which of these
still describes the build in front of me* is asked of a directory listing. `-p` is the other half:
it treats a log from another commit, or one too short to have been a run, as stale, never touches
the newest, and prints what it would delete unless told `yes`. The commit goes at the end of the
name rather than the middle, because a timestamp has dashes in it and so does `abc1234-dirty`.

**One sitting is often several logs, and that is correct.** Both `R` on the pause screen and a
finished run restart the game, which reloads the scene and opens a new log — so a file is one *run*,
not one session.

**It is on by default.** `-- --no-telemetry` turns it off. A trace behind a flag is a trace
the person playtesting has to remember to turn on, which means the interesting run is the one
that was not recorded.

**It is always off on a web export**, no flag needed. `user://` there is a stranger's browser
storage rather than a developer's disk: nobody collects what lands in it and nothing prunes it, so
`Telemetry.begin_run()` checks `OS.has_feature("web")` itself and does nothing on that platform —
the one caller cannot forget the check because there is only one place it is made.

## What one looks like

```
nappy run log  2026-08-26T22:39:25  commit b20763c*

day 6  act 2  run seed 4242  city seed 4242  length 144.0s
   0.0  contact  step 1 on offer at (79,94)
   0.0  plan     closed: cordoned off h(2,5), cordoned off h(4,7)
   0.0  plan     calm: 2 forest, 2 park, 3 courtyard
   0.0  plan     events: cat_dash x3, dog_walker x3, homeless_yeller, playground x2, ...
   0.0  start    doorstep (24,84), facing south
   0.7  cross    stepped into the road at (24,86), mid-block
   3.5  turn     doubled back north
  14.6  near     dog_walker at (23,99), 129px, exc 25, in 12.0/s (crowd 0.0, events 0.0), sleep 5
  15.3  near     dog_walker at (23,99), 19px, exc 33, in 15.1/s (crowd 0.0, events 6.1), sleep 5
  15.4  freeze   sleep stopped filling | exc 35, in 15.4/s (...), sleep 5 | near: dog_walker 15px
  18.1  run      ran 6.0s, exc 0 -> 66, nearest when it started: dog_walker 545px (out of range)
  35.4  lost     lost_crying after 35.4s — She started crying. ... | near: poster_crew 1370px
  35.4  nerve    spent a nerve on day 6 (act 2); 2 left
```

Three columns: seconds since dawn, the kind of entry, and a sentence. The columns are fixed
width so the file can be scanned down one of them — every `near`, or everything that happened
around 0:15 — with nothing but a pager.

### The first line

`commit b20763c*` is the commit the run was played on, and the `*` means the working tree was
dirty. Without it a trace cannot be checked against anything: "day one was brutal" is only a
finding if the code that produced it can be got back. A dirty tree is marked rather than
hidden, because it means the log describes something that no commit reproduces — the reading
is still useful, it just cannot be replayed by checking a hash out. It is asked of `git` at
runtime; an exported build has no repository to ask and records `unknown`.

### The day header

`run seed` is what the player asked for; `city seed` is what the generator settled on.
`CityGenerator.generate()` retries with `seed + 1` when a layout fails its guarantees, so the
run seed alone does **not** reproduce a city and both have to be written down.

---

## What is recorded, and what is not

**A run is deterministic from a seed, so most of what the game decides is already
recomputable and recording it would be noise.** The line is drawn at what the code cannot get
back.

| Record | Do not record |
| --- | --- |
| The seed the generator actually used, and the commit it ran on | The city layout, block purposes, building rects — recomputable from that seed |
| **Random outcomes that branch the run**: a one-shot that fired, with the roll and the threshold; which block arc advanced and what caused it; the alley trap roll; the scar an event left | Falloff curves, meter rates, event intensities and radii — they are in `Tuning` and the catalogue |
| What the player did, in order: where they went, when they turned back, when they ran, when they crossed a road | Derived aggregates — the circling ratio, total distance. Computable when reading, and a reading aid at best |
| What the world did to them: what came within range and how close, when sleep froze and what was near, which closure they saw | Which tiles are calm, which streets exist — recomputable |
| The outcome and its cause: result, elapsed, margin, what was nearby at the moment of a loss, which nerve went and on which day | — |

**Spoiling is the one place a rule was tempted to read this file, and it does not.** The city
remembers which calm block the baby actually went to sleep in and spoils it the next day — which is
exactly what the `calm` entries say. Reading them back is the smaller change and it breaks the
invariant in the loudest possible way: the game would play differently with `--no-telemetry`. So
`GameState.settled_in` is its own run-scoped record, written by `DayController` at the moment she
settles, and the log merely *also* mentions it. **Where a trace and a rule want the same fact, the
rule keeps its own copy.**

Random outcomes are the important half, and the reason is specific to this project: rolls
that depend on **run history** — a one-shot already consumed, a fire that only burns a block
because something burned there, a scar that exists because of what the player did — are not
recomputable from a seed at all without replaying the whole run with identical input. They
are the story of the run and they have to be written down as they happen.

## The entry kinds

**Each one answers a question somebody actually asked about a run.** A new kind has to be able to
name the question it answers, or it is a metric and does not belong.

| Kind | Written by | Answers |
| --- | --- | --- |
| `plan` | `main.gd` | What today is: what is shut, where the calm is, what is out |
| `roll` | `EventScheduler`, `ResistanceDirector` | Which way a run-branching roll went, with the number and the threshold |
| `arc` | `CityState` | Which block became something else, and what caused it |
| `scar` | `EventManager` | Where the city stopped being recomputable |
| `ahead` | `EventManager` | When the director put something across her line, and where she was — the only record of an event that has no place on the map |
| `taken` | `EventInstance` | Whether an `abduction`'s own bystander scene ever actually finishes — the only record that the catalogue touched the crowd at all. Written by the instance itself rather than by `EventManager`: the scene needs nothing the instance does not already carry (`player_at`, its own age), and that is what lets a data-level rig assert it with no map or city behind it |
| `contact` | `ResistanceDirector`, observer | Did the player ever find the difficulty dial |
| `start` | observer | Where the day began |
| `cross` | observer | Did the player have to cross the street, and at a zebra? |
| `road` | observer | Did they *walk down* the road rather than across it? Only written when a stretch outlasts a crossing, so the entry existing is the answer |
| `path` | observer | **Was she on the day's corridor?** A line each way as she crosses on or off it, and one at dusk with the share of her street time she spent on it. It is what makes *"going off the paths lets me skip events and is safer than going on the path"* a measurement rather than an argument. Time in a park or an alley is counted separately from "off it": the corridor is made of streets and the destination is not one, so folding them together would credit every won day with a long safe stretch off the paths |
| `crowd` | `Crowd` → observer | Contact with the street: somebody she walked into, or a car that had to sound its horn at her standing in the road, with a timestamp on it |
| `calm` / `left` | observer, `GameState` | Same park every day? It also says which block she settled in, so the log shows what tomorrow's plan is reacting to |
| `near` | observer | How many entities were nearby, which, and how close — the cost table as what happened to a person |
| `closure` | observer | Are the closures a decision or scenery? |
| `turn` | observer | Did the player double back — and was it because of a barrier they had just seen? |
| `run` | observer | Did running help? Against everything you route around the answer is "it made things worse", by design — but there is one kind of thing running is the *only* answer to, so a `run` immediately after a `charging_dog` telegraph is the lesson landing rather than a mistake |
| `chase` | observer | **The one encounter with a right answer, and whether she played it** — two lines per pursuit: it came for her, and how it ended. How close it actually got, how long of it she spent running, and which of the two ways a chase can end it ended in. Without it a trace has an event being sited, four distances and a death, all of them about the **world**, when the question is about the **exchange** |
| `idle` | observer | **Standing still, and what it bought** — how long, on what ground, and what the two meters did across it. Written when the stand ends, like `cue`, because the duration is the point. Standing still emits nothing, so without this entry it shows up in a trace as a *gap between two lines* |
| `blocked` | observer | **Is she stuck, or standing on purpose?** Movement input held for about a second while she goes nowhere — the direction, how long, and where. `idle` already covers the legitimate stand-still, no direction held; without this one an immobile rig's log reads exactly like a run, and a person pressing into a blocker the engine never stopped them at has no trace of having done it |
| `cue` | observer | **What was she warned about, and for how long** — the mark over her head and the screen-edge badges, each written when the span ends so the duration is on the line. A cue is a claim about a moment, and a complaint about a cue's *timing* is invisible to a trace that writes only what was marked |
| `freeze` / `thaw` | observer | Was the day lost to noise or to the clock? Freezing is the invisible failure |
| `asleep` / `woke` | observer | How long the walk actually took, and what woke her |
| `quiet` | observer | The sabotage landed and the masts went off |
| `home` / `lost` | observer | The outcome, the margin, and what was around when it happened |
| `nerve` | `GameState` | Where the nerves went — which day, which act |
| `ending` | `GameState` | How the run finished |
| `shot` | `main.gd` | **A person pressed `P` and said *look at this*** — where she was, what the meters read, which screen was up, and a PNG beside it. The only entry in the table that is not about the game: it is about somebody watching it |

### Reading the meter breakdown

Several kinds carry the same readout:

```
exc 35, in 15.4/s (crowd 0.0, events 6.1), sleep 5
```

`in` is the baby's **whole** incoming rate; `crowd` and `events` are the two spatial sources.
Whatever `in` exceeds them by came from the player — running, or standing in an alley. **Printing
only the two sources is the trap**: a meter climbing on an empty street then reads as `crowd 0.0,
events 0.0`, which is true and hides that the player was doing it to themselves with the run button.
The three numbers are printed together so they always add up.

The crowd cannot be named one agent at a time. Which of the two is holding the meter up is the whole
question, and it is one subtraction.

---

## Three constraints on the implementation

All three are non-negotiable, and the first is an invariant in the **telemetry** skill.

**It must not touch gameplay.** No RNG, no `day_rng()` stream, nothing that changes a
placement or a roll. Where a system logs a random outcome it hoists the *existing* roll into
a variable to print it; it never adds one. That hoist is a one-line edit with a way to be
catastrophically wrong — consume one extra value from a day's RNG and every event placed
after it moves — so `tests/test_telemetry.gd` plans all fourteen days with the log off and
again with it on, and requires the plans to be identical event for event and pixel for pixel.

**It must be readable without a tool.** It is for a human deciding whether day one is too
hard. If reading it needs a script that does not exist yet, it will not get read. Hence fixed
columns, whole sentences, and no ids that have to be looked up somewhere else.

**Order is the record.** One line per thing that happened, timestamped, in the order it
happened. An aggregate can always be computed from an ordered log; the order can never be
recovered from an aggregate. A page of aggregates says a day was hard; a log says the closure
sent them north, the convoy came through at 0:48, they ran, and the park was already spoiled
when they got there. Only the second one explains anything.

Every line is flushed as it is written, because a run that ends in a crash, an Esc or a closed
window is exactly the run worth reading and a buffered log of it would be empty.

---

## Adding an entry

1. Find the question it answers. If there is not one, stop — see the constraint above.
2. `Telemetry.note("kind", "sentence")` at the point where the thing happens. Reuse a kind
   from the table above rather than inventing a synonym for one.
3. Format positions with `TelemetryLog.tile()`, directions with `TelemetryLog.compass()` and
   block purposes with `TelemetryLog.purpose()`. Two spellings of a position in one log is
   two things to grep for.
4. If it is a random outcome, hoist the roll — never add one — and print the roll *and* the
   threshold. `0.42 >= 0.33` is checkable; "did not fire" is not.
5. Add a row to the table above.

Anything that needs a per-frame check belongs in `TelemetryObserver` and not in the gameplay
class. That node exists so the invariant is easy to keep: the telemetry is not in the files
that decide things. It is only added to the tree when a run is being traced, so with
telemetry off there is no observer at all rather than one checking a flag sixty times a
second.

## Snapshots

A trace says what happened; a screenshot says what it **looked like**, and the second question is
the one this project keeps having to answer with a rig. The defects no log can see are the ordinary
kind here: birds that freeze in the air, a cat drawn running backwards, a zzz a body's width off the
pram, a caret over the wrong things.

So a run writes PNGs beside its log, named `<log stem>-<clock>s-<what>.png`, and they are pruned
with it. Three rules:

- **The heuristic is the log's own.** There is no interval. A shot is taken on the entries a reader
  already stops at, because those are exactly the lines that raise the question a picture answers:
  `lost` (what the street looked like as the day ended), `chase` starting (the one encounter with a
  right answer, and the open question is whether a dog that stops short *reads* as "go now"), and
  the doubled `NOW` mark going up (every complaint about that cue has been about **when**).
- **It stays small.** `Telemetry.SHOTS_PER_DAY` and `SHOT_SPACING` — six a day, three seconds
  apart, so a condition that is true for two seconds is one picture rather than a hundred and
  twenty. A directory of near-identical frames is a directory nobody opens.
- **It does not touch gameplay**, which is the constraint the whole file is built on. A capture is
  an `await RenderingServer.frame_post_draw` and a file write: it draws nothing, changes no state
  and takes no RNG. The calls live in `TelemetryObserver`, not in the classes that decide things,
  and there is no capture at all under `--headless` — the suite must never start writing images.

### And one a person asks for

`P` (or `F9`) writes `<log stem>-<clock>s-asked.png` and a `shot` entry beside it.
`Telemetry.snapshot_now()` is the heuristic one with the two limits taken off, and that is the
whole difference: `SHOTS_PER_DAY` and `SHOT_SPACING` exist because a condition that stays true for
two seconds would otherwise write a hundred and twenty frames, and **somebody pressing a key has
already decided this frame is worth keeping**. A cap that silently swallows the seventh press is a
tool that lies about having worked.

Two things about it that are not obvious. It answers **before** the pause guard in
`Main._unhandled_input`, so it works on the pause and title screens too — the frames worth
photographing by hand are disproportionately the ones where something looks wrong and the player
has just stopped the game to look at it. And the context string is assembled in `main.gd` rather
than here, for the reason everything in this file takes what it needs as an argument: **the
telemetry asks the world no questions, so it can never be the thing that changed one.**

## The city grid

**A trace says where she was and cannot say what she was walking around.** Most questions asked of
a log turn out to be questions about the layout — how far the nearest calm area is, whether a
closure cut anything, which street the spine is, why a park was never reached — and answering one
from a list of tile coordinates is a thing nobody does twice.

So a run writes `<log stem>-map-day<NN>.png`: one four-pixel square per tile, coloured by tile
type, with the home, the calm areas, the main road, today's closures, the day's corridor, every
event the day placed and — at dusk — the trail she actually walked marked over it. `TelemetryMap`
does the drawing.

- **It is not `--overview`.** That flag frames the *rendered* city — buildings, props, dusk, an
  act's colour cast — on a run somebody has to take deliberately. This is the grid, so it says what
  the generator decided rather than what the renderer drew, and it is written without being asked.
- **Per day, not per run.** The lattice is fixed for a run and **what a block is is not**: an arc
  requisitions a park, a fire leaves a shell, and today's closures are down. A single map taken at
  dawn on day 1 would be a lie by day 12. It is written twice a day — see "What the day placed".
- **Marks are outlines, lines and crosses, never fills**, so nothing can hide the ground it is
  describing — the commonest way a debug overlay lies is by covering the thing that was going to
  answer the question. Three things are filled and each is bounded rather than argued: the home,
  because it is a point rather than an area; a hard blocker, because there the ground *is* the mark;
  and a lethal event, at nine tiles of a six-tile street on the handful of rows a day that end it.
  A crosshair reaching a
  block either way was built and taken back out: it is the only red in a picture with no other red
  in it, so it was already the first thing the eye lands on, and the reach was covering two streets
  to buy nothing.
- It has **its own** building colour rather than `Tile.ground_colour`'s `BUILDING` answer, whose
  `_:` arm returns `Palette.OUTLINE` under a comment saying the case only shows through bugs.
  Leaning on a fallback whose stated purpose is *this should never be seen* is how a contract
  quietly becomes untrue.
- **A precinct has no mark, and that is a correction rather than an omission.** A pedestrianised
  corridor is laid `SIDEWALK` all the way across, so the ground pass draws it as an unbroken pale
  band where every other street has a stripe of asphalt down its middle. An overlay on top of that
  repeats what the picture already says, which is the one kind of mark that can go out of date
  without anybody noticing. `tests/test_telemetry.gd` asserts the paving across the corridor, which
  is the fact rather than the overlay.

### The corridor

The picture also carries the day's **corridor** — `RouteTree`, the branch from the doorstep to every calm area still worth reaching —
as one **translucent violet** line down the middle of every street on the tree.

It is the one mark in the picture that is a **plan rather than a fact about the ground**, which is
why `render` takes it as an argument and draws nothing when there is none: a picture that invented
a plan when it was given none would be worse than a picture without one. `Telemetry.write_map`
grows one when the caller has none to hand, and that is safe rather than convenient —
`RouteTree.for_day` is a pure function of the city's seed, the day and what is shut, so the tree
drawn is the same tree anything else asking for today's would get, and growing it touches no
gameplay stream.

Each stroke runs from the middle of one junction to the middle of the next rather than over the
street alone, so consecutive streets meet and a turn crosses: the picture is a **path** rather
than a set of dashes, which is the difference between reading a route and inferring one.

**Every street on the tree is drawn the same, and the stroke is mixed into the ground rather than
laid over it.** Drawing a bundled street solid white and two tiles wide puts a third of the map
under a colour that hides everything beneath it, and makes the shared trunk read as the subject of
the picture rather than as a property of it. Transparency is a **mix** rather than an alpha, because
the image is `FORMAT_RGB8` — chosen so the file previews in a directory listing — and a colour with
an alpha component written into one is simply stored opaque.

What that costs is a diagnostic, recorded here rather than argued away: *a picture in which nothing
is shared is a tree that has quietly become a star* is not readable at a glance from this picture.
It is asserted directly instead, by `RouteTree.bundles()` and `tests/test_route_tree.gd`, which is
the stronger place for it — but it is not something a person notices without looking for it.

### The hard blockers

Every street a hard blocker took has it drawn in **teal**, filled — the wall at the end of a dead
end, and the whole street a big building was built over. The two read differently by shape rather
than by colour: a dead end is a stub at one end of a street, and a landmark is a street's whole
width with solid block either side of it. That is the one exception to
"outlines, never fills" above, and it is not a slip: the rule exists because a mark that covers
the ground stops the picture answering the question it was opened for, and here the ground *is*
the mark — the tiles under it were built over, and an outline round a wall leaves the middle of it
reading as the street it used to be.

It earns a colour rather than being left to show through as building, which is invisible: a two-tile
slab of dark building inside a dark street is exactly the thing nobody spots, and **a hard blocker
nobody can find in the one picture built to check placements might as well not have been placed.**

### What the day placed

Every **sited** event is drawn where the day put it, carrying the three things `docs/CITY.md`,
"The words for it", says about a placement:

| channel | says | values |
|---|---|---|
| colour | **role** — what it was placed *for* | wall (yellow), friction (blue), set piece (magenta), none (grey) |
| shape | **effect** — what it does to a route | lethal fills its three tiles, costly is a cross |
| a white pip in the middle | whether she ever reached it | drawn only once it has been in the world |

- **The role gets the colour because the role is the question.** A wall drawn *on* the corridor
  instead of beside it is the central defect a placement pass can have, and it is one glance to see
  here and invisible in every other tool. Reading it off a log means joining a `plan` line to a
  `near` line by hand, which is the thing nobody does twice.
- **`NONE` is deliberately the dullest thing in the picture.** It is not a fourth kind of
  placement, it is everything the day put down for a reason that is not about the route — an
  ambient playground, a scar the run left, a cat the director will site in front of her later.
- **An unplaced plan is not drawn**, and that is the honest answer rather than a gap. An
  `AHEAD_OF_PLAYER` row has no position at dawn, so drawing it anywhere would be the picture
  claiming a placement nothing made.
- **A spent set-piece offer is drawn like any other**, because the sites that did not fire are what
  makes the covering set visible at all. They come out without a pip, which is right.
- A **routed** event also gets a faint band along the ground it covers. It is much fainter than
  the mark, and that number was set by looking: at the mark's own strength the routes were the
  loudest thing in the picture and read as *corridor* — thin coloured lines down the middle of
  streets, which is exactly what the violet is.

**And it is written twice a day, which is the only reason the pip means anything.**
`<log stem>-map-day<NN>.png` at dawn is purely *what the day intended*; `-map-day<NN>-dusk.png` is
the same picture with the placements she actually walked up to burnt into it. Neither is derivable
from the other and neither is the more useful one — a wall in the wrong place is visible in the
first, and *a corridor with nothing on it ever met* is visible only in the second.

**The pip is a mark added rather than strength taken away.** Fading what she never reached is the
obvious design and it answers the wrong question: a wall in the far corner of a map she never walked
into is still a wall in the wrong place, and it is the placement no trace can report — so the
picture would whisper exactly the thing it exists to shout. Drawn instead, every mark stays at full
strength and the ones she met carry the pip on top of it — see "The trail" below for the other half
of what the dusk map now says about where she went.

### The trail

The dusk picture also carries **where she actually went**: one blended dot per sample, drawn in a
warm colour where she was walking and a hot red where she was running —
`Stroller.run_excess_ratio()`, read off the same sample rather than kept as a second trail.

`TelemetryObserver` accumulates the trail as a list in memory while the day runs and hands it to
`Telemetry.write_map` at dusk, the same way it already hands the day's corridor. **Sampled by
distance, not by frame** — one point roughly every tile (`TelemetryObserver.TRAIL_SAMPLE_DISTANCE`,
32px) — so a fast machine and a slow one produce the same trail and a 180-second day is a few
hundred points rather than growing with how long a frame took. Nothing is written to the log for
it: the trail is drawn, never logged, the same as the corridor.

**The dawn map keeps drawing no trail.** There is no walk yet, and a picture that invented one
would be worse than a picture without one — the same reasoning that keeps the corridor off a
picture given no tree. **A lost day restarts the trail**, in the same `start_day()` reset that
clears everything else about yesterday: a rewound day was not walked.

**It has to be read *against* the corridor the day planned for her**, which is the entire value of
the picture existing — where she actually went, held next to where the day expected her to. Both
marks are blended into the ground rather than painted over it for the same reason: a trail solid
enough to hide the corridor underneath it would answer only half the question.

## What it deliberately does not do

- **No aggregates, no summary at the end of a run.** Both are computable from the log when
  reading it, and neither can be un-computed back into an order.
- **No per-agent crowd entries, except on contact.** A few hundred agents would bury everything
  else, so the crowd is otherwise only its share of the meter. The exception is the one thing about
  it worth a line each: a contact is something the game *decides* rather than a state to be noticed,
  so `Crowd` reports it on `EventBus` and the observer writes it down. That split is deliberate —
  the rate limiting belongs with the rest of what keeps the log readable, and the telemetry stays
  out of the file that decides things.

  Bumps are rate-limited to one line every 1.5s, and the **dropped count is printed rather
  than swallowed** — "she bumped somebody at 0:14" and "she ploughed through fourteen people
  between 0:12 and 0:14" are very different days and without the number they are the same
  line. **Horns are never dropped**: whether the carriageway is a decision or a place people
  wander into is the question the traffic exists to pose, and the horn is the last entry before a
  `lost` line when the answer is the second one.
- **No `near` entries for `city_wide` sources.** A field with no edge cannot be approached.
  What the loudspeaker masts are doing shows up in every meter breakdown instead — which is also
  the most misleading gap in the trace today; the fix is queued in `docs/TODO.md`.
- **No sampling of the player's position on a timer, in the log.** Where they were is
  reconstructable from the entries, and a position every half second would be a metrics dump
  wearing a log's clothes. The dusk map's trail (see "The trail" above) is not an exception to
  this: it is sampled by distance rather than by timer, it is never written to the log, and it
  lives only in memory for the length of one day.
