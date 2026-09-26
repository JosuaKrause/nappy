## M129 — A wall is also what cannot be walked past, and it stands across the street from the route · built 2026-09-19

*(2026-09-15, [PLAYTEST-77](../playtests/PLAYTEST-77.md): "on the side of the street where the path
was chosen only obstacles that can be bypassed should be possible" — "the market stall should
appear on the other side of the street" — "a wall is also when you physically cannot walk
through". Offered a placement-only rule instead, the player chose the role reading: "that seems
to be more thorough".)* Built by an agent on `feature/m129-wall-passability`; the probe at three
states is `evidence/m129-wall-passability-2026-09-15/`, with a README saying which commit each
was taken on.

**What was wrong.** `EventScheduler._role_for` answered `WALL` only for a lethal row or one whose
walk-through cost reaches `Tuning.WALL_WORTH_OF_COST` (35 of the meter). A market stall — a 28 px
body denying 58 px of a 64 px sidewalk — was therefore *friction*, weighted onto the corridor four
to one by `Tuning.EVENT_CORRIDOR_WEIGHT`, and the width rule only asked that *either* sidewalk of
the street stayed walkable. So a stall could close the very sidewalk M150's kerb tint marks as
the route.

**The three changes.**

1. **`_role_for` gains a passability clause.** A standing row is also a wall when its body plus
   the ground it charges for (`_line_reach_of`) leave no line past it along a sidewalk it may
   stand on — the far lane of a two-lane sidewalk, one tile out, the tile grain every other rule
   here is measured in. The rows it catches, with what each denies of the 64 px and its
   walk-through cost: `cafe_tables` 56 px, +6.1; `market_stall` 58 px, +8.5; `construction`
   32 px of body alone, −26.1; `ice_cream_van` 189 px, +18.4. `delivery_van` (22 px) stays
   friction, since a lane of its sidewalk is still free.
2. **`_copies_of` reads the corridor per sidewalk.** `Corridor.carries_a_route(tile)` answers
   whether the tree runs along *this* sidewalk, at the grain of M150's tint. A wall gets zero
   copies there, so the far side of a route's own street is legal ground for one.
3. **The width rule reads the sidewalk the route is walked along**, cumulatively with
   everything already down. A street's two sidewalks are not four-connected to each other, so
   the question was already *one band is open*, and the band it accepted could be the one no
   route walks.

**The two forks the player answered on the pull request (2026-09-19).**

- **A wall across the street is common, not rare.** Asked whether the far sidewalk of a route's
  own street should carry the baseline one copy, as first built, or the rim's four, the player
  chose often. The costly half of the wall band takes `EVENT_WALL_RIM_WEIGHT` (4) at one street
  out *or nearer*, so the rim has two members: a turning she might wrongly take, and the far
  side of the street she is already on. The lethal half keeps `WALL_DEEP_WEIGHT` past the rim,
  so nothing that ends the day is drawn to the other side of her street in particular. Seed
  4242 over days 1/5/8/11/14, walls on a route street's far sidewalk: 7, then 31 with the
  shouting man still a wall, then 21 once the second fork gave him back to the corridor.
- **A pacing row is a wall only where its beat has no way out.** *"Yeller is something you can
  time. It stays on the route"*, and: *"if the yeller paces across a crosswalk then there is a
  way to avoid them. if they stay on the segment for the whole time with no side route then
  there is no way to avoid them. distinguish those cases when deciding whether the yeller is a
  wall."* So the clause splits. `_takes_a_whole_sidewalk`, the role's question, answers no for
  a pacing row: `homeless_yeller` is friction and corridor-weighted.
  `_a_pacing_beat_walls_a_sidewalk` is asked per candidate, where the beat exists, and a beat is
  not a wall when its run passes a **junction box** — the only ground a crosswalk is painted
  on — or a **side route**, ground off the street opening off the sidewalk's own side. A beat
  that passes neither records `WALL` and is refused any tile a route runs along. Its pool was
  built at friction's weights, because a role that depends on the beat cannot be known before
  the tile is rolled; it takes the wall's refusal and friction's weighting, and `EVENTS.md` says
  so. The width rule skips pacing rows entirely: counting his lens as a width would have
  refused him the route's sidewalk for the one reason the player ruled out.

**Rejected.**

- *A placement-only rule*, leaving the role alone: offered, and the player chose the role
  reading as the more thorough.
- *The yeller as a wall by arithmetic.* A beat runs along a sidewalk and moves the row nowhere
  across it, 170 px of charged ground over 64 px, and the discs at the beat's two ends still
  overlap 112 px across, so no phase opens a lane. True, and beside the point the player made:
  the way past a man walking a beat was never a lane.
- *A flood fill for "does this side route lead anywhere".* It is the exact question, per
  candidate inside the placement loop, hundreds of times a day. The side route is read two
  tiles deep instead: one tile of walkable ground against a frontage is a doorway notch, and
  everything that leads somewhere is a lot deep. It errs toward refusing, the conservative
  side of a rule that only ever refuses ground.

**Measured.** `tests/probes/m129_zero_cost_line.gd`, six seeds by one day per act, routes with
a zero-cost line under the primary reading:

| | before | the three changes | with the forks |
| --- | ---: | ---: | ---: |
| act I | 83.7% | 100.0% | 95.3% |
| act II | 67.0% | 95.5% | 93.2% |
| act III | 54.1% | 93.2% | 86.5% |
| act IV | 25.0% | 75.0% | 70.8% |
| all | 183 of 296 (61.8%) | 275 of 296 (92.9%) | 262 of 296 (88.5%) |

Density does not move: 431 placed rows a day at every state. The 4.4 points between the last
two columns are the shouting man back on the route, the price the player accepted with "it
stays on the route": the probe prices a beat at the ground it never leaves free, which for a
170 px field over a 64 px sidewalk is both lanes at the middle of the beat. He never breaks a
route by himself — the shape named for a beat is no routes and one cut — but he stands in the
blocked stretches of 25 of the 34 broken routes, behind `leaf_blower`'s 27 and ahead of
`roadblock`'s 23. The side route changed no placement the primary reading can see: of 52 pacing
placements in the suite's sample, 7 pass a side route and all 7 pass a junction as well.

What still breaks a line is almost all one shape, the junction itself taken (32 routes, 40
cuts), by rows no sidewalk rule reaches: `roadblock` on a carriageway and a wall's wide field
reaching over a crossing from one street out. That is the item left under M129 in `TODO.md`,
which placements the three rules never see.

**The suite**, seed 4242 over days 1/5/8/11/14: friction on the corridor 42% to 37% against an
untouched floor of 35%; paced route streets 19 to 23 against an untouched floor of 3; walls on
a route street's far sidewalk 0 to 21; every one of 15 pacing placements on a walked sidewalk
has a way out in its beat. **One floor moved and is open to overturn**: the narrow-friction
share went 50% to 44% and its floor 0.45 to 0.40. Its docstring named the junction rule as the
one rule that takes corridor ground from a row; there are three now, all biting on the corridor
and nowhere else, so what the floor defends is that the four-to-one weight shows *through* all
three. With the route-sidewalk rule switched off the same sample reads 47%.

The look a rig cannot take — whether the walked side still reads as a street, whether the far
side is visible early enough to be the answer, whether the shouting man reads as something to
time — is an entry in `REVIEW.md`.
