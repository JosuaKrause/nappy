# Turns and the heading

Read this before touching `CarTurn`, how a car turns, turns round or gives up on a turn, or anything
that reads a car's heading. `LaneMover` is the class `CrowdAgent` extends; it holds the heading.

## A turn is a path, and the radius is the lattice's rather than yours

A car plans one arc — `CarTurn` — before it starts turning, and follows it. **The free parameter in
an arc tangent to two lanes is fixed by where the arc *starts*, not by a constant**: a lane centre
sits 16px from its kerb and two lanes are 32px apart, so the near-side arm comes out at 16px, the
far-side at 48 and an about-face at 16 with no choice in it at all. **If you find yourself adding a
turn-radius dial, that is the thing this entry exists to stop** — the number would have to agree
with the lane geometry to land on a lane, so it is the geometry.

The shape of it is easy to get wrong:

- **A body swings to the outside of its turn.** A car has two pixels of slack in its lane, so a few
  degrees of rotation drags its tail over the kerb. The arm that turns *away* from its own kerb
  therefore cannot begin at the carriageway's edge; it waits until the tail is inside the junction.
- **A half turn between two lanes cannot be contained by their own street.** The body's corners
  reach further from the arc's centre than the kerb is. So an about-face is taken in a junction box,
  where the crossing street's carriageway is the room it needs — and the street version, the only
  manoeuvre whose swept body crosses a kerb, is the last resort before a barrier.
- **Refusing outright is not available.** Cars that cannot turn round stop, one nose-to-wall car
  holds the junction it is standing in, and the street behind it queues. Whatever replaces a
  manoeuvre has to keep the road moving.
- **The last resort is stated over *why* an arc was refused, never over how much room is left.**
  Reversing a heading where the car stands is the one manoeuvre with no path in it, so it may only
  be reached from a state that waiting cannot mend. "Stopped with less than a nose's length of
  room" is every car that has braked to its own aim point, so that test spins cars round on the
  ordinary case. Split the refusals: **a lane occupied at the landing empties by itself; the
  ground, the geometry and the map do not.** Wait on the first, and bound the wait, because waiting
  on a car that is itself stopped is a deadlock.
- **A reversal that lands in the same state is the flicker, not the escape.** It swaps the lane a
  car belongs to without moving it, and the cross-steer then slides the body to the other lane's
  centre under every jump threshold — a car shaking its head. So a car with less than a half turn's
  road *both* ways stands still instead, and leaves the way a pocketed body leaves, once nobody can
  see it go. **Ask what the manoeuvre changes about the state that caused it**; if the answer is
  nothing, it is not a manoeuvre.

**And a car that lands from a turn has to be able to leave.** The arm probe is a single point seven
tiles out and looks straight past a two-tile plug. The exit is checked for a turnaround's worth of
road, which is the same *nothing enters a junction it cannot leave* rule read one street further on.

## The heading is the datum, and it is continuous

`LaneMover.heading()` is a unit vector along the car's actual line of travel — cardinal in a lane,
the **tangent of its own arc** mid-turn — and `LaneMover.velocity()` is that times the speed it is really
doing. Everything downstream reads it: the lethal strike box and the horn, right of way at a box,
the checkpoint gate's along/across projection, the shadow, and the picture. **A turn that changes
the axis without changing this points every one of them at a car that is not there.**

`LaneMover.travelling_vertically()` follows the heading mid-turn for the same reason: a car that has swung
past the diagonal is across the traffic it used to be queueing with.
