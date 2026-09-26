## M188 — A resistance target can always be reached · built 2026-09-24

Found by the route rig (`DECISIONS.md`, M184, a rig walks the route): walking her along a real
path's edges to time days 6 to 13 found four legs with no path at all, and the cause was in
`src/resistance/resistance_director.gd`, not the rig — four placement pools each missing a
refusal another pool in the same file already had.

**Bug 1 — a chalk mark could stand on a solid event body.** `_pick_reachable()` checked
`is_walkable`, `is_closed`, `is_held_at`, `is_on_home_block` and `is_in_walled_alley`, but never
`CityMap.is_obstructed()` — the day's own record of a stationary solid body (a café's tables, a
construction band, a kerbed van…), filled by `EventManager.start_day()` from the day's whole plan
before this director ever places anything. Day 9's mark on seed 4242 stood on tile (79,90), open
ground inside a solid event body. Fixed by checking `is_obstructed()` only against the tile the
single `rng.randi_range()` draw actually lands on — not folded into the pool the draw is made
from — redrawing from the same pool up to `PICK_REACHABLE_REDRAW_LIMIT` (24) times, with the
pool's own nearest still-legal tile standing in if every redraw fails too.

**Bug 2 — a contact's bearing offset had no ground check at all.** `_reachable_offset()` drew
`Vector2.RIGHT.rotated(rng.randf() * TAU) * distance` with no walkability check, so a contact
sited beside a rider standing flush against a building could land inside it. Day 7's
`delivery_van` contact on seed 90210 landed on (76,119) and day 8's `burnt_shell` contact on
(9,82), both inside buildings. Fixed by redrawing the bearing, up to `REACHABLE_OFFSET_DRAW_LIMIT`
(24) times, against the same six-refusal ground-legality check `_draw_guard_position()` already
used for the guard; a bearing that still fails after that steps to the nearest walkable,
unobstructed tile within `ContactPoint.REACH` (36px, the completion radius — how close she
already has to stand to touch a contact) of the last bearing drawn.

**Bug 3 — the mark's relocation search carried none of the pool refusals, and needed two fixes to
prove it.** `_nearest_alley_within()` (the search that relocates a mark that was never on screen,
M78) carried the same five refusals `_pick_reachable()` used to, and the same missing
`is_obstructed()`. A `--day 9 --seed 4242 --route mark,task,calm,home --no-title` boot, run after
bug 1's fix alone had landed, still stood the mark inside a building: the dawn draw correctly
found legal ground at (108,67), but she starts at the doorstep, more than `NOTICE_RADIUS` away, so
the relocation search fired on the very first frame and picked the nearest `ALLEY` tile without
ever asking whether a body stood on it — landing right back on (79,90), the exact tile bug 1 was
meant to have fixed. Adding `is_obstructed()` here moved the relocation to (79,91) instead — open,
unheld, unobstructed ground one tile over, and still sealed off from home by the day's own
obstruction (bug 4 below), because the relocation draws from the same `ALLEY` pool the dawn roll
does and needed the same seventh refusal. Fixed by giving `_nearest_alley_within()` both
`is_obstructed()` and `_reachable_from_home()`.

**Bug 4 — a candidate open, unheld ground could still be sealed off from home by everything else
today's obstruction blocks**, which none of the five pool refusals or `is_obstructed()` can see —
each asks about the tile itself, never the streets between it and the doorstep. Day 7's mark on
seed 1234567 stood on good ground (135,105), but the day's full obstruction — the events' bodies
and the crowd's parked vehicles, 791 tiles — sealed every route to that part of the city, where
closures alone leave it 76 tiles from home. `docs/CITY.md`'s winnability guarantee ("Every day
stays winnable") promises a route from home to *some* calm area, never to this candidate
specifically, so the new check, `_reachable_from_home()`, does not widen that guarantee — it only
keeps a placement from pointing at ground the guarantee was never about. Built on the same public
calls the city's own winnability check uses (`ReachabilityGrid`/`EventScheduler.blocked_by()`),
so the director is asking the city's own machinery a narrower question, not reimplementing it.

**A fifth bug of the same shape, found while building bug 4's check: a region wall's own door
bodies were counted as blockers.** `blocked_by()`'s disc approximation — sized right for a point
hazard, wrong for a hut-gate-hut door three tiles wide — closed every door in the wall along with
it, so day 9 onward (`Tuning.REGION_WALL_FIRST_DAY`) answered every mark and contact outside the
home's own region unreachable, on seed 90210, a seed the route rig otherwise crosses those same
doors on without trouble. Fixed by excluding `region_plan.door_bodies` from the blocker set by
identity — the same list the wall-building code already keeps apart from `wall_bodies` for this
reason, and the same exemption `event_scheduler.gd`'s own corridor-cost rule already carries for a
region door — not by matching `def.id`, so a new door-body row never needs a second list here.

**The stability rule: a draw that is valid today stays exactly where it is, and only a rejected
draw is redrawn.** `_pick_reachable()`'s candidate pool is built exactly as it always was, with no
`is_obstructed()` or reachability filter, and the single uniform draw over that pool happens
exactly as it always did — filtering the pool before the draw would shift which index every other
candidate answers to, moving a placement that was never obstructed because *some other* candidate
elsewhere in the pool got rejected. Only the tile the draw actually lands on is asked whether it
is legal; only then, if the answer is no, does it redraw. Proven directly by a unit test with a
controlled two-candidate pool
(`_test_pick_reachable_only_replaces_the_candidate_the_new_check_rejects`). Swept before and after
bugs 1-2 alone, across days 6-13 and seeds 4242/90210/1234567: of 36 mark/task placements, exactly
3 moved, and every other placement is bit-identical to what the unfixed code drew.

**Why the sweep now runs the director's first `_process()`, as a real boot does.** Bugs 1-2's own
sweep test drove `City.start_day()` → `EventManager.start_day()` → `ResistanceDirector.start_day()`
and stopped there. `main.gd`'s real day order goes one step further — `_resistance.start_day()`,
then `_player.reset_at(start_at)`, then the tree's first `_process()` — so a played mark is always
checked at frame 0, standing wherever `_track_sight_and_reposition()`'s relocation search
(`_nearest_alley_within()`) left it, not wherever the dawn roll did. The sweep never called
`_process()` at all, which is what let bug 3 through: it was asking a question the real game never
actually asks. Skipping that tick mattered for a second reason too — `_move_the_mark()` re-rolls
the day's guard through the same shared `_rng` every later placement draws from, so a sweep that
never relocated the mark was drawing a different sequence of guard positions than a real run does.
The sweep test now stands a rigged player at the doorstep and runs `director._process()` once, in
the real order, before checking the mark's position.

**Confirmed on the real game**, headless, `--route mark,task,calm,home --no-title --invincible`:
day 9 seed 4242 (the relocated mark and the task it unlocks both reach in full); days 7 and 8 seed
90210 (both contacts reach); day 7 seed 1234567 (the mark reaches — `"'mark' stuck fast, skipping"`
is the crowd-congestion issue M184 already tracks separately, `docs/TODO.md`, M184, the rig gets
through chokepoints, not an unreachable target).

**Rejected options.** Filtering the candidate pool before the draw, rather than checking only the
tile the draw lands on — rejected because it would have moved most marks, not only the ones
actually obstructed, which is exactly what the stability rule above exists to avoid. Requiring
reachability for every placement pool, rather than the mark, contact and relocation pools alone —
rejected because checked directly against a seed 4242 fixture, turning `require_reachable` on for
the finale's `district` pool (`GameEnums.BlockPurpose.CIVIC`, 72 candidates) returned zero
reachable: the day's own event bodies happened to ring the whole district, not a bug, and the
calm-area guarantee was never about that one district. `require_reachable` stays off for
`_place_at_a_door()`, `_place_at_a_swing()` and the finale's own `district` pool; whether the
winnability guarantee should extend to them is open (`docs/TODO.md`, M181, the resistance has a
reason, and a task is one day).
