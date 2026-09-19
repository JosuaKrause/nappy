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
./tools/telemetry.sh -l       # list them, newest first, with size and kind
./tools/telemetry.sh -p       # say what is stale; `-p yes` deletes it
./tools/telemetry.sh 3        # print the third-newest
./tools/stats.sh              # aggregate playtest runs: days won/lost, loss causes, most-met events
```

Underneath, one folder per run in `user://telemetry/`:

```
~/Library/Application Support/Godot/app_userdata/Nappy/telemetry/   (macOS)
~/.local/share/godot/app_userdata/Nappy/telemetry/                  (Linux)
```

The absolute path of the run's own folder is also printed to stdout at the start of every run.
Both the script and the print exist for the same reason: a trace nobody can find is a trace
nobody reads, and on macOS the directory is inside `~/Library`, which Finder hides by default.

**A run is a folder, `<day>/<run>/`, and the date and run are independently removable.**
For example:

```
user://telemetry/2026-09-03/run-205437-seed2102613802-v0.0.0-49-gdb09693-dirty/
├── run.log
├── maps/
│   ├── day01-attempt1.png
│   ├── day01-attempt1-dusk.png
│   ├── day06-attempt1.png
│   ├── day06-attempt2.png
│   └── day06-attempt2-dusk.png
├── auto/
│   └── 003-attempt1-lost_crying.png
└── asked/
    └── 004-attempt1-asked.png
```

- **`<day>`** is the calendar date the run was played (not the in-game day the log talks about),
  so a bad week of testing can be cleared with one `rm -rf` of its date folders.
- **`<run>`** is the individual run, and its name carries what a level per commit used to split
  across two folders: `run-` when a person was at the controls, `rig-` for a headless boot or
  anything driven by `--screenshot`, `--walk`, `--flee` or `--press`; the full `HHMMSS` time of day
  the run started; the seed; and last `git describe --tags --always`'s own form — the nearest
  version tag, commits since, and the abbreviated hash the run was played on
  (`v0.0.0-49-gab12cd3`), with `-dirty` appended if the tree was not clean, the same mark as the
  log's own first line. `tools/telemetry.sh -p` compares that tail against the same `git describe`,
  by path alone, to say what is stale. The full time of day in the run's own name is the only clock
  anywhere in the path — the parent folder carries the calendar date and nothing finer — and it is
  what lets a run folder still identify itself once copied out on its own, into `docs/evidence/` or
  pasted into a message. The version goes **last**, so sorting the run folders within one `<day>`
  by name still sorts them by age, because the time leads the name.
- **`run.log` sits directly in the run's folder**, not in a subfolder of its own — it is the one
  artefact every run has, so it needs nothing to distinguish it from a sibling of its own kind.
- **The three picture kinds each get their own subfolder**, so a directory listing separates them
  without anybody having to read a filename to tell which is which: `maps/` for the day pictures
  (`Telemetry.write_map`, see "The city grid" below), `auto/` for the heuristic's own screenshots
  (`Telemetry.snapshot`, see "Snapshots" below), and `asked/` for a picture a person pressed a key
  for (`Telemetry.snapshot_now`). A subfolder is only created the first time something is actually
  written into it, so a run that never triggers the heuristic — most of them — has no empty `auto/`
  sitting in it.

**The game never deletes anything under `user://telemetry/`.** *(2026-09-03: "no automatic cleanup
anymore", "the folder structure allows for easily deleting old days/commits".)* The directory grows
without bound on purpose: `<day>/<run>/` is a hierarchy built to be cut into by hand, and
clearing it — a day, one run, or everything — is a decision for whoever is looking at
the directory, not one the game makes behind them. `tools/telemetry.sh -p` (`-p yes` to actually
delete) is the one thing that still removes anything, and it does that because a person ran it.

**The version sits in the run's own folder name rather than in a folder level of its own**, because
a level per commit split a day's runs across as many folders as builds were played on it, and
listing a day did not list its runs. `-p` is what still needs to answer *which of these describes
the build in front of me*, and it does that by path alone, matching the tail of a run's own folder
name against `git describe --tags --always`, computed once at the top of the script: it treats a
run on another version, or one too short to have been a run, as stale, never touches the newest,
and prints what it would delete unless told `yes`.

**One sitting is often several runs, and that is correct.** Both `R` on the pause screen and a
finished run restart the game, which reloads the scene and opens a new run folder — so a folder is
one *run*, not one session.

**It is on by default.** `-- --no-telemetry` turns it off. A trace behind a flag is a trace
the person playtesting has to remember to turn on, which means the interesting run is the one
that was not recorded.

**`--spikes` is off by default, unlike the log itself.** *(2026-09-14, the player, on the log's
own `spike` line: "spike line sounds good"; "make that toggleable separately though since it can
be quite noisy".)* A slow machine can turn one line a second into a permanent fixture of the log,
so it stays behind its own dev flag rather than being folded into telemetry's own default — see
"What a frame cost" below.

**It is off by default on a web export**, and the page's own `?telemetry=1` query parameter is the
one way to turn it on there — but only in a **debug** web export. `_web_override_requested()` is
gated behind `DevFlags.enabled()` (`OS.is_debug_build()`) like every other developer flag: a
release build — the one `.github/workflows/deploy.yml` publishes — answers nothing here regardless
of the query string, and a debug build — the one `tools/serve-web.sh` exports and serves locally —
answers immediately. `user://` on the web is still a stranger's browser storage rather than a
developer's disk, so the override is for watching what a run does while sitting at that browser,
not for collecting anything back afterwards — there is still no `tools/telemetry.sh` to point at
it. `Telemetry.begin_run()` checks `OS.has_feature("web")` and the query parameter itself and does
nothing on that platform without it — the one caller cannot forget the check because there is only
one place it is made.

## What one looks like

```
nappy run log  2026-08-26T22:39:25  version v0.0.0-49-gab12cd3-dirty

day 6  act 2  run seed 4242  city seed 4242  length 144.0s
   0.0  contact  step 1 on offer at (79,94)
   0.0  plan     closed: cordoned off h(2,5), cordoned off h(4,7)
   0.0  plan     calm: 2 forest, 2 park, 3 courtyard
   0.0  plan     events: cat_dash x3, dog_walker x3, homeless_yeller, playground x2, ...
   0.0  start    doorstep (24,84), facing 180°
   0.7  cross    stepped into the road at (24,86), mid-block
   3.5  turn     doubled back 46°
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

`version v0.0.0-49-gab12cd3-dirty` is `git describe --tags --always`, run at startup: the nearest
version tag, how many commits since, and the abbreviated hash the run was played on, with `-dirty`
appended if the working tree was not clean. Without it a trace cannot be checked against anything:
"day one was brutal" is only a finding if the code that produced it can be got back, and naming the
tag as well as the hash says which release this is close to without a `git log` to find out. A
dirty tree is marked rather than hidden, because it means the log describes something that no
commit reproduces — the reading is still useful, it just cannot be replayed by checking a commit
out. Asked of `git` at runtime; an exported build has no repository to ask and records `unknown`.

### The day header

`run seed` is what the player asked for; `city seed` is what the generator settled on.
`CityGenerator.generate()` retries with `seed + 1` when a layout fails its guarantees, so the
run seed alone does **not** reproduce a city and both have to be written down.

### `--invincible`

`--invincible` (or the page's own `?invincible=1`, a debug web build only) is `DevFlags`' own
developer flag — gated behind `DevFlags.enabled()` (`OS.is_debug_build()`) like every other one,
listed in README.md's "Dev flags" table. Under it, `DayController._ignores_loss()` is the one
predicate all three losing results — crying, a hard fail, the clock reaching zero — consult before
ending the day, so none of them do; a won day still ends normally. **It also stands the day clock
and the excitement meter still**, rather than letting the day run its noisy, darkening course with
nothing able to end it: `DayController._process()` skips the countdown outright, so
`fraction_remaining()` — and the light it drives — stays wherever the day started, and `Baby.
_update_excitement()` never adds to the meter, though decay may still run it down. *(2026-09-11,
overturning the flag's own first build the same evening, [PLAYTEST-57](playtests/PLAYTEST-57.md):
"when invincible the timer should never go down and excitement should never go up. this is just
noisy flashing of alarms and the day gets dark.")* The day header notes the flag itself the same
way it notes the seed, appended once when the day opens rather than as a per-frame entry —
`day 6  act 2  run seed 4242  city seed 4242  length 144.0s  invincible` — so a log from an
invincible day is recognisable without reading a single `lost` or `nerve` line that never comes.
The HUD's own debug header (`hud.gd`'s `_refresh_header()`) appends `INVINCIBLE` for the same
reason, so no capture from such a run is mistaken for one where a loss meant anything.

---

## What is recorded, and what is not

**A run is deterministic from a seed, so most of what the game decides is already
recomputable and recording it would be noise.** The line is drawn at what the code cannot get
back.

| Record | Do not record |
| --- | --- |
| The seed the generator actually used, and the version it ran on | The city layout, block purposes, building rects — recomputable from that seed |
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
| `plan` | `main.gd`, `City`, `ClosurePlanner` | What today is: what is shut, where the calm is, what is out, and the region wall's own shape — how many boundary segments, walls and doors, and which regions hold calm |
| `roll` | `EventScheduler`, `ResistanceDirector` | Which way a run-branching roll went, with the number and the threshold |
| `arc` | `CityState` | Which block became something else, and what caused it |
| `scar` | `EventManager` | Where the city stopped being recomputable |
| `ahead` | `EventManager` | When the director put something across her line, and where she was — the only record of an event that has no place on the map |
| `taken` | `EventInstance` | Whether an `abduction`'s own bystander scene ever actually finishes — the only record that the catalogue touched the crowd at all. Written by the instance itself rather than by `EventManager`: the scene needs nothing the instance does not already carry (`player_at`, its own age), and that is what lets a data-level rig assert it with no map or city behind it |
| `chat` | `EventManager` | A detention conversation started — which one, where, and how long it holds her. Written whenever `detain_seconds` fires, not only for `chatting_mother`, so a redetaining door's own toll is on this line too; what it costs the meter is on the line as well, since a sleeping baby pays nothing and an awake one pays `Tuning.CHAT_EXCITEMENT` |
| `checkpoint` | `EventManager` | A region door's toll paid — where she was held, how long, and which side she came out on. Written on release rather than on capture, since "released on the north side" is the fact a reader wants and the teleport is what makes it true |
| `contact` | `ResistanceDirector`, observer | Did the player ever find the difficulty dial, and did an unseen pickup mark have to move to stay findable — where it was, and where it went |
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
| `frame` | observer | **What the frames cost on the device this was played on** — once a second, the frame rate, the worst single frame in that second, the draw calls, renderable objects and primitives the renderer was handed, and the milliseconds spent in `_process` and `_physics_process`. The one entry that is about the machine rather than about the day, and the only way a session played on a phone or on the web page can be read back at all. See "What a frame cost" below |
| `spike` | observer | **Under `--spikes` only: which frame in the second ran past twice the mean of the frames before it, and what the game did in it.** The frame's own length and that mean, in milliseconds, followed by what changed since the previous frame — her tile, the count of live event instances, how many transfer PNGs `TextureResolver` loaded, or how many atlases `TextureAtlas` collected — or "nothing else changed that frame" when none did. At most one line a second, the worst of that second if more than one frame qualified. See "What a frame cost" below |
| `texture` | `TextureResolver`, `TextureAtlas`, `GroundLayers` | **When a picture was loaded or dropped, and what it cost** — a transfer PNG read from disk with the path and the milliseconds the read took, an atlas becoming ready with its group, how many pictures it holds, its pixel size, the milliseconds from the request and how much of that the worker thread took, an atlas being released with how long it was drawn from, and the ground's own shared texture being packed with how many sources it covers and what that cost. It is what says whether a picture arrived before it was drawn rather than during the frame that wanted it |
| `freeze` / `thaw` | observer | Was the day lost to noise or to the clock? Freezing is the invisible failure |
| `asleep` / `woke` | observer | How long the walk actually took, and what woke her |
| `quiet` | observer | The sabotage landed and the masts went off |
| `home` / `lost` | observer | The outcome, the margin, and what was around when it happened |
| `nerve` | `GameState` | Where the nerves went — which day, which act |
| `ending` | `GameState` | How the run finished, and how long the world was actually moving to get there — `GameState.play_seconds`, formatted `%d:%02d.%03d` |
| `shot` | `main.gd`, `Telemetry` | **A person requested a screenshot or animation burst** — where she was, what the meters read, which screen was up, and capture start/completion/refusal context. This entry records somebody observing the game |

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

### What a frame cost

The `frame` entry, once a second:

```
  12.0  frame    fps 118, worst frame 22.4ms, draws 342, objects 351, primitives 4120, process 4.21ms, physics 0.83ms
```

**It is the one entry about the device rather than about the day**, and it is there because the
device a run is played on is usually not the device it can be read on. *(2026-09-13: "I played a
few sessions on mobile. It is a bit laggy now.")* A phone has no readout anybody can photograph and
no profiler to attach, and neither does an ordinary web page — `?debug=1` puts one on the page
itself (see "The debug view" below), but nothing reaches a phone's own screenshot tooling, so a
phone session's numbers still only ever go on the line.

**A frame rate on its own cannot say where the frame went**, which is why the other six fields are
beside it. `draws` is the call count the renderer issued — the number an atlas moves, since only
consecutive draws sharing a texture are batched and a sprite drawn from its own texture is a call
of its own. `objects` is the renderable items submitted and `primitives` the triangles and lines
in them, and the pair separates *many small sprites* from *a few large fills*: a frame heavy in
primitives and light in pixels is a geometry problem, and the reverse is a fill-rate one — the
second being exactly the cost a desktop measurement cannot see on a phone's own screen. `process`
and `physics` are the two loop times, held apart rather than summed because they are fixed by
different things, and together they say how much of the frame never reached the renderer at all.
**The physics tick runs thirty times a second, so `physics`'s own reading is milliseconds per
tick**, not per frame — a frame drawn at thirty or more fps carries one tick, and a slower one can
carry two, so `physics` and `process` are not directly comparable the way two frame-rate figures
would be.

**`worst frame` is the longest single frame in that second, not an average of them.** "A bit
laggy" is a hitch, and a mean is the statistic a hitch hides in.

`FrameCost` (`src/telemetry/frame_cost.gd`) reads all of it off Godot's own `Performance` monitors
in one place, shared with the debug readout below so a number read off a phone's log and the same
number read off a desktop's screen cannot be assembled differently. **The render counters read
zero under `--headless`** — a null display server draws no frame to count — so measuring a frame
is a windowed `tools/shot.sh` run and never a suite; `tests/test_performance.gd` holds the shape
of the line and the agreement between the two places it is written from, which is all a headless
process can hold.

**It is timed off the frame clock rather than the day clock**, unlike every other per-second
thing here, because `--invincible` stands the day clock still on purpose and an interval measured
against it would write one line and then never advance — on exactly the runs a capture is most
likely to come from. The cost is that every line of such a run carries the same timestamp, which
is already true of every other entry there.

**And it is the one timed sample the log has**, which the last section of this file otherwise
rules out. The distinction is what a reader can recompute: where she was is reconstructable from
the entries around it, and what a frame cost on somebody else's phone is not recoverable from
anything at all.

### What a spike was

`frame` gives the engine's own per-second maximum, and the engine cannot say *when in the second*
that maximum fell or what the game was doing at the time. Under `--spikes`, the observer keeps the
same second's running mean of its own frame deltas — the mean of every frame already seen since
the last report, reusing `frame`'s own interval rather than a window of its own — and remembers
whichever frame ran past twice that mean, the worst one if more than one did:

```
  12.0  spike    38.4ms, mean 16.2ms — her tile changed to (44, 12)
```

**The mean is of the frames before the spike, not including it**, so a single long frame cannot
raise the bar it then has to clear. **At most one line a second**, the worst candidate — a slow
machine cannot fill the log with it, which is the whole reason it stays behind its own flag: a
`--spikes` run on a fast machine that never has a frame twice its neighbours writes none at all.

**What changed** is read off state the observer already holds for other entries — the tile
`_watch_the_ground` already looks up, the live event count `_watch_what_is_near` already scans,
`TextureResolver.load_count()`'s own static counter of transfer PNGs loaded from disk — never a
new per-frame hook added to a gameplay class. A late load reads:

```
  12.0  spike    38.4ms, mean 16.2ms — 1 pictures loaded
```

`"nothing else changed that frame"` means only that the watched tile, live count, picture loads
and collected atlases did not change. It cannot exclude other game work, or a retirement and
spawn that leave the live count unchanged. The legacy delta is simulation time; the counters on
the once-a-second `frame` line belong to the reporting frame. Use the raw trace below for temporal
attribution. `TextureResolver.warm()` loads every transfer before the day starts, so a `pictures
loaded` line in play means the warm pass missed one rather than that late loading is expected.

## Raw frame traces

`--frame-trace` adds an independent debug observer, including under `--no-telemetry`. It observes
the ordinary city day, after five seconds of initial active-play wall-clock warmup, with no RNG,
gameplay changes, per-frame printing or file writes. On scene exit (quit or restart), it exports
one JSON file under `user://frame-traces/` and prints its absolute path. A forced kill or crash
loses the in-memory capture. The ordered log's flush-on-entry policy does not apply to this
explicitly requested diagnostic file.

The clock is `Time.get_ticks_usec()` at `RenderingServer.frame_post_draw`: **a raw monotonic CPU
callback timestamp after render submission, not physical display presentation/scanout or GPU
time**. A threaded renderer can defer this callback; the trace records the thread-model setting
and command line so that configuration is visible. Draw, process and physics frame IDs identify
the engine state at the callback. Render counters are sampled at that callback, alongside the
world counters; `Performance.TIME_PROCESS` and `TIME_PHYSICS_PROCESS` are deliberately absent
because they are previous-second maxima, not costs of the sampled frame. The existing graph
continues to show simulation delta and the readout retains its separate labels.

Schema version 1 has `columns` naming the positional fields of every `samples` row, plus
`environment_start`, `environment_end` and `summary`. An interval ends at its row's timestamp;
its start is the preceding row's timestamp. A zero interval anchors each new segment. Pauses,
title screens and ended days break the segment, so idle time is not a hitch. Rows include render
draws/objects/primitives, live event count and instance-ID sum (a replacement can change the sum
without changing the count; it is not a collision-free identity record), crowd count, cumulative
picture loads and atlas collections, object/node/orphan counts, player position in thousandths of
a pixel, day, and the readout/graph/telemetry states. These describe coincident work; an unchanged
counter does not establish a cause or rule out unobserved work.

The buffer retains the **first 36,000 samples** in preallocated integer storage (6,336,000 bytes
for the sample payload). Once full it preserves those samples and increments
`dropped_after_capacity`; it does not overwrite the hitch or grow. Summaries cover retained
positive intervals only: nearest-rank p50, p95, p99 and max in milliseconds, plus counts strictly
above the 60 Hz, 30 Hz and reported display-refresh budgets. These are budget-exceeding callback
intervals, not a count of physically dropped display frames. Unknown refresh is `-1` in metadata
and gives a zero refresh budget/count. Metadata records driver-reported VSync mode (Godot's enum;
`-1` headless), display server, rendering method/driver, viewport/window sizes, engine version,
FPS cap, seed and both engine/user flags. The compositor can still pace independently of the
driver-reported VSync mode.

For a bounded capture-free walk, use `./tools/run.sh --frame-trace --after 20 --no-title
--seed 4242 --walk 3s17e`. With `--frame-trace` and `--after`, the input harness accepts walking
and timed key presses and quits without a screenshot; `--frame-trace` alone waits for your normal
quit. Engine flags for the pacing trials go before `--` in a direct Godot invocation.

For a controlled trial, keep the seed, walking script, duration and warmup fixed; record without
screenshots, bursts or `--invincible`. Compare layer `4` off/on, layer `6` off/on and telemetry
off/on separately. Then compare normal VSync, engine `--disable-vsync`, and engine `--max-fps 60`
as separate diagnostic trials, keeping the other controls fixed. Inspect the recorded positions
to verify the route moved, and reject a run with automatic telemetry captures during its measured
interval. Use a normal exit so the export runs. A pacing trial does not choose shipping settings.

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
   two things to grep for. `compass()` writes the exact bearing in whole degrees rather than a
   word — a press sets an arbitrary unit vector, so most headings are diagonal and a four- or
   eight-word vocabulary would lose the difference between two headings a player can tell
   apart. **+y is south**, so the bearing runs clockwise from north (-y) at 0°, through east
   (+x) at 90°, south (+y) at 180° and west (-x) at 270°, the same way a real compass reads.
   `nowhere` stays for a genuinely zero vector — the absence of a direction, not a rounded one.
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

So a run writes PNGs into its own `auto/` folder, named `<N><attempt suffix>-<what>.png` from a
counter — `003-attempt1-lost_crying.png` — rather than from the day clock: under `--invincible` the
clock never moves at all, so a clock-named picture would name itself identically to every other one
taken that same day; even off that flag, two pictures inside one in-game second collided the same
way. *(2026-09-11,
playtest 56: "phot capture must use real time not game time otherwise at the end of the day all
pictures get overwritten", then "actually why not just count up the screenshot numbers?".)* The
counter is `Telemetry._shot_serial`, shared with the person-requested pictures in `asked/` below so
a picture's own number says when in the run — relative to every picture the run took, from either
folder — it was taken; it counts from 1 for the life of the run and never resets, not even across a
retried attempt at the same day, so the counter itself cannot repeat a number. The attempt is named
on every one, including the first, the same rule "A day played twice" below states for the maps.
Three rules:

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

`P` (or `F9`) writes `<N><attempt suffix>-asked.png` — the same counter `snapshot()` uses, for the
same reason — into the run's own `asked/` folder, kept apart from the heuristic's `auto/` so a
directory listing already says which of the two asked for a picture — and
a `shot` entry beside it in `run.log`. `Telemetry.snapshot_now()` is the heuristic one with the two
limits taken off, and that is the
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

### Animation bursts

In a debug run, `B` (or the `snapshot_burst` action used by scripted rigs) starts one bounded
three-second capture in `asked/burst-<unique>/`. It writes `frame-0001.png` through at most
`frame-0036.png` and a `burst.json` beside them. The JSON has `schema_version` 1,
`target_fps` 12, the supplied `context`, `status`, `reason`, actual `duration_seconds`, and a
`frames` array whose `elapsed_seconds` values are measured at frame readback. PNG encoding happens
serially before the next frame is scheduled, so disk overhead appears in the timestamps and cannot
create an unbounded backlog. A second request is refused while one is active; a run or day ending
the capture leaves metadata with `status: "cancelled"` when possible. The target is not a promise
that every desktop reaches 12 fps; inspect the timestamps for the achieved timing. Headless and
unwritable runs are refused without fabricating images. Run `./tools/clip.sh` to scan the whole
telemetry folder and convert bursts whose sibling MP4 is missing, without deleting their PNGs.
The scan skips active captures and existing videos; ended partial sequences with frames are
eligible too. Pass a burst folder to select one sequence. If there is nothing to convert, the
command reports that and succeeds.

## The debug view

A trace and a snapshot both answer "what happened"; this answers "what does the game currently
think is true about this spot" — a field's own falloff boundary, the ground a shadow is drawn
over, and a collision body's own outline, all drawn in world space over the running game rather
than read back from a log afterwards. `DebugLayers` (`src/dev/debug_layers.gd`) queries the live
`EventInstance`s, `CrowdAgent`s, `Building`s, `Prop`s and the `Stroller` each frame and draws
outlines from what they answer; nothing about how any of them draws itself changes. `RouteLines`
(`src/dev/route_lines.gd`), the fifth layer below, answers a different question — not what the
game currently thinks is true this frame, but what it planned at the start of the day — and reads
`City.route_tree()` once rather than querying anything live. `FrameGraph` (`src/ui/frame_graph.gd`),
the sixth layer below, answers a third question again — not the ground truth and not the day's
plan, but what the last 240 frames actually cost — and reads `main._process`'s own `delta` each
frame it is on rather than querying the world at all.

Six layers, each a number key, read as a raw keycode rather than an input-map action so a release
build has nothing in `project.godot` to reach:

- **`1` fields** — every emitter's actual falloff boundary, inner and outer level, for events,
  walkers and cars alike, since all three run `Tuning.falloff()` through the same
  `GroundShape.field_outline()`/`field_outline_at()` arithmetic the falloff itself uses: a capsule
  about a stationary body's own spine, an ellipse (the emitter at one focus) about a moving one, a
  plain circle at zero speed — so this layer cannot disagree with what the meter does. A flock
  draws one pair per bird, at its own position and its own velocity, rather than one for the whole
  event. Amber (`Palette.MARK_COSTLY`) for a merely costly field, deep red (`Palette.MARK_LETHAL`)
  for a `hard_fail` event's — the same two colours the caret already uses, so this view speaks the
  vocabulary the game already has. A car's own noise field is always amber; its strike box, which
  is what actually ends the day, is in the bounding-box layer instead.
- **`2` shadows** — the ground extent every `GroundShape` shadow is drawn over: events, crowd
  agents, props, her and the pram. Buildings draw no shadow, so none is drawn for one here either.
  Traced from `GroundShape.shadow_outline()`, the same polygon `draw_shadow()` itself now fills, so
  the layer and the shadow cannot disagree.
- **`3` bounding boxes** — every enabled collision shape a body could touch, traced straight from
  the `CollisionShape2D`/`CollisionPolygon2D` nodes physics itself reads (`DebugLayers.
  collision_nodes_under()`), so the layer cannot omit one: an event's obstruction, a building's
  footprint, her own circle, the pram's own body, and a road closure's or the map boundary's own
  barrier. A moving car's strike box is drawn here too, in the lethal
  colour, because it is not a body but is exactly what ends the day on contact. Walkers and cars
  have no body of their own, and none is invented for them.
- **`4` the readout** — the seed, the meter breakdown and what the frame cost, drawn top right by
  `main.gd` and toggleable like the other three in a debug build: off, the string is not
  assembled, not merely hidden behind an invisible label. **A release build carries it too when
  the page's own `?debug=1` (or the command line's `--debug`) holds** — `DevFlags.readout_requested()`,
  parsed the same shape as `?svg=1` and not gated behind `enabled()`, the third bounded
  release-safe query flag beside it and `?telemetry=1` — and nothing else: the three geometry
  layers above, the snapshot key and every other dev flag stay behind `_debug` alone, so this flag
  reaches only the readout. Whenever it holds, a fixed "DEBUG MODE ON" note (`DebugModeNote`,
  `src/dev/debug_mode_note.gd`) is drawn for the whole session and answers to nothing that would
  take it off again — not the `4` key, not a press, not the title screen hiding `_status` around
  it — so a page reached with the flag on is never mistaken for the ordinary release page everyone
  else gets. The note carries the build stamp after its words and the readout's first line
  repeats it — `TitleScreen.build_text()`, `git describe`'s form and the commit, `v0.10.3
  (875609a5)` on a release — read from `git` on a working tree and from the two settings
  `tools/export-web.sh` bakes into an export, `application/config/version` and
  `application/config/source_commit`, so a screenshot of either says which code it is of.
  The same gate lets the page choose what the seed line itself reads: `?seed=N`
  (`DevFlags.seed_override()`) regenerates the city from a positive integer the way the command
  line's own `--seed` does, refusing `0`, a negative number, an empty value or anything else that
  is not a positive integer with a warning and falling back to a fresh seed instead — honoured
  only while `readout_requested()` already holds, so a release page nobody asked `?debug=1` of
  never takes a seed either. The command line's `--seed` takes precedence over the query form
  when both are present.
  Directly beneath the seed line, a `skip` line names what `--skip`/`?skip=` turned off — `events`,
  `crowd`, `shadows`, `motion`, comma-separated, any order (`DevFlags.skip_words()`) — turning the
  desktop's own per-frame draw probes (docs/DECISIONS.md, M124, "the desktop half", rows (e), (d)
  and (c)) into something a phone's own page can ask for, so a screenshot taken under the flag says
  what it measured; absent when nothing is skipped. `events`, `crowd` and `shadows` turn off a draw
  call each; `motion` (docs/DECISIONS.md, M140, "the crowd's scripts parked") turns off the crowd's
  own ticks instead — every agent's `_process` and `Crowd._physics_process` return before they run,
  so the street stands full of standing people and parked cars where the day placed them. Drawing,
  the events and the baby's own excitement read of the crowd are unchanged under `motion`, since
  that scan is the baby's and not the crowd's. Honoured only while `readout_requested()` already
  holds, the same gate as the rest of this bullet, so a release page nobody asked `?debug=1` of
  never skips anything either. The frame block is `FrameCost.readout_lines()` — `fps`, `draws`, `objects`,
  `primitives`, `process` and `physics`, the same six quantities and the same words the run log's
  own `frame` entry carries, assembled from the same readings so the screen and the log cannot
  disagree. See "What a frame cost" above for what each one says.
  **`process` and `physics` each carry three labelled columns, `last`, `mean` and `max`, rather
  than the log's own single reading** — `last` is `process_ms()`/`physics_ms()`, the same
  instantaneous last-frame number `line()` writes; `mean` and `max` are `FrameCost.sample()`'s
  own rolling one-second window, fed once a frame while the readout is on. **`mean` is what a
  still actually measures**: a screenshot lands on one arbitrary frame, and M124's own phone
  probe found the last-frame-alone reading swing between 21.7ms and 65.1ms on the same setting a
  few seconds apart (docs/DECISIONS.md, M124, "the phone's process time split"), so the mean over
  the second around it is the number a single still can stand behind. **`max` is what a stutter
  feels like**, the same argument the run log's own `worst frame` field makes for `line()` — a
  mean is exactly the statistic a hitch hides in. Before the window has taken its first sample,
  `mean` and `max` fall back to the same instantaneous reading as `last`, so the very first frame
  reports what it has rather than a zero that would read as free. `line()` itself is unchanged: it
  already writes once a second, at the interval the mean covers, so a mean over that same second
  would be no different a number.
- **`5` the day's routes** — one purple polyline per route the day's `RouteTree` offers, doorstep
  to calm area, over the centres of the two-tile reachability cells the tree actually grew on
  (`ReachabilityGrid`, docs/DECISIONS.md M69) rather than individual tiles — the tree keeps no
  record of which tile of a multi-tile cell a route crossed. Redrawn once at the start of a day
  (`RouteLines.refresh()`, called from `main._start_day()`), never per frame, because the plan it
  draws does not change until the next one is grown. Where branches share a trunk the lines
  overlap, which is the picture rather than a defect in it — see `RouteTree`'s own class doc on
  what sharing is for. The same purple `TelemetryMap` already draws the day's corridor in on the
  dusk map (`CORRIDOR_MARK`), so the live overlay and the dusk picture agree on what "the corridor"
  looks like.
- **`6` the spike view** — a rolling bar graph of the last 240 frames' own lengths (`FrameGraph`,
  `src/ui/frame_graph.gd`), sat directly under the readout's own block: what `process` and
  `physics` above cannot show, since both are the engine's own once-a-second worst (M138, above)
  and cannot say *which* frame in that second was the long one, or what the fourteen ordinary
  frames around it looked like. Fed from `main._process`'s own `delta`, not from `FrameCost`,
  because a number that already discarded 239 of the last 240 readings cannot be un-discarded. One
  bar per frame, one design pixel wide, newest at the right, in a 240 by 48 design-pixel box: height
  scaled so a 33.3ms (30fps) frame reaches the top and anything longer clips, with two thin
  reference lines at 16.7ms (labelled `60`) and 33.3ms (labelled `30`) and a third, unlabelled
  thin line at the window's own mean. A bar longer than 16.7ms is amber (`Palette.MARK_COSTLY`),
  longer than 33.3ms is deep red (`Palette.MARK_LETHAL`) — against the two drawn lines and never
  against the mean, so a second in which every frame is slow shows every bar as slow — the same two
  colours the caret, the badge and the `1` fields layer above already use, so this reads as the
  vocabulary the game already has rather than a third meaning for the same two colours — and every
  other bar is the readout's own text colour at half alpha. **Its own debug layer, independent of
  `4`** — *(2026-09-15, the player: "spike view should be independent of debug layer 4 it should
  be its own debug layer and turned off by default unless --spikes is set".)* Built only while
  `_debug or _readout_requested` holds, the readout's own gate, since it sits on the readout's
  layer and reads its text colour — but shown only while its own switch, `_layer_graph_on`, is on:
  off by default, `true` at boot when `--spikes` (`DevFlags.spikes_requested()`) was given or
  `--layers` names `6`, and flipped by the `6` key from there, whatever `4` does to the readout
  beside it. **Fed only while its own layer is on, and emptied the moment it goes off**
  (`FrameGraph.clear()`, called from `main._toggle_debug_layer()`) — *(2026-09-15, the player:
  "spike recording should only be on while the layer is on. that means toggling the layer twice
  will lead to a blank frame array".)* — so `6` twice leaves a blank graph that fills again only
  from that moment rather than a window that silently skipped the time it spent off. The run log's
  own `spike` line (see "What a frame cost" above) stays on `--spikes` alone regardless of `6`: it
  is the log's own line, not this view's recording.

The mapping above is printed once on boot in a debug build. With no `--layers` flag and no
`--spikes`, a run opens with the readout on and the other five layers off, so an unflagged debug
run looks exactly as it did before this existed. `--layers 1,3,5,6` (or the page's own
`?layers=1,3,5,6`) sets which of the five non-readout layers start on instead, so a rig screenshot
of a particular disagreement is reproducible without a keypress; a malformed entry is dropped with
a printed note rather than failing the whole flag. `4` is not part of that list — it defaults on
already. `--spikes` starts `6` on the same way, whether or not `--layers` also names it.

## The city grid

**A trace says where she was and cannot say what she was walking around.** Most questions asked of
a log turn out to be questions about the layout — how far the nearest calm area is, whether a
closure cut anything, which street the spine is, why a park was never reached — and answering one
from a list of tile coordinates is a thing nobody does twice.

So a run writes `day<NN>-attempt<N>.png` into its own `maps/` folder: one four-pixel square per
tile, coloured by tile type, with the home, the calm areas, the main road, today's closures, the
day's corridor, every event the day placed and — at dusk — the trail she actually walked marked
over it. `TelemetryMap` does the drawing.

**A day played twice writes two pictures.** A nerve retries a lost day without the calendar
advancing — `GameState.finish_day()` spends the nerve and gives the resistance's day back — so
`Telemetry.begin_day()` is called again with the day it just failed at, and it counts how many
times that has happened. Every attempt names itself, including the first —
`day06-attempt1.png` / `day06-attempt1-dusk.png`, then `day06-attempt2.png`,
`day06-attempt2-dusk.png` — so the retry does not overwrite the picture of the day that went
wrong, which is the one worth keeping, and every filename in the folder has the same shape rather
than the first attempt reading differently from the rest.

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

The picture also carries the day's **corridor** — `RouteTree`, the branch from the doorstep to
every calm area still worth reaching — as a **translucent violet** fill over every cell the tree
touches.

It is the one mark in the picture that is a **plan rather than a fact about the ground**, which is
why `render` takes it as an argument and draws nothing when there is none: a picture that invented
a plan when it was given none would be worse than a picture without one. `Telemetry.write_map`
grows one when the caller has none to hand, and that is safe rather than convenient —
`RouteTree.for_day` is a pure function of the city's seed, the day and what is shut, so the tree
drawn is the same tree anything else asking for today's would get, and growing it touches no
gameplay stream.

**Cells rather than a stroke down the middle of every street.** `RouteTree` grows on
`ReachabilityGrid` cells, so a strand can cut a corner through a park or take an alley — a tree
made of whole streets could only ever be drawn as one, and drawing cells instead is what lets the
picture show exactly the ground a branch actually uses rather than the street it happens to run
beside.

**Every cell on the tree is drawn the same, and the fill is mixed into the ground rather than laid
over it.** Drawing a bundled street solid white and two tiles wide puts a third of the map under a
colour that hides everything beneath it, and makes the shared trunk read as the subject of the
picture rather than as a property of it. Transparency is a **mix** rather than an alpha, because
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
| a white pip in the middle | whether she **met** it | drawn only once she has come within `outer_radius` — the field she can actually feel |

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
`day<NN>.png` at dawn is purely *what the day intended*; `day<NN>-dusk.png` is the same picture
with the placements she actually walked up to burnt into it. Neither is derivable from the other
and neither is the more useful one — a wall in the wrong place is visible in the first, and *a
corridor with nothing on it ever met* is visible only in the second.

**The pip is a mark added rather than strength taken away.** Fading what she never reached is the
obvious design and it answers the wrong question: a wall in the far corner of a map she never walked
into is still a wall in the wrong place, and it is the placement no trace can report — so the
picture would whisper exactly the thing it exists to shout. Drawn instead, every mark stays at full
strength and the ones she met carry the pip on top of it.

**Met means she came within the event's own `outer_radius`** — the field that actually reaches
her — not merely that `EventManager.stream_around` had loaded it into the world. Streaming happens
at `Tuning.EVENT_STREAM_RADIUS` (900px), more than twice the reach of a typical row, so a day where
she met eight of forty events and one where she was merely near forty are very different days, and
only the narrower question is the one worth answering. `TelemetryObserver._watch_met_events` keeps
the list; see "The trail" below for how it is carried to the picture.

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

**`docs/evidence/archive/session-captures/2026-09-02/rig-2026-09-02T233549-seed4242-3c6d4b4-dirty-map-day01-dusk.png`** is the trail
reading rather than being argued for: day 1 of seed 4242, walked from the real doorstep with
`AutoScreenshot`'s `--walk 3s15e` — three seconds of south to clear the notch, then fifteen of east
along the pavement. The trail turns once, south into east, and runs continuously for about forty
tiles before the script lets go and she stands where it left her; every tile of it is verified
against that run's own dawn map, pixel for pixel, so what differs between the two pictures is the
trail and nothing else. It crosses two zebras and a signalled crossing cleanly, which a single held
direction never could show: a bare `--walk south` from the same doorstep meets this city's traffic
within the first half-dozen tiles and comes back a speck, which is what every dusk map taken before
the scripted walk existed showed. It carries no `MET_MARK` pip — the only thing she came close
enough to, `cat_dash`, was sited ahead of her by the director rather than placed at dawn, so it has
no dawn position for a glyph to sit on. The pip itself is proven against a plan placed by
construction, in `tests/test_telemetry.gd`'s `_check_a_glyph_says_what_it_is`.

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

  **The `frame` entry is the one timed sample, and the test it passes is the same one.** What it
  records is not reconstructable from anything — not from the seed, not from the entries around
  it, not from a second run on another machine — because it is a fact about the device somebody
  was holding. A position is; a frame's cost on a stranger's phone is not.
