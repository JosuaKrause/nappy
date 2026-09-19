# Playtest 78 — 2026-09-19

Said in conversation on 2026-09-19 about the released build, v0.11.1, with no run folder
attached. Two findings, the second of which arrived as the answer to a question about the
first.

## A closed-off street calms the baby better than the route's own sidewalk

> "another thing I noticed is that it is easier to go to a completely closed off area (eg
> walking via the roadway) to calm the baby down than it is to just walk back and forth on the
> regular sidewalk on a path. this is because there is no pedestrian traffic in the closed off
> area. and on the regular path the noise from the crowd itself is too high. we need to nerf the
> crowd influence a little bit. any ideas how to approach this?"

The numbers behind it are the ones `tests/probes/m117_decay.gd` reads (`DECISIONS.md`, M117,
excitement decays visibly on quiet ground): walking gives the meter back
`Tuning.EXCITEMENT_DECAY_WALKING`, 6.0 points a second, on ordinary ground with nobody near,
and a quiet ordinary sidewalk in act I nets about 3.6 a second because the walkers around her
load the rest back on. A walker charges `Tuning.PEDESTRIAN_INTENSITY`, 4.2 a second, inside
`PEDESTRIAN_INNER_RADIUS`, 22 px, fading to nothing at `PEDESTRIAN_OUTER_RADIUS`, 55 px, on a
sidewalk 64 px wide — so no line along a sidewalk with people on it is out of everybody's reach.
A street the day's closures have shut has no walkers and no cars on it, so it gives back the
whole 6.0, which is nearly a precinct's 6.6.

Four ways to bring the crowd's share down were offered: a shorter reach, a lower intensity,
walkers stepping aside wider, and fewer walkers in act I. The shorter reach was recommended,
because a close pass keeps its full price — *careless is expensive and careful is free* is what
`tuning.gd` says the crowd's numbers defend — while the middle of a sidewalk between walkers
becomes nearly free.

> "I like the shorter reach idea. main road can stay as expensive as before. we can also let the
> walkers step aside more politely"

So three things: the walker's outer radius comes down from 55 px toward 40 px, against a target
of about 4.8 a second given back on a quiet act I sidewalk; walkers give her more room when
they step aside (`Tuning.CROWD_YIELD_LATERAL`, 22 px, is how near a walker's closest approach
has to come before it bothers); and the main road's measured cost stays where it is, which is
an instruction rather than a side effect to tolerate — if shortening the walkers' reach lowers
the main road's floor, the cars' numbers make it up. Filed as M155 in `TODO.md`.

## The crowd gives up on a street at an event, and should only give up at what stops it

Asked whether a quiet closed-off street is an exploit — with a slower decay there, or walkers
that keep using it, as the two ways to close it — the player answered with the cause instead:

> "cars shouldn't avoid it. I noticed cars turning around even though the obstacle is on the
> sidewalk. only things like a fallen tree (which blocks the whole street) should prevent cars
> from entering (in which case the player cannot exploit the area either). also pedestrians
> should only avoid the area if they cannot reach it physically. right now they give up if
> there is an event at all when they should only give up if they touch an impassable wall. that
> leads to two changes: 1) they should still walk through a car accident since the sidewalk is
> free there 2) they should be able to spawn inside a closed off section but shouldn't stand in
> one place but instead walk until they are forced to turn around (by the environment)"

What the code does today, read from `CrowdAgent._cannot_go_on`, the one predicate both the
lookahead and the turn at the last junction trust. A car treats as shut: a closed tile, a held
segment (a hard seal's ground or a region wall), a tile of its own lane a stationary solid body
stands on, a precinct, and the map's edge. A walker treats as shut: a closed tile, a held
segment, a soft-sealed tile (a soft seal takes both sidewalks of a street and leaves the
roadway), and a point along the street where every lane of its own sidewalk has a body on it.
Either kind turns off at the last junction before such a tile rather than walking or driving
up to it. `CrowdPockets` separately keeps both kinds out of ground the day's seals leave no
street out of — a junction with all four arms held and the stubs sealed in with it — by never
placing an agent there and standing still one that is caught there.

What is asked for, as four statements:

- **A car is kept out of a street only by something that blocks the whole street**, a fallen
  tree being the example. An obstacle on the sidewalk never turns a car. Where a car is seen
  turning for one today is not known from the code alone and is the first thing to find.
- **A walker is kept out only of ground it physically cannot reach**, and it turns where it
  meets the impassable thing, not at the junction before it and not because an event is there.
- **A car accident leaves its sidewalk walkable, so walkers walk past it.**
- **Walkers may be placed inside a closed-off section, and they keep walking** until the
  environment turns them round.

One overlap with an earlier instruction, put to the player the same day. On 2026-09-12 the player
asked that pedestrians and cars with nowhere to go — *"all four sides of the intersection are
blocked off"* — *"should just despawn (or never spawn in the first place) right now they're
accumulating in one place and move back and forth or worth flicker"*, which is what
`CrowdPockets` builds. The fourth statement is unambiguous for a closed-off *section*, two
junctions of street or more, which `CrowdPockets` leaves populated by design. For the single
shut-in junction of the 2026-09-12 instruction the two sentences pull apart — a walker there
has one stub to pace, which is the flicker the earlier sentence is about — and the recommended
reading, that it stays empty, waits on the player's answer. Filed as M156 in `TODO.md`.

---
