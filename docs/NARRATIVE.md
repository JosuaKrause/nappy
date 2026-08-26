# Nappy — Narrative

## Premise

Nothing is explained. The player is a mother with a baby that will not sleep. She walks.
The story is entirely in *what she walks past*, and the fact that she keeps having to walk
past it because the baby still will not sleep.

## Acts

A run is 14 days, split into four acts. The act determines the palette, the ambient audio
bed, the NPC density, and which events are eligible.

### Act I — "It's a nice neighbourhood" (days 1–3)

Warm palette. Full sun. Lots of pedestrians, dogs, kids in the playground. The obstacles
are *pleasant* things — a busker, a cat, a friendly neighbour. The only genuinely
unpleasant thing is a man yelling on a corner, and everyone walks around him.

Day 3 ends with the fire truck and a burning building. Read as an accident.

### Act II — "Notices" (days 4–7)

Palette desaturates slightly. Posters go up. Loudspeaker masts are installed on day 5 and
switch on with a test tone. Police patrols appear. On day 6 a curfew is announced and the
day gets shorter.

The burnt building from day 3 is still there, cordoned off, never repaired. Same tile,
every day, for the rest of the run.

**Day 5:** the first `resistance_contact` appears in an alley. No prompt, no quest marker
beyond a chalk mark on the wall that the player may or may not notice.

### Act III — "Vans" (days 8–11)

Cold palette, overcast. Streets are emptier — `empty_street` actually *reduces* some
ambient noise, which is the cruellest joke in the design: the city gets easier to put a
baby to sleep in, because there is nobody left in it.

Abductions begin. Masked men, unmarked vans. Getting close is a hard fail — you and the
baby are taken, day over, one Nerve gone.

Alleys become genuinely dangerous: the same alleys that carry the resistance contacts also
now carry `alley_robbery`.

### Act IV — "Open" (days 12–14)

Smoke, sirens, barricades. Military convoys re-shape the map as they pass. Protests grow.
Whole districts close.

**Day 14** is the finale — either the sabotage route (good ending) or simply the last walk
home (neutral ending).

## The resistance subquest

### Design intent

The subquest must *cost the core resource*. Joining the resistance means deliberately
choosing the worst routes for your baby: alleys, crowds, closed districts. The player
trades the thing they have spent the whole game protecting.

### Structure

| Step | Day | Where | What |
| --- | --- | --- | --- |
| 1 | 5+ | Alley, chalk mark | Walk to the mark and hold **E** for 3 s. Alley trickle is running the whole time. |
| 2 | 7+ | Different alley | Contact person. Requires standing in the alley for 6 s. |
| 3 | 9+ | Civic district | Deliver a package — a route *through* high-excitement streets, because the quiet ones are watched. |
| 4 | 11+ | Any alley | Warn a contact before a raid. Timed: must arrive before the `night_raid` scripted event fires. |
| 5 | 13 | Industrial | Pick up the device. |
| 6 | 14 | Civic | Sabotage. The finale. |

Each completed step grants **1 resistance progress**. `RESISTANCE_GOAL` is 4 of the first
5 steps, which lets the player miss one and still reach the good ending.

### Risk

- Alleys used for contacts have a per-day chance of being a robbery instead. Seeded, so
  the same alley is not always the trap — but the run's pattern is learnable.
- From Act III, being seen near a contact by a `police_patrol` costs a resistance point.
- Failing a timed step (step 4) removes it permanently — the contact is gone.

### Feedback

There is no quest log in the HUD. The state is expressed as chalk marks on walls, which
change between days. `docs/TODO.md` tracks a codex screen in the day summary as the
concession to legibility.

## Endings

### Bad — Nerves at 0

Whichever day it happens on, the run ends. She stops going out. The city continues without
her. Short, flat epilogue text over a static shot of the apartment window.

### Neutral — survive 14 days, resistance incomplete

The baby sleeps. The city is quiet now, in the way an occupied city is quiet. Epilogue over
the same daily walk route, now empty of everything the player learned to avoid.

### Good — resistance complete + day 14 sabotage

The loudspeakers cut out mid-sentence. First real silence in the run — mechanically
expressed: on the final walk home, the ambient excitement floor is **zero** for the first
time since day 5. The player walks home in the easiest conditions in the game, and that is
the reward.

## Tone rules for writing content

1. Never have a character explain the politics. The player infers.
2. The baby is never in narrative danger from the regime directly — the danger is always
   *noise*. Keep the horror ambient.
3. No triumphalism in the good ending. The reward is quiet, not victory.
