# grassy-dolphin — The escape's streets keep a sidewalk open and carry the yellow tint · 2026-10-17

[fluffy-kestrel](../playtests/2026-10-17-fluffy-kestrel.md), #741: "In the city there is no route that
is available and no guidance markers on the road". Answering (inbox #747): "roadblocks currently are
impossible to get past. one sidewalk must be open if they're en-route. the escape's street should
not have fully blocking events like in the normal game. also, yes, of course the yellow tint. we
spent the whole game establishing that why would it be different in the last section?"

**What was wrong.** `EventScheduler.build_finale` put one van and two roadblocks on every street a
chain walks, with nothing checking that the street stayed walkable. A van's body shuts the whole
sidewalk it stands on; a roadblock's band covers one sidewalk and the carriageway. Since sandy-ferret
(#663) the hunting van stays parked and solid, and since spotted-wombat (#676) the band stands for
the whole walk, so a van on one side and a band on the other, or two bands on opposite sides, closed
a street for good. A flood past every body over eight seeds reached one exit of sixteen (seed 77's bridge). The
escape never had the yellow curb tint: [M145](2026-09-14-M145-the-routes-curbs-tinted-faint-yellow-built-an-experiment.md)
draws it from a day's route tree, which the escape does not have.

**Built (PR #755).** `_fill_a_finale_street` asks two questions of a placement before accepting
it, counting every body as it stands for the whole walk (the parked van, the band after its guard
leaves, each explosion as its crater) where the game builds it, and the seals with them: an unused
alley's mouth wall lies along the chain street it opens onto and takes the outer lane of that
street's sidewalk. **One sidewalk stays open**: the day's physical check,
`closes_a_walked_sidewalk_band()`, asked of both sidewalks. **The walk stays joined**: on an 8px
grid of her centre, any two points on the edge of a box round the placement that were connected
inside it without the placement must still be connected with it, and so must the service exit and
the exits where they fall inside; that is the day's junction rule asked of a box round the
placement, and it keeps an alley's mouth open as well as the street. Since the seals alone leave
both exits reachable, every accepted placement does too. A refused candidate is rolled again or
not placed; nothing is repaired afterwards and no event's lifetime changes. Over seeds 1 to 20, against `main`, the
chain streets keep their pressure: 610 vans and 201 explosions as before, 530 roadblocks where there
were 588. Planning costs more: `FinalePlanner.plan` averages about 320 to 400ms where `main` takes
226 to 255ms (worst 557ms against 370ms), on the desktop, paid on entering the city section and on
every restart; on the phone it is likely several times that, not yet measured. `City.tint_the_escape_route()` tints both kerb lines of every
street the plan's chains run through, after every plan, restarts included. `tests/test_finale.gd`
floods from the service exit past every body, seed 23 among its seeds, and requires both exits (it
fails on `main`; a sweep of seeds 1 to 80 finds none failing), and checks through `Main` that the
first plan and a restart tint the escape's streets and no others, the day's tint gone.

**Choices open to overturn:** either sidewalk counts as the open one, not only the side the chain's
cells run along; the joined-walk check refuses more than it strictly must, since two points on the
box's edge may also join round its outside; the tint is whole streets and both kerb lines, as on a day; an escape started from a scene recipe
gets no tint.
