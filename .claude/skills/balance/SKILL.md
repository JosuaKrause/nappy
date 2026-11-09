---
name: balance
description: Rules for changing any balance or density number — event density, crowd density, Tuning constants — and the measured facts about what a route actually costs. Load this BEFORE editing src/autoload/tuning.gd, max_per_day, the view bags' shares (VIEW_SHARES), CROWD_*_PER_ACT, or any number a player can feel.
---

# Balance

**The rules not to miss:**

- **Every balance number is a named constant**, never a literal where gameplay can feel it.
- **Regenerate `docs/COSTS.md` in the same commit as any number that moves**: `tools/cost-table.sh`,
  then read `git diff docs/COSTS.md`. CI fails a balance change without it.
- **Never derive a density: measure what a day places**, over several seeds, with a probe.
- **When a test pushes back, decide whether the relationship or the number is wrong.** Do not just
  update the test, and never assert what a setting is (inbox #1173 in gray-dolphin).
- **A new free row, or a new row cheaper to run past, is a design decision**, not a number.
- **No city-wide "background noise" number**: the noise floor is the people and cars she can see.
- **A measurement that carries an argument is taken again**, not quoted.

**Every balance number is a named constant, never a literal where gameplay can feel it.** Where it lives
is decided by who reads it: only files under `src/` count, and a comment is not a read. A number two or more
`src/` files read, or that a function or constant of `src/autoload/tuning.gd` (`Tuning`) itself reads, lives
in `Tuning`. A number exactly one `src/` file reads is a `const` in that file (`CityGenerator.ALLEY_CHANCE`,
`Crowd.BUMP_RADIUS`), and tests and probes that read it name it through that file's class, so a test read
never makes it shared; a number only tests read stays in `Tuning`. Use
`rg "\bNAME\b" src tests` to find where one lives.

**Expect tests to push back.** Several encode *relationships*, not values — traffic noise must stay
under the walking decay; a fast mover must telegraph across its whole radius. If a test fails,
decide whether the relationship or the number is wrong. **Do not just update the test.**

A test never asserts what a setting is, and the relationship tests that encode any guarantee between settings
(fairness, the difficulty ramp, a derived number kept in step with its setting) stay (inbox #1173 in gray-dolphin;
**writing-tests**).

## Never derive a density — measure it

**Change the event density:** `max_per_day` in the catalogue **first**, then each view's share of
locations holding an event (`EventScheduler.VIEW_SHARES`, and `VIEW_SHARE_SCALES`, fitted per view and per day, for the
draws the rules leave empty, with `GROUND_WEIGHTS`, each row's weight per kind of ground, fitted
beside them so the mix holds), because **a share the catalogue cannot fill is not density**. Then **measure what
a day places**, over several seeds (`tests/probes/placement_view_mix.gd` per view,
`tests/probes/placement_rows.gd` row by row, on main and on the branch), since the day's rules
leave out whatever would close a route or reach unused calm (`StreetInvalidation`).

Each probe runs by its path, `tools/test.sh probes/placement_view_mix.gd`. A probe that prints
per-day counts is the only honest way to set a density; where neither checked-in probe prints the
count in question, a temporary one takes two minutes to write. **Measure four things and not one:**

- **placed per day**
- **live inside `EVENT_STREAM_RADIUS`**
- **on screen at once**
- **met on a route**

They move by different multiples, and only the last is what the player is complaining about.

## Two levers, and which one binds differs by day

A **cap** binds when the day reaches it. A **weight** binds when it does not, because a row is only
drawn as often as its weight. **Raising a cap the day never reaches does nothing at all** — that
is "a share the catalogue cannot fill is not density" at the other end.

## Ask what a number is *per*

The bags' shares are per location, because the target is per block: a bigger lattice lays out
more locations and draws more events. A flat count would be a statement about one lattice size and
nothing else: grow the city and the same events spread thinner, which is the density silently
falling while every constant still reads as correct.

The crowd is the deliberate opposite — it is a population of the **field** around the player rather
than of the city, so it does **not** scale with the lattice.

## Crowd density

`Tuning.CROWD_PEDESTRIANS_PER_ACT` / `CROWD_CARS_PER_ACT`, and `CrowdLanes.ARTERIAL_BUSYNESS`, which
is one street's share of the streets the player can see rather than of the whole city.

Then **measure it**, with a throwaway probe over a minute of a real day:

- how often there is a safe gap to cross the arterial, and an ordinary street
- the mean wait at the kerb
- contacts in a forty-second walk down a lane centre **and** holding the midline between two lanes
- whether any two cars share a lane closer than a car's length

A lane has a **capacity**, and past it the arterial jams solid and no controller helps. The
junctions have a capacity too, so the car number is not only a noise number — **measure the mean
speed and the stopped fraction alongside the floor**, or a road that reads as "busy" in a screenshot
is a car park in motion. The honest answer to "the main road is too quiet" can be **fewer cars**.

## What a route actually costs

**[`docs/COSTS.md`](../../../docs/COSTS.md) is the generated, checked-in table** — one line per
catalogue row: its geometry and role, the net rate while walking a fixed distance away, and the
net points from a real pass at `Tuning.WALK_SPEED`, awake and asleep. `tools/cost-table.sh` writes
it from the real `EventDef`/`EventInstance`/`Tuning` code the game charges with, never a second
copy of the falloff or the decay.

**This is how a balance change is read and reviewed.** Regenerate the table in the *same commit*
as any number that moves — `tools/cost-table.sh`, then `git diff docs/COSTS.md` — and read the
diff before asking anyone else to: it names every row a rate change touched and by how much.
`tools/cost-table.sh --check` is wired into CI and fails, naming what moved, if a balance change
lands without a regenerated table.

**The table prices a row *if you meet it*.** Whether a day makes you meet it, and how often, is the
four measurements under "Never derive a density — measure it" above.

**The measured facts behind the table are `references/route-costs.md`**, read before arguing from
it: why walking through an event costs (the falloff's shoulder), the two lists of rows allowed to be
free and the one row cheaper to run past (each a design decision to extend, held in
`tests/test_events_costs.gd`), what a rise in the walking decay does to a wide row, and the costs
the table does not cover (a contact, a horn, a solid body, the ground's own multiplier).

## The noise floor is emergent, never a constant

A street is loud because there are people and cars on it, which the player can see. **If you find
yourself adding a city-wide "background noise" number, that is the thing this rule exists to stop.**

## Re-measure rather than quote

A measurement in a doc has a shelf life, and a stale one reads exactly like a live one. **When a
number is load-bearing for an argument, take it again.**
