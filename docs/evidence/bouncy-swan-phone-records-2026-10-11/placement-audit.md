# Event placement: does it always complete, and within what bound

An audit of every loop, retry and search that places, sites, warns of or defers an event: in
`src/events/`, and in what those call to decide a placement. Asked for by the player in inbox #701
(velvet-marten): *"the lag spike explanation might also be the explanation for the soft lock --
let's audit the placement code for guaranteed and bounded completion"*. It is the bouncy-swan item
"event placement completes, always and within a bound".

For each site the table gives four things:

- what it does and how often it runs;
- why it terminates;
- its worst-case work per call;
- whether a refusal can repeat every look or every frame for as long as the day lasts, and what it
  holds up while it repeats.

The line numbers are those of this branch's last commit.

**Words used below.**

- **A look** is one pass of `EventDirector.site_what_is_on_her_way()`. It runs once per second of
  her walking (`ON_HER_WAY_LOOK`), from 18s of walking (`ON_HER_WAY_AFTER`) and 400px from home.
  Each pass asks `WalkSiting.ahead_of()` for every place still owed: the day-3 fire, the day's
  poster crews, and a place a marble from her route's bag names.
- **A judgement** is one run of the rule chain `EventScheduler._judge()` on one candidate against
  every plan of the day. The chain covers a pacing row's role, the protected calm, the doors' clear
  ground, the route junctions, the walked sidewalk, a pacing beat's opening, and `_room_around()`'s
  spacing.
- **Plans** means `EventManager._plans`: the catalogue rows, the seals and the region wall's
  bodies. There are 357 of them on seed 67's day 9 and 432 on seed 13's day 12.
- **The phone factor** is 2.7. The day-9 stall cost 748ms of `events` on the phone and 275–292ms
  on the Apple M2. It is one frame's ratio, used to say roughly what a desktop figure would cost on
  the player's phone, not a measured conversion.

## What it found

1. **No placement loop can run for ever.** Every loop is one of three kinds:
   - a counter: `EVENT_PLACEMENT_TRIES` (24), `budget * 4`, `ROUTE_SKIP_LIMIT` (64),
     `TRAP_DRAW_LIMIT` (24);
   - a walk over a finite list;
   - a search with a cap (`WAY_ON_SEARCH_LIMIT` 4096, `ROUTE_SEARCH_LIMIT` 6000, `_WALK_STEP_LIMIT`
     20000).

   Three loops instead end on an argument about their inputs, and all three hold:
   - `PendingWarning.on_its_route()`: `up` grows each step and the road is finite;
   - `PendingWarning.route_down_her_line()`: `behind` steps toward `place`;
   - `_ensure_the_city_is_still_walkable()`: pops a finite list.

   **A fourth relied on how its caller built the path, and is now bounded here.**
   `EventScheduler._a_beat_reaches_a_way_out()` walked a pacing beat with `while true` until it
   landed on the beat's far end. A beat laid along one axis lands there. One that did not would have
   stepped past the far end and gone on until something else stopped it. It now walks at most the
   run's own length, which is the same walk for every beat `_along_street_path()` lays.

2. **What repeats is a refusal.** It repeats once per look, once per second of walking, or once per
   frame, and nothing it holds up is needed for the day to end. Every repeating refusal holds up
   one of these:
   - the place being sited: a crew, the day-3 fire, or a route place (the man shouting, a mast,
     day 7's van);
   - the moments queued behind the head of the director's owed list;
   - the fire engine's arrival;
   - a pursuer owed again;
   - day 13's column;
   - a leaving body's way out of her sight.

   What still ends:
   - the clock and the meter: none of these stops the day's clock or the baby's meter;
   - the way home: none of them stands a body in it;
   - day 3's fire: a won day 3 lights the fire at dusk;
   - a mast task: falls back to the nearest live mast;
   - day 13's task roadblock: falls back to the old live spawn.

   So none of these sites can hold a day where it cannot end. The softlock risk is cost: **a
   refusal that is expensive and repeats every look takes the frame away from her as surely as a
   loop would.**

3. **The look is that cost, and it was large enough to read as a lock.** Before this branch, every
   copy still owed in a look ran `_best_of()`: 24 rolls, and a judgement on each roll even when the
   pool held one tile. A look with every copy unplaced and every offered tile refused therefore cost
   copies × 24 judgements.

   On day 12 a judgement costs 3.5–5ms against 432 plans, and about 10 crews were owed. Before the
   change, a look there was copies × 24 × 4ms: 0.7–1.0s on the M2, about 2–3 seconds on the phone.
   That cost came back on every look in a row while the band offered a handful of refused tiles.

4. **This branch takes both factors out of the look.**
   - `_best_of()` judges each distinct candidate once per call.
   - `WalkSiting` works out a look's offer once rather than once per copy, the widening that finds
     nothing included.
   - Inside a look, the copies share their verdicts (`WalkSiting.begin_look()`). The rule chain
     reads only the placed plans, so every copy asked against the same placed plans asks the same
     question. The director drops the verdicts when the look places or moves a plan, and around
     asking about a plan already placed, which is judged without its own body.

   A look now makes at most one judgement per distinct candidate offered, plus a fresh set after
   each plan it places or moves. Every copy still rolls, so every placement stays the same. The
   measurements were taken on an Apple M2, headless, Godot 4.7.2, one session per step, each step's
   after against its own before (the second session ran slower on both revisions while another
   probe shared the machine):

   | Look | Before | After step 1 (per call, the offer once) | After both steps (the look shares its verdicts) | Both steps, × phone factor |
   |---|---|---|---|---|
   | Day 9, seed 67, the phone's own track: its stalled look | 275–292ms; 545–860ms in the second session | 14.9ms, 12 judgements | 7.2–8.4ms, 1 judgement | ~20ms |
   | Day 12, seed 13, `--route mark,task,home` after the swing, without `--invincible`: the worst looks | 453–744ms; 334–628ms in the second session | 52–168ms | at most 16.7ms over the whole run | ~45ms |
   | The same under `--invincible`, look time only (the flag does not run inside a look): eleven looks in a row | 0.64–1.14s; 0.51–0.66s in the second session | 0.05–0.26s | at most 14.8ms over the whole run | ~40ms |

   [README.md](README.md) has the method, the per-look and per-tick distributions and the identity
   checks.

   **The ceiling** is a look whose band offers many distinct refused tiles. Each of them is judged
   once, not once per copy. A one-time cost stays per copy: copying the day's plans for its ask and
   rolling, about 0.24ms on day 9.

5. **Dawn work that rescanned the city per candidate is now done once.** Neither change moves a
   placement.
   - `MastSites` rebuilt every region boundary's door points for each of a few hundred candidate
     sites; it now builds them once per `compute()`.
   - The alley mouse's sack piles were a scan of every tile of the map on each roll for the mouse;
     they are now found once a day.

   One dawn cost stays, for a reason on record: the fill's judgements grow with the plans already
   placed, about budget × 4 attempts × 24 judgements × the plans so far. That is quadratic in the
   day's density. It is paid inside the day's load, and a spatial index is a recorded non-choice
   (the events skill, "No spatial hash").

## The day-12 softlock

azure-koala's finding 9: *"day 12 after closing the park and walking back with sleeping baby
softlocks the game"*. It was said on v0.25.4 or earlier. **It is very likely this family.** The
reasons:

- **The code was there.** v0.25.4 has the same per-copy `_best_of()` with 24 judging tries
  (`event_scheduler.gd:1655` at that tag), the same one-crew-at-a-time wait
  (`EventDirector._waits_its_turn()`), and the same one-second look.
- **Day 12 is where it is worst.** Day 12 has more plans than day 9 (432 against 357 on these
  seeds), and its judgements cost about four times as much. The look repeats while she walks away
  from the park:
  - on seed 13 with the current cordon, before this branch, looks of 0.45–0.74s on the M2 came
    back to back within seconds of the swing, and under `--invincible`, walking on, eleven looks in
    a row cost 0.64–1.14s each;
  - that is about 1.7–3 seconds per second of walking on the phone, before any drawing, where the
    branch now takes at most 17ms on the M2;
  - a game that gives her 1s of walking for every 2s frozen reads as locked.
- **It wears off, so it reads as a lock while she keeps walking.** A look is not repeated while she
  stands still. A placed crew makes the others wait. Any site that is accepted ends the run of
  refusals.
- **Nothing in the code can lock the game outright.** Section 1 shows every loop is bounded. So if
  the report was a game that never came back, rather than one that froze while she walked, this
  family does not explain it.
- **What is not shown.** The rings repainted the park's ground, so v0.25.4's day 12 cannot be
  replayed on the current build (plush-marten's cordon replaced them). The sleeping-baby walk home
  was not measured on the phone. A frame record of day 12 on the phone would settle it.

## The sites

### A. The dawn plan (`EventScheduler.build_day()` and what it calls)

All of these run inside the day's load, once per `build_day()`. None repeats during the walk.

| Site | What it does | Terminates because | Worst-case work per call | Can a refusal repeat; what it holds up |
|---|---|---|---|---|
| `event_scheduler.gd:1791` `_fill_with_recurring()` | Weighted roll, then `_place_one()`, until the day's budget is spent | `for attempt in budget * 4`; stops early on a spent budget or nothing affordable | budget × 4 × (`_best_of()`). Budget is about 200 on day 1 and 400 on day 14 | No; a refused attempt spends no budget |
| `event_scheduler.gd:1934` `_best_of()` | Rolls 24 candidates from a pool, judges each distinct one once, takes the first perfect or the roomiest | `for _try in Tuning.EVENT_PLACEMENT_TRIES` (24) | ≤ 24 judgements; at dawn the pools are thousands of tiles, so nearly 24 | Null when every candidate is refused; the caller decides |
| `event_scheduler.gd:1967` `_judge()` | The rule chain on one candidate | Straight-line code; each rule loops over `already` or a bounded fill | O(plans) plus fills of at most a 6×6 box and a sidewalk run | n/a |
| `event_scheduler.gd:2706` `_a_beat_reaches_a_way_out()` | Whether a pacing beat passes a junction or a side route | `for _step in maxi(abs dx, abs dy) + 1`; **bounded on this branch**, where it was `while true` until landing on the far end | ≤ the beat's length in tiles | n/a |
| `event_scheduler.gd:2107` `_prefer_beside_a_sack_pile()` | Extra copies of alley tiles beside a sack pile, for the mouse | Finite lists | Candidates × piles. **The full-map pile scan now runs once a day**, not once per roll | n/a |
| `mast_sites.gd:31` `MastSites.compute()` | Six mast sites by farthest-point sampling | `while chosen.size() < MAST_COUNT and not candidates.is_empty()`, removing one each pass | Candidates × 6. **Door points are now built once**, not once per candidate (`_eligible_candidates()`, `mast_sites.gd:75`) | Fewer than six sites on a city with fewer candidates |
| `event_scheduler.gd:952`, `:1035` `_place_one_shots()`, `_place_a_set_piece()` | A one-shot at each site of a covering set | Finite site list (2–6) | Sites × `_place_one()` | Not consumed; rolled again the next day |
| `event_scheduler.gd:741` `_spoiling_grid()` | Thins a park's spoiler grid to ≤ 9 cells | `while columns * rows > SPOILERS_TO_DENY_A_PARK`; one dimension drops by 1 each pass | ≤ a dozen passes | n/a |
| `event_scheduler.gd:3610` `_ensure_the_city_is_still_walkable()` | Drops the widest blockers until a park and the day's target are reachable | `while not blockers.is_empty() and not (...)`, popping one blocker each pass | Dropped × (`blocked_by()` over every blocker left + one or two floods): quadratic in the worst case. A binary search over the sorted list would give the same blockers with a logarithmic number of floods, since dropping only adds reachable ground | n/a; removal only, the city skill's monotonic exception |
| `event_scheduler.gd:353` `_fill_a_finale_street()` | The finale's rows per street | `count` × 24 tries | × `_room_around()` over the plans | A street with no ground gets none |

### B. Late sitings (`WalkSiting`, during the walk)

| Site | What it does | Terminates because | Worst-case work per call | Can a refusal repeat; what it holds up |
|---|---|---|---|---|
| `event_scheduler.gd:1168` `ahead_of()` | Sites a place on her branch of the route tree, in a band ahead of her | No loop; `_offer_ahead()` + `_best_of()` + one or two floods | ≤ 24 judgements (≤ the distinct tiles offered, and inside a look none already judged for another copy) + 2 floods | **Yes, every look, without end.** It holds up only the place being sited. See C, the look |
| `event_scheduler.gd:1238` `_offer_ahead()` | The row's ground in the band; widened to twice the band, then the whole branch | `for wider in [far * 2.0, INF]`, over the route cells walked by `_the_way_she_is_going()` | Three route walks and cell scans. **Worked out once per look on this branch** (the last question and its answer are kept), not once per copy | n/a |
| `event_scheduler.gd:1533` `_the_way_she_is_going()` | Route cells ahead of her along her branch | `while i >= 0 and i < route.size()`, with `i += step` and `step` ±1 | Branches × routes × cells | n/a |
| `event_scheduler.gd:1292` `ahead_on_her_street()` | Day 7's van and day 6's man shouting, on the street she walks | 59×59 tile scan, then `for band in bands` (≤ ~29 groups of 8) | ≤ ~29 × (`_best_of()` ≤ 8 judgements + ≤ 2 floods) | Yes, every look while the place is owed; holds up only that place |
| `event_scheduler.gd:1700` `_still_leaves_a_park_reachable()` | Home and an unused calm area still reachable with the site's field closed | One flood, and a second only on failure | `blocked_by()` over every blocking plan + a flood of the reachability grid | False makes `ahead_of()` wait a look |
| `event_scheduler.gd:1383`, `:1398`, `:1441` `among()`, `near_her()`, `off_her_path()` | Day 11's mast near the mark, day 13's roadblock, the dusk fire | No loop beyond one `_best_of()` per pool (two pools at dusk) | ≤ 2 × (24 judgements + 2 floods) | Asked once per event; on refusal each falls back: the nearest live mast, a wider ring then the old spawn, no dusk fire |

### C. The director and the manager at runtime

| Site | What it does | Terminates because | Worst-case work per call | Can a refusal repeat; what it holds up |
|---|---|---|---|---|
| `event_director.gd:588` `site_what_is_on_her_way()`: **the look** | Asks `ahead_of()` for every place still owed | `for plan in _on_her_way` | One offer + one judgement per distinct candidate offered (afresh after each plan the look places or moves) + copies × (a copy of the plans + 24 rolls + ≤ 2 floods). Measured above: day 9's stall 275–292ms → 7.2–8.4ms, day 12's worst looks 0.45–1.14s → under 17ms | **Yes, every second of walking.** It holds up the places alone. The day-3 fire is lit at dusk on a won day. A crew or route place never sited is simply not met |
| `event_director.gd:648` `_waits_its_turn()` | Later crews of a row wait while one is placed and not yet in the world | Over `_on_her_way` | O(owed) | A crew left behind her that cannot be re-sited keeps the others waiting until a later look moves it or it streams in; it holds up crews only, and it is also what keeps most looks cheap |
| `event_director.gd:828` `due()` | Hands out the next owed moment | No loop | One siting: `_crossing_ahead_of()`, `_toward_her()` (≤ 13 × 7 × 2 tile checks) or `_toward_her_on_the_road()` | **Yes, every second of walking** (`_next_in = 1.0` at `:871` and `:880`), and **the head is not popped**, so every moment behind it waits, return patrols included. A return patrol's road siting is empty anywhere she is not beside a plain sidewalk edge (park, square, junction, precinct). It holds up moments, not the day |
| `event_director.gd:451` `_next_on_the_route()` | Skips the marbles of rows that have met their `max_per_day` | `for _i in ROUTE_SKIP_LIMIT` (64) | 64 peeks and draws | A bag that names nothing pops the slot with the clock still due, so the next slot is asked the next frame; the owed list drains |
| `event_manager.gd:1634` the owed pursuer | Re-sends day 3's dog (or a sprinkled one) that had nowhere to stand | Retried after each second of walking; one slot | One `PendingWarning.along_her_heading()` (≤ 25 tile checks) | Yes, without a cap; it holds up that dog only, and does not hold up `due()` |
| `event_manager.gd:1449` `_summon_what_has_been_sighted()` | Warns of the fire engine once the fire is seen | `for plan in _plans`; 2 headings | 2 × `PendingWarning.on_its_route()`, ≤ ~750 out-of-sight checks each | **Yes, every frame** the fire is in view with no road out of sight; a withdrawn warning re-arms it. It holds up the engine only |
| `event_manager.gd:1297` `_run_the_warnings()` | Moves each warning with her; at its time asks its place again, then creates or withdraws | Over the pending warnings | Each warning's own place function | A withdrawal re-arms only the engine (`:1504`) and the owed dog (`:1774`); the cyclist, a torn poster's pursuer, the resistance trap and day 13's column are not sent again |
| `pending_warning.gd:233` `on_its_route()` | The engine's place up its road | `while up <= reach`; `up` grows by 8px and the road is finite | ≤ road length / 8px | INF |
| `pending_warning.gd:185` `route_down_her_line()` | Keeps a row's far end on the map | `while not bounds.has_point(behind) and behind.distance_to(place) > TILE_SIZE`; each step moves `behind` toward `place` | ≤ the line's length in tiles | n/a |
| `event_instance.gd:3665` `_way_on_out_of_sight()` | A leaving body's way on to where she cannot see it | `while head < queue.size() and head < WAY_ON_SEARCH_LIMIT` (4096) | ≤ 4096 tiles of breadth-first fill | **Yes, every frame** a leaving body's search finds nothing. It holds up the body's going, not the day. Caching a failed search would change when it is asked again, so it is a fork |
| `event_manager.gd:1074`, `:1098` `queue_a_mast()`, `queue_a_task_row()` | Day 11's mast near the mark; day 13's roadblock | One siting each; ≤ 3 rings for the roadblock | One `WalkSiting.new()` (a route tree and corridor) when none exists, then one `_best_of()` | No; each has its fallback |

### D. Outside this branch's fence, read where events call them

These live in `src/resistance/` and `src/routes/`. Nothing here was changed.

| Site | What it does | Terminates because | Worst-case work per call | Can a refusal repeat; what it holds up |
|---|---|---|---|---|
| `happenings.gd:370` `_maybe_the_column()` | Day 13's column | Asked every frame until a warning goes up | One `send_the_column()`, which **draws `_rng.randf()` on every call**, so how many frames it fails moves the stream | Every frame until it goes up; withdrawn, it is not sent again |
| `happenings.gd:221` `_maybe_the_market()` | Day 11's market boarded up ahead of her | Asked every second | Market candidates × route cells | Retried for as long as `board_up()` fails; it holds up the market only |
| `resistance_director.gd:2273` `_add_a_mast_near()` | Day 11's extra mast on the circle round the mark | Over every sidewalk and square tile | **`MastSites._is_eligible()` without door points, so every boundary segment is rebuilt per edge tile.** The same fix as `MastSites.compute()`'s applies | Falls back to the nearest live mast |
| `resistance_director.gd:2875` the task guard's move | Day 13's guard, re-placed unseen every 0.5s | One search per call; a failure is remembered for 3s | 29×29 tiles of clear-line checks + ≤ 12 fills of a way past him | The memory's key holds her tile, so while she walks the search runs every 0.5s; it holds up the guard's move only |
| `resistance_director.gd:2665` `_reach_blocked` | The day's obstruction for the director's reachability questions | Built once a day | One `blocked_by()` + one flood | Not rebuilt for a mast, task row or route place added later: a correctness question, not one of completion |
| `route_tree.gd:394` the route walk home | Grows a route | Capped at `_WALK_STEP_LIMIT` (20000), then the shortest path | ≤ 20000 steps | n/a |
| `reachability_grid.gd:258` `flood()` | Breadth-first fill of the cell graph | `while head < queue.size()`; the reached set only grows | Every node + every blocked tile's dirty cell | n/a |

## Forks, for the player

- **Skip identical unplaced copies after the first refusal in a look.** Not built. The look's
  shared verdicts already leave a copy only the copy of the plans for its ask and its rolls, about
  0.24ms on day 9, and skipping would change how much the crews' stream is drawn.
- **A binary search in `_ensure_the_city_is_still_walkable()`.** It drops the same blockers with a
  logarithmic number of floods. It matters only on a dawn that drops many, which was not measured.
- **Remember a failed out-of-sight search in `_way_on_out_of_sight()`** for a short while. It
  changes when a leaving body asks again.
- **Pass door points in `_add_a_mast_near()`.** This is outside this branch's fence and changes no
  placement.
