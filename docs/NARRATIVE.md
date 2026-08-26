# Nappy — Narrative

## Premise

Nothing is explained. The player is a mother with a baby that will not sleep. She walks.
The story is entirely in *what she walks past*, and the fact that she keeps having to walk
past it because the baby still will not sleep.

## Acts

A run is 14 days, split into four acts. The act determines the colour cast, the ambient
audio bed, and which events are eligible (every `EventDef` carries an `act_tag`, and a test
asserts nothing from a later act leaks into an earlier day).

The colour cast is the quietest part of the telling: the same corner, four times, getting
colder. Warm afternoon → drained → cold and overcast → smoke.

The loudest part is that **the city remembers**. `scar_id` makes a one-off event permanent
for the rest of the run: the building that burned on day 3 is still a cordoned-off shell on
day 12, and every barricade an Act IV convoy drops stays dropped. The route you memorised
on day 2 stops existing, one closure at a time.

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

Cold palette, overcast. Streets are emptier — `quiet_road` replaces `busy_road` on the
arterials and actually *reduces* the ambient noise, from 3.2 to 1.4. This is the cruellest
joke in the design, and it is a real number rather than a line of text: the city gets
easier to put a baby to sleep in, because there is nobody left in it.

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

- **The alley roulette.** From Act III (`TRAP_FIRST_DAY` 8), an alley contact has a
  `TRAP_CHANCE` of 0.3 that an `alley_robbery` is waiting *at* it. The contact is still
  there; going for it is the gamble. Seeded from the run seed and the day, so the alley
  that was safe on day 9 of this run is safe on day 9 every time you replay it — the
  pattern is learnable, which is the difference between risk and a coin flip.
- **Being seen.** A `police_patrol` within `SEEN_RADIUS` of a contact while you are holding
  resets the hold to zero. *This is a change from the original plan, which docked a
  resistance point.* Taking away progress the player has already banked reads as a bug more
  than a consequence, and it is invisible at the moment it happens. A reset costs the thing
  the subquest is actually about: more seconds standing still in an alley, with the meter
  you care about doing the wrong thing. The cost is legible while you are paying it.
- **The deadline.** Step 4 expires at `deadline_fraction` (0.55) of the day. A warning
  delivered late is not a warning, and the contact is gone for the rest of the run.

### The finale

Reaching `RESISTANCE_GOAL` earns the *chance* at the good ending; the day-14 sabotage is
the act. `GameState.earned_good_ending()` requires both, so a player who does all the
legwork and then walks straight home on the last night gets the neutral ending.

### Feedback

There is no quest log and no marker. In the world the subquest is a chalk mark on an alley
wall, drawn *under* everything that stands on it, found by walking past it. The HUD carries
one terse line — how far in you are, and, while you are actually holding, how much is left
— and the day summary spells out the tally once. That is the whole of it.

## Endings

### Bad — Nerves at 0

Whichever day it happens on, the run ends. She stops going out. The city continues without
her. Short, flat epilogue text over a static shot of the apartment window.

### Neutral — survive 14 days, resistance incomplete

The baby sleeps. The city is quiet now, in the way an occupied city is quiet. Epilogue over
the same daily walk route, now empty of everything the player learned to avoid.

### Good — resistance complete + day 14 sabotage

The loudspeakers cut out mid-sentence. First real silence in the run, and it is mechanical
rather than described: completing the sabotage retires every `city_wide` source, so the
ambient floor is **zero** for the first time since the masts went up on day 5. The player
walks home in the easiest conditions in the game, and that is the reward.

It is also the only moment the HUD says anything out loud — one line, for seven seconds,
where the "not settling" hint normally sits.

## Tone rules for writing content

1. Never have a character explain the politics. The player infers.
2. The baby is never in narrative danger from the regime directly — the danger is always
   *noise*. Keep the horror ambient.
3. No triumphalism in the good ending. The reward is quiet, not victory.
