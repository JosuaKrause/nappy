## M44 — A suite you can run · `feature/a-suite-you-can-run`

**8.4 minutes to 96 seconds, with one check more than it started with.** The suite is the thing this
project checks most often, and at eight minutes it had stopped being run after each change and
started being run at the end — which tells you *that* something broke rather than *what*. M42's
larger lattice is what surfaced it: 7×7 to 9×9 took the suite from ~110s to 8.4 minutes, four times
the cost for 65% more city, and everything below was already there and already growing.

**The entry that asked for this proposed four things and every one of them was wrong**, which is the
part worth carrying. It guessed at cached maps, smaller seed sweeps, a fast/slow split and duplicated
per-day checks; the four suites it named as 90% of the cost were the right suites for the wrong
reason. Half an hour of a throwaway probe found something else entirely, and none of it cost a check.
**Time a thing before you speed it up** is a rule this project already applies to balance constants,
and it applies to its own tooling the same way.

- [x] **A rig that steps the parts is not running the whole** — 240 of the 495 seconds, inside a
      single test. `test_balance`'s day on the arterial walked the crowd by hand (`for agent in
      crowd.agents(): agent._process(step)`) and skipped the frame around them, so nothing ever
      rebuilt `TrafficIndex` — and `claim()` is written to be thrown away once a frame, so every
      recycle stayed. **64,796 cars in nineteen lanes after three thousand frames**, each one scanned
      six times per recycle, growing quadratically for the rest of the day. `Crowd.step()` is the
      whole frame and is what a rig calls now: 3.94 ms/frame at frame three thousand → **1.09**.

      **And it was not only slow, it was wrong**, which is why this is not a speed fix.
      `test_balance` and most of `test_crowd` were measuring a road with no separation pass on it
      while claiming to measure the real world. `tests/test_crowd.gd` now asserts the index holds
      exactly one entry per car, so the pathology cannot come back quietly — it never could have
      been seen otherwise, because a lane full of cars that left an hour ago is still a legal lane
- [x] **A cache whose lifetime is not stated is recomputed** — `EventScheduler._place_one` filtered
      every sidewalk tile in the city (five thousand of them, twice over) to find where an event may
      stand, and `_fill_with_recurring` asks that question **once per attempt** — over four hundred
      times on a fourteenth day. Nothing it depends on can move inside one `build_day`: the grid is
      repainted at dawn and the day's closures are already down. `_ground_for()` computes it once per
      distinct *question* — placement types plus side of the street, which most of the catalogue
      answers identically — threaded through the day rather than kept on the map, because a cache
      with a shorter life than its invalidation rule is the next bug. **`build_day` 515 → 71 ms**
- [x] **A `Vector2i`-keyed dictionary hashes a Variant per lookup** — `walk_distances` was the
      most-run arithmetic in the project (twice per generation attempt, once per day planned) and it
      asked a Dictionary about fifty thousand times what the tile grid answers by index.
      `CityMap.walk_field()` is the same sweep over a flat `PackedInt32Array`, with `blocked` painted
      into the grid before it starts rather than asked about per neighbour, and the four steps
      written out because the loop's own bounds test costs more than the arithmetic it guards.
      **16.3 → 4.5 ms.** `calm_tiles` and `count_walkable` lost their per-tile calls to the same
      pair of lookup tables — **8.9 → 0.6 ms**
- [x] **`CityGenerator.validate` does its cheap checks first** — it runs on every attempt, a third
      of them fail, and it opened with the two full sweeps of the map. A rejection that can be seen
      by counting calm blocks must not walk eleven thousand tiles twice first, and now does not walk
      them at all. Which reason comes back when several are true changes; whether a map is accepted
      does not. **`validate` on a map that passes 57.5 → 10.5 ms, and `generate` — 1.65 attempts of
      it, on average — 124.7 → 46.2 ms**
- [x] **`tools/test.sh crowd balance`** — the inner loop is now seconds. A filtered run prints
      `PARTIAL RUN` under its count, because a partial pass that reads like a green build is worse
      than no filter at all

| suite | before | after |
| --- | ---: | ---: |
| `test_balance.gd` | 255.1s | **25.6s** |
| `test_events.gd` | 74.6s | 12.7s |
| `test_crowd.gd` | 69.2s | 25.3s |
| `test_generator.gd` | 42.5s | 15.7s |
| `test_full_run.gd` | 18.8s | 4.4s |
| `test_telemetry.gd` | 12.6s | 2.1s |
| everything else, together | 22.2s | 10.3s |
| **whole suite** | **495s** | **96s** |

**What was deliberately not done.** No check was cut and no seed sweep shortened — every number
above is the same work done differently, which is why the count went *up* by one rather than down.
No map is cached across suites: a `CityMap` is mutable by design (a block arc repaints it, a day
closes streets on it) and sharing one between suites buys about seven seconds in exchange for a test
whose result depends on what ran before it. And `Crowd.step()` is the whole crowd frame minus the
player half — `_bump`, `_make_way`, `_strike`, `_horn` — which a rig with a stationary player would
also now be able to run. Whether `test_balance` *should* run it is a real question about what that
suite measures, and it is a design question rather than a speed one.
