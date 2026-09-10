# Playtest 52 — 2026-09-10

## The crowd walks and drives through the seals

Said while queuing M61's field half and M104, the debug view, for implementation:

> also I noticed that objects like fallen trees don't stop/redirect traffic or pedestrians

Filed as M110, the crowd goes round a seal. The mechanism is known rather than mysterious: the
crowd diverts only at the tiles `CityMap.close_streets` puts in `closed_tiles`, which are the
closures `ClosurePlanner` places at a street's two mouths. A hard seal — the fallen tree, the car
accident, the burst main, the burnt-out car, the collapsed frontage, the stacked barricade — is
`SealPlanner` standing a row's bodies across the middle of a segment, and none of that segment's
tiles is closed, so `CrowdAgent._cannot_go_on()` reports the way open and walkers and cars pass
through the bodies. The same is true of every solid catalogue body: the `delivery_van` row's own
docstring says a van on the carriageway stands *"in a traffic lane the crowd knows nothing about
and drives straight through"*. Whether the ordinary bodies should divert the crowd too is the open
question the entry carries.
