## M156 — The crowd only turns at what physically stops it · built 2026-09-19

*(2026-09-19, [PLAYTEST-78](../playtests/PLAYTEST-78.md): "cars shouldn't avoid it. I noticed cars
turning around even though the obstacle is on the sidewalk. only things like a fallen tree (which
blocks the whole street) should prevent cars from entering … pedestrians should only avoid the area
if they cannot reach it physically. right now they give up if there is an event at all when they
should only give up if they touch an impassable wall"; and, on the 2026-09-12 complaint it
explains, "the pacing back and forth I complained about was because walkers never actually tried
walking to the edge. they saw that a road section was closed of and never entered it. this
shouldn't happen. they should still go into the section until they cannot continue. this should
also happen from inside the path since right now we have offshoots that are clear because nobody
attempts to go in".)* Agent commits on `feature/m156-crowd-turns`, one per queue item; the burst
is `evidence/m156-crowd-turns-2026-09-19/`, seed 4242 day 1 at a fallen tree's closure.

**The measurement came first, and it named the cause.** `tests/probes/m156_car_turns.gd` re-asks
`CrowdAgent._cannot_go_on`'s clauses at the tile each car's lookahead stopped on and charges the
answer to one of the day's placements; three seeds by three days, twenty seconds each.

| car-frames turned by | before | after |
|---|---:|---:|
| a solid body | 24369 | 670 |
| of which a body standing on a sidewalk | 24369 | 0 |
| a held segment | 17220 | 15675 |

Every car a body turned was turned by a body on a *sidewalk*, and none by one on its own lane.
Seed 4242, day 1: a car in lane tile (101, 94) stopped by a `delivery_van` on (102, 94), the kerb
lane of the sidewalk; `skip`, `moving_van` and `construction` the same way. The 670 left are a
region wall's `roadblock` standing on the carriageway.

**A body stands on the tiles whose middle it covers.** `GroundShape.tiles_under()` took every tile
a body touched, so a van pinned to the kerb — 22px around a lane centre 16px from the kerb —
overhung the road by six pixels and was handed a whole 32px lane. The middle is the rule because
every lane is travelled down its own centre line, so a tile whose centre is clear still has a line
down it; the change only ever removes tiles from the record, which is the safe direction. A
fallen tree still takes all six lanes and the crash exactly its two carriageway lanes. Two guards
came with it: the body's own centre tile is always in, or a small disc near a tile corner stands
on nothing, and the rasteriser is exact for a diagonal axis. Rejected: filtering in
`EventManager.obstructed_footprint()` with the rasteriser left alone — two answers to where a
body stands — and "more than half the tile", the same number with no sentence behind it.

**A hold is a car's warning and a body is a walker's, and the asymmetry is the manoeuvre.** A
car's answer to a wall is an arc that needs a junction box, so it decides while the last junction
is still ahead. A walker turns in a stride anywhere, so deciding early buys nothing and costs the
city a street's length of sidewalk. `CrowdAgent._segment_is_shut()` answers for a car, and for a
walker only at a region door it turns back from; hard-seal and region-wall bodies are recorded in
`CityMap.obstructed_tiles` like any other; `_acts_on_a_barrier_within()` gives a car the whole
lookahead and a walker the next tile. A walker that turns leaves, and `_turn_round()` commits the
new heading for a stride, which is what keeps two walkers at one barrier from stacking or
flickering. Rejected: keeping the hold for walkers and turning them later — a hold is a fact
about a segment and can never say that a crash leaves its sidewalks open.

**A walker picking an arm asks the city, not the day.** `_cannot_go_on` split into
`_never_a_street_here()` — the map edge, the lattice, a precinct's paving to a car — and today's
barriers; a walker's arm probe asks only the first, so a street sealed further along weighs like
an open one from either end, offshoots of the route included, while a calm zone's park arm is
still refused. A car keeps the whole predicate. Rejected: a weight instead of a gate, a number
nobody can set from anything observable.

**The walker pocket is gone and the car's stays.** `CrowdPockets` emptied a junction sealed on
every side for both kinds, which answered the 2026-09-12 pacing; the player has since named the
cause as the lookahead, and a walker there now walks each stub to its barrier and turns. Emptying
the ground cost 48 of 144 junctions' worth of sidewalk on seed 4242 day 1. A car cannot turn
round against a barrier, so its pocket stays.

**Open to overturn, the agent's choices where the entry was silent.** A walker acts on a barrier
when it is the next tile, the last moment the cached lookahead leaves room for. A soft seal still
marks both lanes of its sidewalk where its body covers one, so it is the one place a walker is
turned by slightly more than the body. `docs/ARCHITECTURE.md`'s line on `crowd_pockets.gd` was
corrected outside the agent's fence because it would otherwise have shipped false.

Whether closed-off streets and offshoots read as peopled, whether a turn at a barrier reads as a
decision, and whether cars flow past a sidewalk obstacle are in `REVIEW.md`.
