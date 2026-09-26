## M111 — Cars follow their turns · built 2026-09-11

*(Playtest 53: proper turns and turnarounds using diagonal sprites; 2026-09-10, playtest 54: "the
car turn overcommittment that you flagged is good and we should do that" — the full model, swept
footprint and reserved turn space included, over the smaller reading of an arc with the sprite on
its tangent.)* Three agent commits on `feature/cars-follow-their-turns`, reviewed here. **A turn
is a path.** `CarTurn` (`src/crowd/car_turn.gd`) is one circular arc tangent to the lane the car
is in and to the lane it is joining; `CrowdAgent._plan_a_turn()` replaces the instant axis-and-lane
swap for cars, the car drives its own lane to the arc's entry with every ordinary rule still on it,
follows the curve, and takes up the exit axis, corridor, lane and direction where the arc ends. The
frame that crosses over splits its travel between straight and arc so displacement is speed times
delta on every frame. **`heading()` is the arc's tangent mid-turn and `velocity()` is that times
the real speed** — the datum M108's vehicle item reads for the picture; `_frame()`, `_flipped()`
and `_travel_axis()` still draw the cardinal picture until that item lands. Walkers are untouched;
`_pick_an_arm`, the axis weights and M110's refusals are unchanged, except that the arm probe
gained an optional origin because a car now asks before it reaches the junction.

**The radius is the lattice's, not a dial.** An arc tangent to two lanes has one free parameter,
fixed by where it starts: the near-side arm is 16px, the far-side 48, an about-face 16. Two
constants went into `Tuning` under the balance rules: `CAR_TURN_SPEED` 60px/s — 0.42s in the
tightest quarter turn against 0.19s at the 130px/s cruise, and 60²/16 = 225px/s² of lateral
acceleration, under `CAR_BRAKE`'s 320 — and `CAR_TURN_RADIUS_MIN` 16px, over the body's 14px half
width so no arc is a pivot. **A car's back swings to the outside of its turn**: a 28px body in a
32px lane has 2px of slack, so the arm turning away from its own kerb starts a body's half length
into the junction; this refused every far-side turn in the city until it was found.

**Nothing is committed before it is checked.** The footprint is the 52×28px strike box swept along
the curve, sampled on a 5×3 grid of itself every 4px of arc, against pavement, closures, held
segments, precinct paving and the map edge; a car's length must be free where it lands, held every
frame through `TrafficIndex`; a turnaround's worth of road must lie past the arc's end; the run-up
must not cross the blockage. A car with nothing that fits brakes to a stop a half turn short of the
obstruction, and `nudge_back()` refuses to move a car on an arc, so the separation pass can never
repair a turn. A turning car holds its junction box on both axes from the moment the arc begins —
not from commit, since holding it through a 200px approach empties the crossing street — stays in
the queue it came from so followers keep a headway, reserves its exit lane in the rebuilt index,
reports `travelling_vertically()` from its heading mid-turn, and gives way at no zebra while on the
arc. Signals, amber, right of way, horn and the lethal contract read `heading()` and follow the
curve for free.

**The space constraint that needs a different manoeuvre**, recorded as the entry asked: a half turn
between two lanes 32px apart is a 16px arc and the body's corners reach 40px from its centre, 8px
past a 32px kerb. So an about-face is taken in a junction box, where the crossing carriageway is
the room it needs; where a barrier leaves no junction reachable, the street about-face overhangs
open pavement only, every hard blocker still refused. Refusing it outright was measured at 33 of 34
cars stopped inside 90s against a baseline of 10, because one nose-to-wall car holds its junction
and the street behind it queues; with it, 4/7/13 stopped at 90s over seeds 4242/24757/99001
against 10/7/7, and 5.71/5.01/9.13 cars stopped per frame against 6.64/5.56/9.26. The manoeuvre it
wants is a three-point turn and the traffic has no reverse gear — **that is the player's question,
in `TODO.md`**, together with the one instant reversal that survives as a last resort for a car
already stopped with less than a half turn's room, reachable only by a placement or a barrier that
arrived after it. **One route outcome changes**: an arm whose exit has no turnaround room is
refused at the turn-fitting gate, since the arm probe is one point seven tiles out and looks past
a two-tile plug — harmless while a car could reverse anywhere, a permanently parked car now.

**Measured on the branch**: 62/32/9 turns per 90s across the three seeds, mean 2.3s each, entry
speed 61–65px/s on average with a worst of 152 where the seven-tile `LOOKAHEAD` gave no room to
ease, worst per-frame step 3.07px against the 3.08px cap, worst heading swing 8.7° per frame.
**Tests**: `tests/test_turns.gd`, driven through `Crowd.step()` — arm turns from all four
approaches into both arms, about-faces from all four, a street about-face short of a closure, a
plugged arm, a queue behind a turning car, two cars at one box, a zebra, a red light on the
spine, the city boundary, and the constants' relationships; each path checked for displacement
within top speed, bounded heading swing, swept box on drivable ground, exact exit lane and finite
completion. **Left open and recorded**: the approach cannot always reach the turn speed because
what a car knows is bounded by `LOOKAHEAD`, and lengthening it would move which junction a car
turns at; the single-point arm probe still chooses cul-de-sac arms, caught at the turn instead of
at the choice. **No capture**: the picture is deliberately still cardinal, so a still would show
nothing; the motion is what `REVIEW.md` asks a person to watch, and the diagonal capture at entry,
apex and exit is M108's vehicle item.
