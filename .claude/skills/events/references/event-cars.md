# A car that drives is a body that moves, and its strike is not the body

Read this before touching `EventDef.vehicle`, `EventCarDriving`, `EventInvestigation`, the patrol
car (`police_patrol` and every copy of it) or the fire engine (`fire_truck`).

`EventDef.vehicle` makes the only bodies that move, and it answers the pin the mobile exemption is
for by **never moving into her**: every event's step is proposed, checked and then committed
(`EventInstance.step()`), and a car's check is its own (`EventCarDriving.check()`): a step or turn
that would bring the body into her or her pram is taken back, with whatever the step decided on that
pose (the end of its route reached there), so the car stands for her until she is out of its way.
Its `obstructs_radius` stays zero — it closes no ground — and its lethality is **a strike area ahead
of its nose, only while it drives its route, only with her on the carriageway**, reaching
`EventCarDriving.PATROL_STRIKE_LEAD` past the touch so a car driving its nose into her strikes
rather than stands.

## It gives way where the crowd's cars do

This file owns the event car's give-way rule; the **crowd-traffic** skill points here. An event car
gives way short of a zebra she is waiting at off the main road, and at a red light, so the zebra
stays the safe way over, and **never inside a junction box**: for a zebra beyond the box it holds at
the box's entry line, since the crossing traffic cannot see its body. **Decide that before the nose
reaches the box**, from the box's own sight and wherever she waits along that zebra: a car that
looks for the far zebra through the zebra's own sight circle (`Tuning.CAR_ZEBRA_SIGHT`) sees her
standing out on its second tile only once its nose is in the box, counts itself committed, and
stands there.

## Seven traps

- **A strike stated over the touch alone never fires**, because the body stops her first — the
  same switched-off kill as a lethal radius inside a body. The lead past the touch is what keeps it
  live.
- **A car that has stood must not pull away into her.** It goes on standing while she is in its
  lane within its warning, so every strike comes after `Tuning.CAR_HORN_TIME` of warning or from
  her stepping into a moving car's path — the crowd car's contract, the carriageway and the horn,
  which is the one it keeps instead of a telegraph (**crowd-traffic**, "The traffic fairness
  contract").
- **A car created in her lane must not drive off at her.** Just out of sight on any street is
  nearer her than a fast car's warning reaches her — the fire engine's 1.7s of 190px/s past a
  touch that counts its body and hers, against the view's 180px half height up a north-south
  street and 320px half width across an east-west one — so one driving from its first frame
  strikes her inside the time it takes to walk off the road. A car that drives is made standing
  (`EventCarDriving`), so it waits until she is out of its way, as a car that has stood does.
- **A car that parks where it arrives must not reach past where it parks.** Its warning, strike,
  doubled caret and standing for her are stated in seconds of its travel, and the fire engine's
  route ends at its kerb, so they end at the touch it would make parked
  (`EventCarDriving.route_left()`), with no strike lead past it. Left uncut, they warn her past the
  kerb of a strike the car cannot make, end the day as it parks short of her, and stand it off
  screen for her there.
- **A heading change that newly brings her inside its warning's reach is refused like a step into
  her.** A turn moves nothing, so the body check passes it — and the raid's pacing car reversing at
  the end of its beat turns her from behind a car driving away into the front of one, struck with
  next to no warning. The car stands instead.
- **A car that stopped for her must not turn round on the spot, nor vanish beside her.** She is
  nearly always ahead of the investigating car, so "leave the way that does not run at her" is a
  180° turn in one frame in her view; once its man is back in it drives on along its route the way
  it was going instead, a car that has stood, so it waits while she is in its way. Any car leaving
  is gone only once she could not be watching.
- **A car that stops where it noticed her stops in junction boxes**, standing in the crossing
  traffic's way for a whole chase. One that notices her with any of its body on a junction drives on
  until it is clear of the box (`EventInvestigation._stands_in_a_junction()`). A test on a hand-made
  straight route away from junctions cannot see this; `tests/test_pursuer_on_foot.gd` drives real
  routes on three seeds.
