# Nappy — Narrative

## Premise

Nothing is explained. The player is a mother with a baby that will not sleep. She walks.
The story is entirely in *what she walks past*, and the fact that she keeps having to walk
past it because the baby still will not sleep.

## The two names

She is **Peregrine**. The baby is **Wren**.

They are the only proper nouns in the game — the city has no name, the country has no name, and
nobody on the other side of a checkpoint is ever given one. Two is what the premise can afford:
a name says who somebody is to *you* without saying where they are or which side they are on,
which is the one piece of explaining that costs nothing.

Both are birds and neither reason is on the surface, which is the register this wants. A **wren**
is small and will not settle. *Peregrinus* is a common noun before it is a name — *the one from
abroad, the one passing through* — and the falcon is the **pilgrim** falcon, named for only ever
being seen on passage, never where it nests. She has a home she cannot stay in, and the city gets
less hers every day. The whole game is the walk between those two facts.

Considered and rejected: **Hal**, for the halcyon and its fourteen days of calm — the arithmetic
was perfect (a run is fourteen days, and the halcyon's whole job is to make the world quiet enough
to nest in) and the name reads male on sight, which costs the premise more than the reason buys.

**These names are content and never identifiers.** Nothing in `src/` is named after them; see
`CLAUDE.md`, "Names are content, never identifiers". A name can change and a rename that has
reached the code is a diff nobody can review.

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

**Day 4:** the first `resistance_contact` appears in an alley. No prompt, no quest marker
beyond a chalk mark on the wall that the player may or may not notice, and it is guarded
from this first appearance on — see "Risk" below.

### Act III — "Vans" (days 8–11)

Cold palette, overcast. Streets are emptier — literally: from act I's crowd, the streets
keep about a fifth of the people and a quarter of the cars, and the arterial that ran at
three times the idle decay in act I falls below it. The city gets *quieter*. This is the cruellest joke in the design, and it
is now something the player can see rather than only feel: the pavement she walked down on
day 1 shoulder to shoulder is empty. The city gets easier to put a baby to sleep in,
because there is nobody left in it.

Abductions begin. Masked men, unmarked vans. Getting close is a hard fail — you and the
baby are taken, day over, one Nerve gone.

### Act IV — "Open" (days 12–14)

Smoke, sirens, barricades. Military convoys re-shape the map as they pass. Protests grow.
Whole districts close.

**Day 14** is the finale — either the sabotage route (good ending) or simply the last walk
home (neutral ending).

## The resistance subquest

### Design intent

The subquest must *cost the core resource*. Joining the resistance means deliberately
choosing the worst routes for your baby: alleys, crowds, closed districts, a stranger's
own field. The player trades the thing they have spent the whole game protecting, and every
task is one verb — **get to a guarded place and touch it.**

### Structure

A task is two beats: pick up the instruction at a chalk mark, then perform it the next day.
Touching either is instant — there is no key to hold, and no standing still to pay for. Only
the perform half grants **1 resistance progress**; the mark is the note, not the errand.
`RESISTANCE_GOAL` is 4 of the 5 perform beats, which lets the player miss one task
entirely and still reach the good ending.

| Days | Task | What |
| --- | --- | --- |
| 4 / 5 | A note for a stranger | A chalk mark, then touch the right `homeless_yeller` — several are live at once and look alike, so a wrong one costs his field and tells you nothing. |
| 6 / 7 | The package | A chalk mark, then touch the delivery van's drop. Picking it up makes the pram heavier for the rest of the day. |
| 8 / 9 | The checkpoint | A chalk mark, then walk through the checkpoint itself rather than round it. |
| 10 / 11 | The wall | A chalk mark, then reach the poster crew's wall before they finish it — the window closes if the crew moves on first. |
| 12 / 13 | The protest | A chalk mark, then reach the middle of the densest crowd in the city. |
| 14 | The last night | The finale, offered only once the goal is met. Sabotage. |

### Risk

- **Every mark is guarded**, from the day the first one can appear. A robber waits somewhere
  between 66px and 176px of it — inside that band touching the mark is death, always; above
  it he never wakes at all; between them, which side she approaches from decides whether he
  notices her. Seeded from the run and the day, so the distance that was safe on day 9 of
  this run is safe on day 9 every time you replay it — the pattern is learnable, which is
  the difference between risk and a coin flip.
- **A wrong candidate costs full price and returns nothing.** Approaching the yeller's field
  is the cost whether or not he is the contact, and there is no way to tell in advance which
  one is.
- **The deadline.** The wall's window closes when the poster crew's own instance is gone —
  paste it over and the contact goes with it, for the rest of the run.

### The finale

Reaching `RESISTANCE_GOAL` earns the *chance* at the good ending; the day-14 sabotage is
the act. `GameState.earned_good_ending()` requires both, so a player who does all the
legwork and then walks straight home on the last night gets the neutral ending.

### Feedback

There is no quest log and no marker. In the world a pickup is a chalk mark on an alley
wall, drawn *under* everything that stands on it, found by walking past it; a perform's
contact is invisible, riding silently on the ordinary-looking thing it rides on. The day
brief is the only channel that ever tells her what is next — touching a mark reads its
words back to her on the following day's screen — and the HUD carries one terse line,
*somewhere out there* and what she is looking for. How far in she is belongs between days
rather than during one. That is the whole of it.

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
