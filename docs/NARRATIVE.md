# Nappy — Narrative

## Premise

Nothing is explained. The player is a parent with a baby that will not sleep. They walk.
The story is entirely in *what they walk past*, and the fact that they keep having to walk
past it because the baby still will not sleep.

A new run chooses either the mother or the father with equal probability. That presentation
stays fixed through every day, retry and escape; it changes no route, rules or story outcome.

## The two names

The parent is **Peregrine**, in either presentation. The baby is **Wren**.

They are the only proper nouns in the game — the city has no name, the country has no name, and
nobody on the other side of a checkpoint is ever given one. Two is what the premise can afford:
a name says who somebody is to *you* without saying where they are or which side they are on,
which is the one piece of explaining that costs nothing.

Both are birds and neither reason is on the surface, which is the register this wants. A **wren**
is small and will not settle. *Peregrinus* is a common noun before it is a name — *the one from
abroad, the one passing through* — and the falcon is the **pilgrim** falcon, named for only ever
being seen on passage, never where it nests. The parent has a home they cannot stay in, and the city
belongs to them less every day. The whole game is the walk between those two facts.

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
is now something the player can see rather than only feel: the pavement they walked down on
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
| 4 / 5 | A note for a stranger | A chalk mark, then touch whichever `homeless_yeller` they reach first — several are live at once and look alike, so there is no wrong one to single out first. |
| 6 / 7 | The package | A chalk mark, then touch the delivery van's drop. Picking it up makes the pram heavier for the rest of the day. |
| 8 / 9 | The checkpoint | A chalk mark, then walk into the `roadblock`'s own band — the poured-concrete street closure, not a region door's hut — rather than round it. |
| 10 / 11 | The wall | A chalk mark, then reach the poster crew's wall before they finish it — the window closes if the crew moves on first. |
| 12 / 13 | The protest | A chalk mark, then reach the middle of the densest crowd in the city. |
| 14 | The last night | The finale, offered only once the goal is met. Sabotage. |

### Risk

- **Every mark is guarded**, from the day the first one can appear. A robber waits somewhere
  between 66px and 176px of it — inside that band touching the mark is death, always; above
  it he never wakes at all; between them, which side the player approaches from decides whether he
  notices them. Seeded from the run and the day, so the distance that was safe on day 9 of
  this run is safe on day 9 every time you replay it — the pattern is learnable, which is
  the difference between risk and a coin flip.
- **The contact is whichever look-alike the player hands the note to.** A perform step's contact does
  not wait at the one instance the day happened to seed; it rides onto whichever live
  look-alike — a `homeless_yeller`, a `delivery_van`, a `roadblock`, a `poster_crew` or a
  `protest` — the player is within reach of, and follows them from one to the next until they touch
  one. There is no exhaustive check to run and no wrong candidate to cost the player anything:
  approaching the field of any of them is still the cost, but any one they have noticed and walk
  up to is the right one. *(2026-09-13: "the task is always solved by going to any yeller she
  notices.")*
- **The deadline.** The wall's window closes when the poster crew's own instance is gone —
  paste it over and the contact goes with it, for the rest of the run.
- **Only a day the player wins counts.** *"a task is only complete if it is done on the day that won"* —
  a mark touched, a step performed, a contact lost to its deadline, a package picked up or the
  last night's sabotage are all given back when the day is lost, and the retry offers the same
  mark or contact again. So the errand is never spent on an attempt that failed, and a task
  cannot be lost to a day that did not happen; the price of a bad day is the nerve, not the
  subquest. See `GameState.finish_day()`.

### The finale

Reaching `RESISTANCE_GOAL` earns the *chance* at the good ending; the day-14 sabotage is
the act. `GameState.earned_good_ending()` requires both, so a player who does all the
legwork and then walks straight home on the last night gets the neutral ending.

### Feedback

There is no quest log and no marker. In the world a pickup is a chalk mark on an alley
wall, drawn *under* everything that stands on it, found by walking past it; a perform's
contact is invisible, riding silently on the ordinary-looking thing it rides on. The day
brief is the only channel that ever tells the player what is next — touching a mark reads its
words back on the following day's screen — and the HUD carries one terse line,
*somewhere out there* and what they are looking for. How far in they are belongs between days
rather than during one. **That line is silent until the first mark has been touched** —
the first encounter comes with no hint at all, and only later ones are named.

**A lost day repeats its own instruction rather than moving on.** *"the words shown on the lost
day are the words that show at the beginning of that day not the nexts."* The summary of a day
they lost reads out the words of the mark that unlocked the task they were out to perform — the
same words the summary of the day they found that mark already gave them — because a mark touched
on a lost day has its touch given back with the attempt, and the retry needs telling what the day
is for. A lost day 4 says nothing at all: its whole content is finding the mark, so there is
nothing yet to repeat.

A pickup mark that has never been on screen has never really been placed, so it follows
the player rather than sitting where the dawn plan first put it: once they are far enough from it
to have missed it, it moves to the alley they have just come near instead, guard and all —
so a mark the player can actually walk up to is what makes the silent first encounter fair
rather than a dead end.

## Endings

### Bad — Nerves at 0

Whichever day it happens on, the run ends. The parent stops going out. The city continues without
them. Short, flat epilogue text over a static shot of the apartment window.

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
