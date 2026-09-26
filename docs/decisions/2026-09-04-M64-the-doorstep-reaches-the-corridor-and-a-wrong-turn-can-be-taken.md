## M64 — The doorstep reaches the corridor, and a wrong turn can be taken · built 2026-09-04

Four items of M64, from playtest 22, built on `feature/the-door-reaches-the-corridor` and
`feature/a-wrong-turn-can-be-taken` and merged together.

**The doorstep could be sealed in on the first frame.** *(2026-09-03, playtest 22: "the starting
area was sealed off completely and the only way out was alongside the main road which basically ends
the day".)* `SealPlanner` exempted the home street and `RouteTree` coloured no home node — *"a door
is not a route"* — and nothing protected the join between the two guarantees. Which street off the
home street ended up on the tree was whatever a branch's random walk happened to reach home through.

**The fix is a guarantee rather than a repair**, per the standing rule that placement is checked
before it is accepted: `RouteTree._grow_the_trunk()` runs once after every branch has grown, a BFS
from the home street's nodes outward to the nearest cell already on the tree, adopted under the merge
point's existing colour. That makes `is_on_the_tree()` true of the join, so neither `SealPlanner` nor
`ClosurePlanner` had to change to pick the fix up. **The rejected alternative**, named in the brief
and cheaper: exempt every street incident to the home street's far junctions, which unseals a handful
of segments without proving they lead anywhere.

**Measured** over 123 (seed, day) samples built to stress the mechanism — the tree grown with only
the 1 or 2 calm areas farthest from home still standing, modelling a run spoiled by day 6 — the
trunk's main-road fallback was **never needed: 0% at both 1 and 2 areas kept**, against the pre-fix
probe's reading that the single protected street was the main road **27.8%** (2 kept) and **11.8%**
(1 kept) of the time. The old number measured which street a random walk happened to use; the new
mechanism searches every direction out of the home street, which is why it moved that far.

**A route may cross the main road and never run along it.** *(2026-09-03, playtest 22: "a path
should never go alongside the main road — main road by itself can be considered a blocker — paths can
only cross the main road".)* Nothing in `src/routes/` mentioned the main road before this.
`RouteTree._ways()` now drops every edge whose two tiles share the spine's own x-band on a y-step; an
x-step through the band is a crossing and is never refused, however many in a row, so `docs/CITY.md`'s
*"she may cross whenever she likes"* is untouched. **The main road is deliberately not sealed** —
it is already the worst ground in the game to stand on, `EXCITEMENT_DECAY_MAIN_ROAD_MULTIPLIER` 0.6
against an ordinary street's 1.0 — so making it *not a route* is the fix and sealing it would be the
harm the player reported. `SealPlanner._is_the_main_road` refuses it as a candidate independently
rather than relying on *off the tree*, because a crossing marks one stretch of the spine on-tree
while the rest is not.

**The winnability check was restated from reachability to survivability.** *(2026-09-03, playtest
22, in the player's own words: "reachable is not survivable".)* `tests/test_seals.gd` flooded from
the doorstep through the day's seals and closures and asked whether any calm tile was still
reachable — a plain graph question with no cost attached — and it passed on the exact run that
produced the doorstep bug, because the one route left ran the whole way down the spine.
`_test_a_day_is_reachable_without_the_main_road` adds every tile of the main road's band to the
blocked set, so calm staying reachable under that removal proves the day never *requires* the 0.6
ground. **The remaining gap is named as a fork rather than closed:** the crowd and the events
standing on whichever route she takes are not simulated, so a spine-free route could still cost more
than the meter allows. Closing it needs the day's own event and crowd simulation over this static
graph.

**The seals are thinned, so a wrong turn stays open long enough to be taken.** *(2026-09-03, playtest
22: "it feels a bit on guardrails… removing some obstacles randomly might lead the player down a bad
path until they return to the actual path… the goal is to guide the player without having the player
know they are being guided".)* `SealPlanner._thin_soft_pairs` drops one body of
`Tuning.SEAL_THINNING_FRACTION` (0.08, *"start small"*) of the day's soft pairs; never a hard seal,
never an alley mouth.

**The fork it answers, with the alternative kept:** *"removes a barrier"* could mean the whole pair
or one body of it, and the smaller reading was taken — a street that still *looks* obstructed reads
as an ordinary street with something on it rather than as a gate somebody opened. **Dropping the
whole pair** opens the street cleanly and is easier to notice both in play and in a test; it is the
cheap thing to switch to if the subtle version reads as too subtle against a played day.

The geometry was checked rather than assumed: a soft seal puts one body per pavement and never
touches the carriageway, so the side thinning opens was not obstructed by that seal at all — every
current soft row's `obstructs_radius` stays inside its own pavement (`construction` 64px of a 64px
band, `cafe_tables` 48, `market_stall` 56, `delivery_van` 44), asserted in `tests/test_seals.gd`
against the pram's 28px collision circle.

**Why this is not the repair pass `CLAUDE.md` warns against**, and it is the monotonicity carve-out
that file now carries: every guarantee the sealing holds is about *reaching* somewhere, and removing
a barrier can only add reachable ground, so nothing here can invalidate what the placement pass
already proved. Stated next to `_thin_soft_pairs` itself so the next reader does not delete it on
sight.

**Measured**, 3 seeds × days 1, 5, 8, 11, 14: before thinning, 2377 off-tree streets carried a soft
pair (4754 bodies) and 136 carried a hard seal; after, 4541 soft bodies survive — 213 dropped, 4.5%
of the soft total, matching the expected 4% (the fraction × one of two bodies per thinned pair)
within sampling noise.

**Three fixes the merge made that neither branch could make from inside its own fence.** Forbidding
the spine reshaped `RouteTree.covering_sites()` on the fixed seeds two other suites use, and it
exposed two latent bugs and one false assertion:

- `_place_a_set_piece`'s *"anywhere"* fallback never set `set_piece_group`, so a one-shot placed that
  way was silently outside the machinery `EventManager` spends a group with. Latent since the
  fallback existed; the reshaped tree made it reachable. It now tags a group of one.
- A telemetry glyph test picked whichever stationary lethal event a day placed and assumed nothing
  was drawn over it — but four marks *are* drawn over the events on purpose (calm, dead ends,
  closures, home, which `render()` calls the picture's fixed points). It now uses a bare render as
  an oracle and reads a glyph only on tiles the overlays do not touch.
- **A threshold that was already false of the city and passed on too small a sample.** The test
  required fewer than 40% of one-shot runs to be offered a single covering site, over six seeds.
  Measured over forty-six: **63% now, and 45.7% before this branch** — so it passed only because
  those six read 16.7%. The assertion is replaced by the measurement. The real **17-point drop in
  one-shot covering breadth** is a consequence of forbidding the spine and is left for somebody's
  judgement rather than a green tick.
