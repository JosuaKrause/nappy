# Playtest 12 — the shape of the city, played

The twelfth report, and the first taken **inside** a milestone rather than after one: M41 was on a
branch and half-built, so this is the street hierarchy being judged the day it first existed. Ten
things, delivered in one sitting as the player walked around it.

That is the useful part of it. Every previous playtest of a structural change arrived a milestone
late — M27's streaming, M34's solid bodies and M37's silhouettes were all measured by a rig and
seen by nobody until the milestone after them. This one caught a spine with two roads in it, a
precinct in every corridor and a light nobody could read while all three were still a diff.

---

## The findings, as reported

| # | What the player said | Kind |
|---|---|---|
| 1 | "there are way too many pedestrian only zones and they should have a higher density of events (also people seems to not go in the middle)" | design + bug |
| 2 | "there should be one north to south main road I had multiple (and there should be no east to west ones at all)" | design |
| 3 | "the traffic volume on the main road was too sparse so I could almost always ignore the lights" | balance |
| 4 | "the lights themselves are a bit confusing it's not clear which one belongs to which roadway" — and the fix: "turn the ones that are for the horizontal roads. that makes the light only visible as cone but then the direction is clear. also keep them on the side of the road — don't move them away from the road" | design |
| 5 | "it is now much harder to find a calm space, that equation shouldn't change there should be the same amount still. since each day one gets removed we need as many as days in an act (+1 more as backup). that forces exploration. at the end of an act we can reset the used up status" | design |
| 6 | "let's increase the sleepiness speed for calm zones again" | balance |
| 7 | "a stretch of three blocks at the shore (like a coney island beach walk) and three blocks in the city somewhere — no more" | design |
| 8 | "those are retail zones so there is a lot of foot traffic and restaurants etc — generally not calm but easier to reduce excitement than alongside roads — order is: excitement decay (best) calm → pedestrian → side road → main road (worst)" | design |
| 9 | "I think we can make the map even bigger" | design |

---

## The one sentence

**A hierarchy is only a hierarchy if there is one of the top thing.**

Findings 1, 2 and 7 are the same mistake made twice. M41 put a main road on *each* axis and a
precinct in *every* corridor of both, because the generator was written to answer "what kind is
this corridor" for all of them — and a spine that crosses itself is two spines, and a precinct you
meet on every third street is what a street is. The city ended up with three kinds of street and
no hierarchy among them, which is the thing the milestone existed to build.

The correction is that two of the three kinds are **places** rather than classes: there is *the*
main road, one of it, running north to south; and there are *two* precincts, three blocks each,
one along the southern shore and one in the city. Everything else is a street.

## Finding 8, which is the one that changes the meters

The other nine are about where things are. This one says what a street *does*: the ground's
excitement decay is no longer uniform, and the order is

    calm  >  pedestrian  >  side road  >  main road

so choosing a route is choosing a recovery rate, and not only a set of things to walk past. It is
the first time since M14 that the ground under her feet has done anything except be calm or not,
and it is what makes the precinct worth walking to even though it is loud: a retail street is
busy, and it is still the best place in the city that is not a park to bring a meter down.
