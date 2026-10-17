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
a street for good. A flood past every body over eight seeds reached no exit on any of them. The
escape never had the yellow curb tint: [M145](2026-09-14-M145-the-routes-curbs-tinted-faint-yellow-built-an-experiment.md)
draws it from a day's route tree, which the escape does not have.

**Built (PR #755).** `_fill_a_finale_street` refuses, before accepting it, a placement that would
leave neither sidewalk of a chain street walkable from junction to junction, counting every body as
it stands for the whole walk (the parked van, the band after its guard leaves, each explosion as its
crater); it asks the day's own physical check, `closes_a_walked_sidewalk_band()`, of both sidewalks.
A refused candidate is not replaced, so the street carries one fewer; nothing is repaired afterwards
and no event's lifetime changes. Over eight seeds the chain streets keep their pressure: 216
roadblocks where there were 232, the same 241 vans. `City.tint_the_escape_route()` tints both kerb
lines of every street the plan's chains run through, after every plan, restarts included.
`tests/test_finale.gd` floods from the service exit past every body over eight seeds and requires
both exits (15 of its 16 checks fail on `main`), and checks the tint is on the escape's streets and
no others.

**Choices open to overturn:** either sidewalk counts as the open one, not only the side the chain's
cells run along; the seals are not part of the check (they stand on streets the chains do not use);
the tint is whole streets and both kerb lines, as on a day; an escape started from a scene recipe
gets no tint.
