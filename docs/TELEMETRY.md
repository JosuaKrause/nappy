# Nappy — Telemetry

What a run writes down, why each line is there, and how to read one.

Implemented in M23. The short version: **a run log is a chronological plain-text file that
records what the code cannot recompute.** It exists because several open questions in
`docs/TODO.md` and `docs/PLAYTEST-02.md` are questions about what actually happens to a
person playing, and nobody should have to have an opinion about those.

---

## Where the logs are

```sh
./tools/telemetry.sh          # print the newest run
./tools/telemetry.sh -f       # follow the run happening right now
./tools/telemetry.sh -l       # list them, newest first
./tools/telemetry.sh 3        # print the third-newest
```

Underneath, one file per run in `user://telemetry/`:

```
~/Library/Application Support/Godot/app_userdata/Nappy/telemetry/   (macOS)
~/.local/share/godot/app_userdata/Nappy/telemetry/                  (Linux)
```

The absolute path is also printed to stdout at the start of every run. Both the script and
the print exist for the same reason: a trace nobody can find is a trace nobody reads, and on
macOS the directory is inside `~/Library`, which Finder hides by default. Logs are named
`run-<timestamp>-seed<N>.log`, the newest fifty are kept and older ones are pruned —
`check.sh` and `shot.sh` boot the game too, and the directory would otherwise fill with
two-line traces of runs that never started.

**It is on by default.** `-- --no-telemetry` turns it off. A trace behind a flag is a trace
the person playtesting has to remember to turn on, which means the interesting run is the one
that was not recorded.

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

Random outcomes are the important half, and the reason is specific to this project: rolls
that depend on **run history** — a one-shot already consumed, a fire that only burns a block
because something burned there, a scar that exists because of what the player did — are not
recomputable from a seed at all without replaying the whole run with identical input. They
are the story of the run and they have to be written down as they happen.

## The entry kinds

Each one answers a question that is open in `docs/PLAYTEST-02.md` or `docs/TODO.md`. A new
kind has to be able to name the question it answers, or it is a metric and does not belong.

| Kind | Written by | Answers |
| --- | --- | --- |
| `plan` | `main.gd` | What today is: what is shut, where the calm is, what is out |
| `roll` | `EventScheduler`, `ResistanceDirector` | Which way a run-branching roll went, with the number and the threshold |
| `arc` | `CityState` | Which block became something else, and what caused it |
| `scar` | `EventManager` | Where the city stopped being recomputable |
| `contact` | `ResistanceDirector`, observer | Did the player ever find the difficulty dial *(decision 10)* |
| `start` | observer | Where the day began |
| `cross` | observer | Did the player have to cross the street, and at a zebra? *(finding 3, and M21 later)* |
| `calm` / `left` | observer | Same park every day? **M24 cannot be built without this one** |
| `near` | observer | How many entities were nearby, which, and how close — the cost table under finding 7 as what happened to a person |
| `closure` | observer | Are M16's closures a decision or scenery? |
| `turn` | observer | Did the player double back — and was it because of a barrier they had just seen? |
| `run` | observer | Did running help? Today the answer should always be "it made things worse" |
| `freeze` / `thaw` | observer | Was the day lost to noise or to the clock? Freezing is the invisible failure |
| `asleep` / `woke` | observer | How long the walk actually took, and what woke her |
| `quiet` | observer | The sabotage landed and the masts went off |
| `home` / `lost` | observer | The outcome, the margin, and what was around when it happened |
| `nerve` | `GameState` | Where the nerves went — which day, which act *(decisions 9, 11)* |
| `ending` | `GameState` | How the run finished |

### Reading the meter breakdown

Several kinds carry the same readout:

```
exc 35, in 15.4/s (crowd 0.0, events 6.1), sleep 5
```

`in` is the baby's **whole** incoming rate; `crowd` and `events` are the two spatial sources.
Whatever `in` exceeds them by came from the player — running, or standing in an alley. The
first version printed only the two sources, and a meter climbing on an empty street read as
`crowd 0.0, events 0.0`, which is true and hides that the player was doing it to themselves
with the run button. The three numbers are printed together so they always add up.

The crowd is ~530 agents and cannot be named one at a time. Which of the two is holding the
meter up is the whole question, and it is one subtraction.

---

## Three constraints on the implementation

All three are non-negotiable, and the first is an invariant in `CLAUDE.md`.

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

## What it deliberately does not do

- **No aggregates, no summary at the end of a run.** Both are computable from the log when
  reading it, and neither can be un-computed back into an order.
- **No per-agent crowd entries.** Five hundred and thirty agents would bury everything else.
  The crowd appears as its share of the meter, which is the thing being asked about it.
- **No `near` entries for `city_wide` sources.** A field with no edge cannot be approached.
  What the loudspeaker masts are doing shows up in every meter breakdown instead — which is
  also the most misleading gap in the game today, and `docs/TODO.md` has it under M10.
- **No sampling of the player's position on a timer.** Where they were is reconstructable
  from the entries, and a position every half second would be a metrics dump wearing a log's
  clothes.
