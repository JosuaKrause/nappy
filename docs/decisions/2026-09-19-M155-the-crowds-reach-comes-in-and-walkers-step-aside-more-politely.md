## M155 — The crowd's reach comes in, and walkers step aside more politely · built 2026-09-19

*(2026-09-19, [PLAYTEST-78](../playtests/PLAYTEST-78.md): "it is easier to go to a completely closed
off area (eg walking via the roadway) to calm the baby down than it is to just walk back and
forth on the regular sidewalk on a path … the noise from the crowd itself is too high. we need
to nerf the crowd influence a little bit." Offered a shorter reach, a lower intensity, a wider
step-aside or fewer walkers: "I like the shorter reach idea. main road can stay as expensive as
before. we can also let the walkers step aside more politely".)* Three agent commits on
`feature/m155-crowd-reach`; the probe at three states is
`evidence/m155-crowd-reach-2026-09-19/`, with a README saying which tree each was taken on.

**The probe.** `tests/probes/m117_decay.gd`, three seeds, net points per second while walking
(negative is given back):

| Leg | before | louder cars, rejected | built |
|---|---:|---:|---:|
| Quiet sidewalk, day 1 | −3.95 | −4.20 | **−4.73** |
| Quiet sidewalk, day 9 | −5.77 | −5.73 | −5.88 |
| Main road, day 1 | +5.71 | +5.70 | **+5.69** |
| Main road, day 9 | −0.13 | −0.12 | **+1.36** |
| Precinct, day 1 | −6.53 | −8.13 | −8.13 |
| Alley, day 1 | −0.10 | −0.45 | −0.45 |
| Calm | −10.60 | −10.60 | −10.60 |

**The reach.** `PEDESTRIAN_OUTER_RADIUS` 55 → **30**, with `PEDESTRIAN_INTENSITY` (4.2) and
`PEDESTRIAN_INNER_RADIUS` (22) untouched, so a close pass keeps its price and the middle of a
sidewalk between walkers is nearly free. 40 and 35 were tried and gave back less (−4.62, −4.68);
28 moved nothing further. The aim was four fifths of the empty street's 6.0; it reaches 79%.
The precinct and the alley move with the radius and were not held: nobody asked for them to be.

**The main road's price is held by the main road's own ground.** The shorter reach takes the
walkers on the spine's sidewalks out of what the spine costs, and the player's instruction was
that it stays as expensive. The agent's first lever was `CAR_INTENSITY` 5.4 → 7.7, which held
day 1 exactly and was rejected in review: a car is on every street, so it took back half of
what the radius had bought the quiet sidewalk and made every ordinary crossing dearer.
`EXCITEMENT_DECAY_MAIN_ROAD_MULTIPLIER` 0.35 → **0.02** replaced it, the one number that is
only true of main-road tiles. Day 1 is the day held, because `tests/test_crowd.gd`'s arterial
floor, ceiling and crossing cost are stated against it; the worst-of-eight crossing reads 27.8
of the meter against 26.2 before, under the half-meter line, since the shorter reach lightens
what a crossing walks through by about what the ground stops giving back.
**The orchestrator's choice, shown to the player with the table above and accepted** *(2026-09-19: "numbers look good")*: one multiplier
serves the whole run, so day 9's main road goes from giving a sliver back to costing 1.36 a
second — the spine in the emptied acts is dearer than it was, which *"as expensive as before"*
does not ask for. A multiplier per act, or more walkers on the spine's own sidewalks, would hold
both days; neither was built.

**The step-aside.** `CROWD_YIELD_LATERAL` 22 → **30**. At 22 it equalled the walker's
full-intensity core, so it only fired for a pass already inside it, and the ordinary pass — her
on the midline of a two-lane sidewalk, a walker holding a lane 24 px away — never made anyone
move. 30 catches that pass and stays short of the 48 px between a sidewalk's two lanes, so the
far lane is left alone and a sidewalk does not part in front of her. `BUMP_STEP_ASIDE` (32 px,
how far a walker steps) already clears it. On a throwaway rig driving `Crowd._make_way` on a
generated city, three seeds: closest approach on a head-on midline pass 24 → 32 px, walker
noise over the approach 0.73 → 0.00 points, contacts none either way.

Whether pacing a quiet sidewalk now reads as recovery, and whether walkers stepping aside read
as polite rather than as fleeing, are in `REVIEW.md`.
