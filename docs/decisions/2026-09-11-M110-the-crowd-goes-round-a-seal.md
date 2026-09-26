## M110 — The crowd goes round a seal · built 2026-09-11

*(2026-09-10, playtest 52: "also I noticed that objects like fallen trees don't stop/redirect
traffic or pedestrians"; playtest 55, day 7: "also cars go through the barriers and checkpoints";
on the doors: "at checkpoints cars should slow down halt then the bar should lift then the car
drives through then it closes again"; on her: "attempting to do that should just start a regular
checkpoint inspection".)* Five agent commits on `feature/crowd-goes-round-a-seal`, reviewed here,
with M100's two crowd defects alongside. **Seals, walls and doors only**, as the entry recommended;
ordinary bodies — a café, a construction band, a kerbed van — are still walked through, and the
question of whether they should be stays the player's, in the entry.

**One record serves the catalogue and the crowd.** `CrowdAgent._cannot_go_on()` and the
frame-zero placement test both read `CityMap.held_segments` through `is_held_at` — the record
M100's held-ground fix built the same day, whose docstring already named this reader — so a hard
seal's segment, a region wall's and a closure's are shut to walkers and cars from seven tiles
off, and both turn at the last junction. A wall is a hard seal of the `roadblock` row, so nothing
separate was needed for it; the two items share one commit for that reason. **Two carve-outs**,
each a list threaded from `Crowd.start_day()` to every agent: the region's door segments, where
a car brakes to the stop line, waits for the boom `Crowd._stop_for_gates()` already runs for M62,
passes and lets it lower, and a walker passes the hut as she does; and the segments around the
home block, which `EventManager` holds for placement only — no barrier stands there and she walks
out onto one every morning — so the crowd keeps them. The second was an orchestrator's correction
of the first build, which had shut them; a `CityMap` query saying *why* a segment is held was the
alternative and was not taken, since it would attach a reason to every entry for one reader's
sake. Tests: zero occupancy and zero through-traffic on a hard-sealed segment over twenty
seconds; a wall shut and a door carved out on a real day; walkers and cars seen on the home
block's own streets inside thirty seconds on a day with holds.

**A soft seal takes both pavements from the walkers.** `CityMap.soft_sealed_tiles`, documented
beside `held_segments` and filled by `SealPlanner.plan_day` with both pavement tiles of every
surviving side — a thinned pair's dropped side stays open, which is the thinning's whole point —
and read by walkers only; a car on the carriageway passes.

**What the entry asked for and this branch could not reach** was the bar itself: a raised bar
started an inspection at the huts, where the detain radius lived, but `checkpoint_gate` carried
no detain of its own, so the bar's own tiles held nobody. The appended checkpoint test pins that
the gate's raised state has no bearing on the hut's hold; the gate row's own detain was built the
same day on M113's branch, which owned the checkpoint rows — see the M113 record.

**The two crowd defects.** A car's end-on picture is now drawn with its footprint centred on the
node, so the strike box, the shadow, the field and the picture agree — checked analytically
rather than by rasterising. And a car crawling forward in a queue, or joining the back of one,
refuses a step onto ground `_cannot_go_on` refuses, so *nothing walks into a hard blocker* is
back to exactly zero from the one-car-on-one-percent-of-frames it had been loosened to. **Small
things changed on the way**: `setup()`'s placement retry budget 8 → 24, kept as defence in depth
after a test landed an agent on a wall on frame zero; `_recycle()`'s six-roll budget untouched.
