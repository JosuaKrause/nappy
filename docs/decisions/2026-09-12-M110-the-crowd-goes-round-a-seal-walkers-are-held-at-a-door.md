## M110 — The crowd goes round a seal · walkers are held at a door, built 2026-09-12

*(2026-09-12, playtest 58: "walkers walk through checkpoints..."; asked which rule they get,
"Held at the hut like her"; "a small fraction can do that"; "others can turn back"; "don't want a
queue that is long"; "four states walking -> waiting -> inspection -> emerging on the other side
(with cooldown to not go back again) -> walking".)* M110 had carved a door out of the crowd's
shut list so the street would read as open, and a walker crossed straight through the hut's
footprint. Three agent commits on `feature/walkers-held-at-doors`, reviewed here. **The answer is
the walker's own**, drawn from its RNG stream when it is placed and again when it is recycled, so
it never changes mid-street: `WALKER_DOOR_PASS_FRACTION` 0.125 passes, `WALKER_DOOR_TURN_BACK_FRACTION`
0.25 turns back, the rest are held; `validate_traffic()` refuses a pair that leaves no remainder.
Turning back needed no machinery: a turn-back walker gets no door carve-out in
`_segment_is_shut()`, so a door reads to it like the wall either side, and it turns at the last
junction. The draw happens *before* placement, since placement refuses ground a walker treats as
shut and a walker handed turn-back afterwards could start inside the door's own street and pace
it all day. **The four states** live in `CrowdAgent.advance_the_door_hold()` on
`WalkerDoorHold`, a new class holding a hut's ground point, whoever is inside and the line;
`Crowd._hold_walkers_at_doors()` writes each walker's door ahead from public geometry the way the
car's gate stop is computed. Walking, then waiting stopped on its lane `WALKER_DOOR_STOP_DISTANCE`
(40px) short of the hut plus `WALKER_DOOR_QUEUE_SPACING` (26px) per place in line, then
inspection standing on the hut's own point and invisible for `WALKER_DOOR_HOLD_SECONDS` (1s), then
emerging on the far side on the same lane with a cooldown that clears once it is
`WALKER_DOOR_COOLDOWN_RADIUS` (96px) from the hut, then walking. The stopped pose came free by
folding the hold into `velocity()`, which the gait frame and the eight-way view both read. **The
line is short by construction**: `WALKER_DOOR_QUEUE_MAX` (2) is stated over everybody committed,
inside plus waiting, because stated over the waiting line alone the first frame a door is seen lets
an unbounded number commit while nobody is inside yet; a refused walker gets that one door's
segment shut to it and turns like at a wall. Every way out releases the hut — inspection ending,
recycling, streaming out, turning away, and `Crowd.clear()` — and a probe over a whole day with
every walker held found the hidden count always equal to the inspected count. **Chosen where the
design was silent**: every door body with `detain_seconds > 0` holds, hut, alley guard and boom,
with the lane test deciding which is on a walker's line, so on an ordinary street only the hut
ever is; alley guards hold nobody, since no walker enters an alley; inside means standing on the
hut's point rather than hidden where it stopped, so a hidden walker is never a body in the street
she can hit; a walker inside keeps its ordinary noise; two walkers approaching one hut from
opposite sides share one line. **Left open**: the refusal turns a walker where it stands when it
meets a full door from inside the door's own street, since seven tiles is all the crowd sees a
wall from; widening that for doors alone would buy the junction. All five numbers are
recommendations, open to overturn. Tests drive the answers' fractions over a four-day sweep, one
walker through all four states with the hut occupied exactly during inspection, a line at the cap
with the refused walker never joining, and a car still stopping for the boom. The burst
(`rig-045244-seed4242…/asked/burst-32711603-001` in the scratch telemetry folder, not archived)
shows a walker stopped beside the hut and then gone; a three-second burst is shorter than one
walker's cycle, so the full cycle rests on the suite.
