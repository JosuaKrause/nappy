# Handoff

**Last updated:** end of the M23 session.
**Read this first, then [PLAYTEST-02.md](PLAYTEST-02.md), then [TODO.md](TODO.md).**

---

## Where things are

`main` is green and playable. `./tools/test.sh` → **14963 checks, 0 failures** (~55s);
`./tools/check.sh` → OK; `./tools/run.sh` plays it; `./tools/telemetry.sh` says what the last
run actually did.

**The most important change since the last handoff is that arguments about the game can now
be settled by reading one.** Every run writes an ordered plain-text trace — see
[TELEMETRY.md](TELEMETRY.md). Before picking up anything below, play a day and read the log:
it is faster than any of the reasoning in this document, and several of the open questions
here are one run away from being answered rather than argued.

- **M0–M9 complete.** Full 14-day run, four-act escalation, resistance subquest, three
  endings. Documented in `docs/`.
- **M11–M15 complete.** Playtest 01's first five milestones: the quick wins, the SVG asset
  pipeline, the crowd as the noise floor, the M14 balance re-pitch, and block purposes with
  planned arcs.
- **M18 complete** *(taken out of order — see below)*. A day is 180s instead of 330s, aimed
  at **a minute of play with a grace of three**. Calm ground fills the meter in 24s instead
  of 119s: 10x the street rather than 3.5x, so a second in a park is worth ten on the
  pavement. Street gain went *up* (0.24 → 0.42), because M14's relationships are stated over
  `day_length()` and a 45% shorter day would otherwise have stopped making "real progress on
  the way" true.
- **M16 complete.** Road closures. Five kinds, 1–4 streets a day by act, barriers at both
  mouths so a shut street is readable from the junction, and the day-level invariant — at
  least two distinct routes to at least two distinct calm areas — checked by max flow on the
  junction graph before each closure is accepted.
- **M23 complete** *(taken out of order — it was the gate)*. A chronological run log in
  `user://telemetry/`, on by default, read with `./tools/telemetry.sh`. It records what the
  code cannot recompute: the random outcomes that branch a run, the seed the generator
  actually settled on, **the commit it ran on**, what the player did, what came near them,
  and how each day ended. **The gate is now open** — M19's balance half and M24 both have
  their data source.

## The decisions that govern the next milestones

Taken at the end of the M16/M18 session and easy to miss, because they are decisions rather
than code. All of them are written up in `PLAYTEST-02.md` (decisions 9–14).

1. **The beginning is challenging too.** Not extremely difficult, but a player who never
   meets danger never learns to deal with it. The measurement below says act I and act II
   currently cost nothing at all, and "the early game teaches events are safe, then act III
   kills you" is the worst of both. **M19 has to make an act I street cost something.**
2. **Difficulty is self-selected through the extra quests.** The resistance is the dial. That
   is why the base game has to be hard on its own — the dial *adds* difficulty, it does not
   supply it. Consequence: "how visible should the resistance be" stopped being a curiosity.
   A player who never finds the dial is locked to the easiest setting and never told there
   was one.
3. **The act I/II numbers are set from data, not argument.** Build the mechanisms (M19), ship
   telemetry (M23), read real runs, then pitch. This made M23 a gate rather than a
   recommendation, which is why it went first. **The gate is open** — M19's balance half is
   now waiting on runs, not on code.
4. **Telemetry is an ordered log, not a metrics dump** — what happened, in what order,
   readable top to bottom with no tool. It records what the code *cannot* recompute, above all
   the **random outcomes that branch a run** (a one-shot that fired, a block arc that
   advanced, an alley trap that was set): those depend on run history, so no seed reproduces
   them. Anything derivable from the seed, `Tuning` or the catalogue stays out. *(Shipped in
   M23; [TELEMETRY.md](TELEMETRY.md) is the version to work from now.)*
5. **The resistance stays hidden and loses its key.** *(Closes an open question carried since
   M8.)* No marker, no quest log — wanting the difficulty dial and finding it are the same
   behaviour. But `E` appears in exactly one line of the game, so the hold becomes automatic
   on proximity: the cost was always standing still in an alley, never the keypress. M26.

## Read this before touching the event or signalling code

Two measured facts came out of the end of this session. Neither is a bug; both change what
the next milestones are for, and both are easy to rediscover the hard way.

**Walking through an event is nearly free before act III.** Eleven of eighteen events cost
under fifteen points of a hundred-point meter to walk straight through the middle of, and
three are *negative* — walking through a `dog_walker` is better than walking around it,
because the 3.5/s walking decay outruns what it emits. The full table is in
`docs/EVENTS.md`, "What an event actually costs". Regenerate it whenever a rate in `Tuning`
moves.

**Running is the wrong move against every event in the game.** `EXCITEMENT_FROM_RUNNING`
(9/s) plus the collapsed decay (3.5/s → 0.5/s) beats the shorter exposure in every single
case. The run button is currently a trap. This is why M25 is written as a mechanic to build
rather than a constant to tune.

**No circles.** The aura rings are being deleted, not restyled (M22), and `CLAUDE.md` carries
that as a standing rule next to the invariants. They only ever covered events —
the ~530 crowd agents have no ring, and two `city_wide` sources have none either — so on a
normal street most of what you can see is unmarked and nothing explains the difference. The
replacement lives in the entity plus a small symbol vocabulary. The one thing to preserve:
the ring *breathes* with the pulse envelope, which is what makes a pulsing event timeable.

## A second playtest landed mid-session

Six findings, written up with analysis and sequencing in **[PLAYTEST-02.md](PLAYTEST-02.md)**.
The short version: **the loop is right and the street is empty of consequence.** Read that
document before picking anything up; the summary below is not a substitute for it.

Two things about the ordering, because neither is obvious from the numbers:

- **The queue is M17, then M18–M26**, and M18 and M23 are already done. Findings 7–12 arrived
  as a follow-up read of the same playtest and are written up in the same document. The new
  findings were deliberately queued *behind* the milestones in flight rather than in front of
  them. Two have jumped the queue since, each for one practical reason: **M18**, because
  closure counts tuned against a day that was about to halve would have been tuned wrong, and
  **M23**, because it was the gate on M19's balance half and on M24 and it makes judging
  everything else cheaper.
- **M22 wants pulling forward next to M19.** It is filed later because that is where it was
  asked for, but a lethal car arriving from off-screen is a breach of the telegraph fairness
  contract rather than a polish item, and M19 is what creates them.

## What to do next, in order

### First: play a day and read the log

Not a milestone, and it costs three minutes. Several of the open questions in `TODO.md` — is
the nerve economy right, does anybody ever find the resistance, is anything standing between
the player and a won day — are now questions about a file rather than about a design. Do this
before picking up M17, because the answer may reorder what follows it.

### M17 — the route map

The planning screen, rendering the block states M15 introduced *and* the closures M16 adds.
`CityState.changed_on(block)` is already recorded for exactly this — shading "this is new" is
what makes the screen worth opening twice.

M16 raised the value of this: closures are legible at the junction and **not** before it. A
player two junctions away cannot know a street is shut, and the map is the only thing that
can tell them. That gap is stated as a gap in `docs/CITY.md` rather than papered over.

M23 raised it again, and gave it a test: the log's `closure` entries say where a barrier was
seen from, and a `turn` following one says whether it changed the plan. If closures read as
scenery in the traces, that is the argument for the map screen — and afterwards, the same two
entries are how to tell whether the map fixed it.

### Then M18–M26, per PLAYTEST-02.md

M18 and M23 done. **M19 bodies on the street** (collision, lethal cars, pavement hazards that
force a crossing, cars that stop at zebras) — the big one, and the thing that makes M18's
generous meter honest, and the thing the cost table above says the early acts badly need. Its
balance half is no longer blocked: set the numbers from what the traces say, per decision 11.
**M20 traffic that behaves** (following, overtaking, 8-direction driving, crashes as events).
**M21 the city overhaul** (four-block calm zones, T-junctions and L-bends, main roads as
barriers, plus the canal dropped out of M16). **M22 danger you can read** (the circles go;
entity, symbol, screen edge, and a symbol over the player when they are too close).
**M24 the city remembers where you went** (spoil the park you relied on yesterday) — the
`calm` entries it needs are being written now. **M25 patrols, and running that matters** — the
`run` entries are the measurement it will be judged by, and today they all say the same thing.
**M26 teaching the controls** — delete the interact key, then teach walking and running,
ending in a scripted day-1 event that requires a short run. M26 must come after M25 for
correctness, not scheduling: forcing a run before running is ever the right answer teaches a
move that is never correct again.

M21 rewrites the lattice enumeration in `src/routes/street_network.gd`. The graph half of
that file — route counting, the invariant, the doorway exemptions — survives untouched and
matters *more* afterwards: with holes in the lattice, route redundancy stops being true by
construction and has to be checked by search, which is what that file is.

---

## Standing decisions

Taken in the M12a session and still governing everything after it. All four are recorded in
`PLAYTEST-01.md`; repeated here because they change the design.

1. **Assets are SVG.** Confirmed. Graphics get refined later — *"for now we need something
   workable"*, so do not gold-plate the art. Generating images or using freely-licensed
   assets is also acceptable.
2. **An ordinary street makes sleep progress, but never enough** to finish a day alone.
   A day must be unwinnable on street gain and comfortably winnable with one calm stretch.
3. **Finding 12 narrows the route choice, it does not remove it.** Not a single forced path
   — several viable routes and *several quiet destinations to choose between*. The day-level
   invariant to enforce in M16: at least two distinct routes to at least two distinct calm
   areas.
4. **The city is mutable day to day, by recontextualising areas.** *(Implemented in M15.)*
   The generator plans each block's *purpose arc* up front so blocks transition coherently.
   This **superseded the "`CityMap` is immutable for the run" invariant in `CLAUDE.md`** —
   replaced by: the street lattice and block boundaries are fixed; what a block *is* may
   change, only along its planned arc. Rendering reads block state, so `City.start_day()`
   repaints the ground and re-dresses the blocks every morning.

---

## Gotchas learned in M23

- **A green suite says nothing about whether a log is any good.** The observer passed every
  test and its first trace of a minute's actual walking had four defects in it: a `run` entry
  claiming a six-hundred-pixel event was "in reach", two instances of the same event that the
  log could not tell apart, a duplicated field, and — the bad one — a meter breakdown reading
  `crowd 0.0, events 0.0` while excitement climbed, because the player was doing it to
  themselves with the run button and nothing said so. This is the screenshot rule with a
  different output format, and it is now in `CLAUDE.md` next to it.
- **The breakdown has to add up or it lies by omission.** Printing the two spatial sources was
  true and useless. It prints the baby's whole incoming rate alongside them now, so whatever
  the remainder is — running, an alley — is visible as a remainder.
- **Hoisting a roll to print it is the dangerous edit.** `if rng.randf() > threshold` becoming
  `var roll := rng.randf()` is identical, and *nearly* the same edit that consumes an extra
  value and moves every event placed afterwards. `tests/test_telemetry.gd` plans all fourteen
  days twice, with the log off and on, and compares event ids and positions to the pixel.
- **Telemetry must be inert by default, not disabled by a flag.** The suite creates schedulers
  and city states directly; if the log were on by default it would write a file per check.
  `Telemetry` is dormant until `begin_run()`, which only `main.gd` calls — so the suite pays a
  boolean and the game gets a trace with no flag to remember. The observer is not even added
  to the tree when telemetry is off.
- **A roll that passes and then fails to place is invisible.** `_place_one_shots` can roll a
  one-shot in and then find nowhere to put it, in which case it is *not* consumed and gets
  rolled again tomorrow. From outside that is indistinguishable from a roll that failed, so it
  gets its own line.
- **`user://` is somewhere nobody can find.** On macOS it is inside `~/Library`, which Finder
  hides. The path is printed at the start of every run *and* `tools/telemetry.sh` exists, and
  it still took someone asking where the logs were. Neither was sufficient alone.
- **macOS ships bash 3.2, so no `mapfile`.** `tools/telemetry.sh` reads `ls -t` in a `while`
  loop instead, like the rest of `tools/`.

## Gotchas learned in M16

- **Check before accepting, not after placing.** The obvious shape for closures — place N,
  then drop them until the day is legal — has an order-dependent answer and a window in
  which the day is illegal. Testing each candidate against the invariant *before* accepting
  it costs the same and has neither problem. The reason it is affordable is the next point.
- **Counting distinct routes is a max flow, not a search for routes.** Two edge-disjoint
  paths is what "two distinct routes" means, and by Menger's theorem the count is also "how
  many streets it would take to cut this off". Two BFS augmentations over a 64-node junction
  graph — not a flood fill over ten thousand tiles — which is why it can run on every
  candidate closure of every day inside a test suite.
- **A doorway is not a route, and that has to be said out loud.** The first version of the
  brute-force cross-check closed every street in turn and asserted the area survived. It
  failed on three courtyards, correctly: a courtyard has one archway onto one street.
  Two routes has always meant two routes *to the door* — the same exemption the home has
  had since M3 — and the test now excludes access streets and carries a second test that
  states the consequence rather than leaving it implicit.
- **A cross-script enum is not the same type as itself.** `f(side: Side)` called from
  another script with a `StreetNetwork.Side` value fails to parse. Widen to `int`.
- **The crowd made the closure legible for free.** Agents divert at the junction rather than
  driving through a barrier, so the street with nobody on it is the street that is shut —
  which reads from a block away, further than the barrier does. That was a side effect of
  making the crowd respect closures, and it is better than the thing it fell out of.

## Gotchas learned in M18

- **Cutting the day tests the tests.** Every M14 balance claim is written as a relationship
  over `day_length()`, and halving the day is exactly the change those relationships exist
  to survive. They did: nothing needed its shape changed, and the one that pushed back —
  "a whole day of street walking still makes real progress" — pushed back correctly, which
  is why street gain went *up* while the day got shorter.
- **A shorter day is a faster suite.** `tests/test_balance.gd` steps a real `Baby` through
  fourteen days at 1/60s; it went from 94s to 27s for free.

## Gotchas learned in M15

- **A carved interior needs a way in.** Courtyards were sealed rects the first time and the
  connectivity check failed on *every seed*. The archway is now part of `BlockLayout`, and
  it is paved as an alley on purpose: reaching hidden calm costs a few seconds of somewhere
  you would rather not be.
- **Put arc invariants in the arc, not in the callers.** A commercial block could be planned
  to go dark on day 10 and then burn on day 3, because two independent rolls wrote their own
  `from_day`. `BlockPlan.then()` now clamps each step to at least the previous step's day.
  `tests/test_blocks.gd` found it on 13 of 24 seeds.
- **Protect the calm ground, not the block.** `_ensure_one_usable_park` matched events
  against the whole block lot. For a courtyard — four tiles inside a residential block —
  that stripped every event off streets the player was never going to settle on. It matches
  `BlockLayout.open_rect` now.
- **Calm ground must not read as a rooftop.** From above, the first quiet-square paving was
  the same warm beige as the building roofs. Since M14 finding calm ground is the whole
  game, so the tile is deliberately cooler than anything else in the palette. This will
  matter more in M17, where the map screen *is* the view.
- **`var x := SomeEnum.keys()[i]` will not parse.** The value is a Variant, and "inferred
  from a Variant value" is an error, not a warning. Annotate: `var x: String = ...`.

## Known slow: `tests/test_generator.gd` is 21s of the suite's 55s

Per-suite timings are printed by `tools/test.sh`. `test_generator.gd` generates 200 cities
and runs a route-redundancy sweep that closes each street segment in turn on the *tile* grid.
`test_balance.gd` is next at 27s (down from 94s when M18 shortened the day).

The generator sweep is now the obvious thing to speed up, and M16 has already written the
tool: `StreetNetwork.route_count()` answers the same question by max flow on the junction
graph in a fraction of the time. It has deliberately not been swapped in — the tile-level
sweep checks something the graph cannot, namely that the *tiles* agree with the lattice — but
if the suite needs to get faster, running the cheap check on all 200 seeds and the expensive
one on a handful would be honest.

## Gotchas learned in M14

- **Pitch balance numbers against the day, not against each other.** The old numbers were
  all mutually consistent and the day was still winnable by circling the block, because
  nothing tied the fill rate to `day_length()`. The two tests that matter now are written
  as `GAIN * day_length(day) < METER_MAX` and `METER_MAX / calm_gain < day_length * 0.6`,
  so lengthening the day cannot quietly make the street sufficient again.
- **Arithmetic is necessary and not sufficient.** Whether a park fills the meter depends on
  whether the crowd pushes it over the freeze threshold, which no data-level test can see.
  `tests/test_balance.gd` stands a real `Baby` in a real city with that day's crowd and
  events. It is what caught that the claim needed checking on all fourteen days, not one.
- **Check the short day.** A calm stretch of 139s looked fine against the 330s day and was a
  stopwatch race against the 264s curfew one. Every balance claim here is measured against
  `day_length(RUN_LENGTH_DAYS)`.

## Gotchas learned in M13

- **A runtime error in a test suite hangs the runner; it does not fail it.** `run_tests.gd`
  calls each suite synchronously and quits at the end, so an error aborts `_ready()` before
  the quit and the headless process sits there printing nothing. Deleting `busy_road` left
  three suites calling `by_id("busy_road").intensity`, and the symptom was a test run that
  produced *no output at all* for six minutes. No output means an error, not a slow suite.
- **A negative-width `Rect2` normalises** — already in `CLAUDE.md` from M12c, and it bit
  again here: it is the same helper the whole crowd draws through.
- **Moving a `Node2D` does not invalidate its draw list.** The transform is applied when the
  retained list is replayed, so 530 agents only need `queue_redraw()` when their *picture*
  changes — a turn, a flip — not when they move. That is the difference between 530 redraws
  a frame and a handful.
- **Give each agent its own RNG.** Seeded per agent from the day, not shared, so a turn
  taken at a junction cannot depend on the order agents happen to reach junctions in — which
  frame timing would otherwise decide, and determinism would be a lie.

## Gotchas learned in M12c

- **A negative-width `Rect2` does not flip `draw_texture_rect`** — it is normalised, so the
  sprite lands a full width sideways. It reads as art sliding off its own shadow rather than
  as a failed flip, which is how it was found. `Sprites.draw_standing()` mirrors the
  transform around the anchor instead, and is the only place that does.
- **A sprite cannot swing its own legs.** The mother's gait was a procedural stride and a
  bob; with the legs drawn into the art, both had to become a two-frame swap. The bob is
  baked into the second frame rather than added on top, or the two would compound.
- **Deleting the colours was part of the job.** Two thirds of `Palette` no longer painted
  anything once the art moved into SVG, and a constant that looks authoritative but controls
  nothing is a trap for whoever tries to retint the game next. What stayed is what the code
  still picks at runtime: light, act cast, aura, chalk, shadow, building variant.

## Gotchas learned in M12b

- **Edge overlays beat corner tiles.** The roof parapet is four edge tiles drawn on top of
  the roof fill, each transparent apart from its own band. A corner cell takes two of them
  and the parapet turns by itself — no corner tiles, and no combinatorial explosion when a
  roof is only one tile deep and a row has to be both its north and its south edge.
- **Multiply the colour, not the art.** Wall and roof fills are authored near-white and
  passed the variant colour as `draw_texture`'s modulate, so six roof colours cost one
  asset. Windows are drawn *after*, unmodulated: a lit window is the same warm colour
  whatever the building is painted.

## Gotchas learned in M12a

Beyond the ones already in `CLAUDE.md`:

- **`Sprite2D` with `centered = false` puts the node at the sprite's top-left.** Y-sorting
  then compares the wrong edge. Everything in this project is feet-anchored: put the node on
  the ground plane and use `offset` to draw upward.
- **A y-sort tie is broken by tree order.** The front door sits in the wall of the building
  above it at exactly the same `y`, so it has to be added to the tree *after* the buildings.
- **A tile cannot carry a line that falls on its own edge.** The road centre line sits on the
  seam between the two carriageway tiles, so it is authored as two halves that meet
  (`road_line_e`/`_w`, `road_line_n`/`_s`).

## How the asset pipeline is put together

- `assets/tiles/*.svg` — 17 ground tiles, 32×32, hand-editable. **There is no regeneration
  script**; they were emitted once and are now the source of truth.
- `assets/ground_tileset.tres` — one `TileSetAtlasSource` per tile. **Source ids are
  positional and `src/city/ground_tiles.gd` mirrors them by hand.** Adding a tile means
  appending to both, in the same order.
- `src/city/ground_tiles.gd` — the only place that decides which tile a cell gets.
- `assets/buildings/*.svg` — 11 building tiles, 32×32. `wall`/`roof` are fills (modulated);
  `wall_edge_*`, `wall_base`, `roof_edge_*`, `window_*` are alpha overlays drawn on top at
  full colour. No `TileSet` here: `Building._draw()` assembles them per lot, which keeps one
  node per building and lets a lot pick its own colour.
- `assets/rig/`, `assets/props/`, `assets/events/` — feet-anchored sprites, drawn through
  `Sprites.draw_standing()`: the node sits on the ground plane, the art rises from it.
  Anything whose size carries meaning (a fire's flames, a barrier's width) passes an
  explicit size rather than using the texture's own.

Run `./tools/check.sh` after touching assets; it does the import pass that generates
`.import` files.

---

## Working agreement

From `CLAUDE.md`, which is the fuller version:

- Feature branch per milestone, `--no-ff` merge to `main` when green.
- Run `check.sh`, `test.sh`, and a `shot.sh` screenshot before committing anything visual.
  A green `check.sh` says nothing about whether the game looks right.
- Commit the docs in the same commit as the code.
- Update **this file** at the end of each work session.
