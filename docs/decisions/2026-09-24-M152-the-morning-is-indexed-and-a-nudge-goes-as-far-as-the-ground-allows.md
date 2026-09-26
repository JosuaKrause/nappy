## M152 — The morning is indexed, and a nudge goes as far as the ground allows · built 2026-09-24

*([PLAYTEST-76](../playtests/PLAYTEST-76.md), [PLAYTEST-77](../playtests/PLAYTEST-77.md): "when they
turn in the final stretch the teleport a car length somewhere else".)* The in-view shunt the
probe once found on seed 91117 day 1 no longer reproduces on the current streets, so the seven
off-camera `spacing` jumps over the seven rig days were diagnosed instead; the probe now names,
per shunt, what put the follower inside its leader.

- **Two were behind a landing booked on the day's first frame.** `Crowd.start_day()` ran the
  morning's resolve but left `TrafficIndex` empty, so every check on frame 0 saw an empty road
  and a turn could book a spot a queued car already stood on, paid 116 and 201 frames later.
  `start_day()` now fills the index from its resolve (`_index_the_queues()`, shared with
  `space_out_the_traffic()`); it moves no car.
- **Two were pairs the morning placed inside each other past a barrier.** `nudge_back()` refused
  a slide whose end tile was blocked, so the overlap waited until a full slide was legal and then
  jumped 41px. It now slides as far as the ground allows, stopping a pixel short of the first
  blocked tile and checking every tile on the way.
- **Three, then five, are the last resort's reversal on the spot**, the residual this item called
  measured and not asked about; the count moved because the traffic plays out differently.

| over 7 rig days | before | after |
|---|---|---|
| `spacing` jumps | 7 (0 in view) | 5 (0 in view) |
| behind a first-frame landing | 2 | 0 |
| a morning pair still inside each other | 2 | 0 |
| from reversals on the spot | 3 | 5 |

`tests/test_crowd.gd` and `tests/test_turns.gd` each gained a test red on the old code;
`_test_traffic_gives_way_at_a_crossing` accepts a car braking for a barrier it has reached, since
that rig drives one car by hand and its index was frozen empty before. The **crowd-traffic**
skill's morning paragraph says the index is filled from the resolve, and that a separation
refused rather than made smaller is deferred, not avoided.

**Open to overturn, chosen by the agent:** a recycled car's merge onto blocked ground is still
refused whole; a slide stops a pixel short, as `_hold_inside_the_tile()` does. **Left open, and
not asked about:** the reversal on the spot (`_turn_round()`) flips a stopped car where it stands
and can land level with another; the shape on record is to treat a landing held by a stopped car
as a plug and stand rather than reverse.
