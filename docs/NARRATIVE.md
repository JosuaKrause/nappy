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

Every morning, as she comes out, a neighbor in work clothes — coveralls, a reflective band, a
work cap — leaves the same building and walks off down the street. Nothing points at them. It is
the neighbor down the hall, and it is every morning until day 10.

On day 3 the fire meets her on her way. It is on whatever street she takes, the engine comes
and parks across from it, and between them the street is shut for the rest of the day, so she
turns round or goes another way. Still read as an accident.

### Act II — "Notices" (days 4–7)

Palette desaturates slightly. Posters go up. Loudspeaker masts are installed on day 5 and
switch on with a test tone. Police patrols appear. On day 6 a curfew is announced and the
day gets shorter.

The burnt building from day 3 is still there, cordoned off, never repaired. Same tile,
every day, for the rest of the run.

**Day 6, the day of the curfew:** the first `resistance_contact` appears in an alley. No prompt,
no quest marker beyond a chalk mark on the wall that the player may or may not notice, and it is
guarded from this first appearance on — see "Risk" below.

### Act III — "Vans" (days 8–11)

Cold palette, overcast. Streets are emptier — literally: from act I's crowd, the streets
keep about a fifth of the people and a quarter of the cars, and the arterial that ran at
three times the idle decay in act I falls below it. The city gets *quieter*. This is the cruellest joke in the design, and it
is now something the player can see rather than only feel: the pavement they walked down on
day 1 shoulder to shoulder is empty. The city gets easier to put a baby to sleep in,
because there is nobody left in it.

Abductions begin. Masked men, unmarked vans. Getting close is a hard fail — you and the
baby are taken, day over, one Nerve gone.

**Day 10 is the raid on her own building.** Once she has left, vans pull up across the street from
her door with a patrol car pacing between them, and that is what she comes home to; the doorstep
stays reachable along her own sidewalk. The neighbor who has left every morning so far is out in
the city, walking home into it. The next morning a door down the hall is sealed, and the neighbor
no longer leaves for work.

### Act IV — "Open" (days 12–14)

Smoke, sirens, barricades. Military convoys re-shape the map as they pass. Protests grow.
Whole districts close.

**Day 14** is the last night — either the sabotage (good ending) or simply the last walk home
(neutral ending). The sabotage is a hand-over at the power station's front door, and she is
walking away from it when the city goes dark: every lit window, every traffic light and every
loudspeaker at once, the masts because they run on the same power. The walk home is under dead
lights, harder than the day before it rather than easier. And it does not end on a screen:
winning day 14 with every task complete goes on the same night to the escape, the building and
then the city, both in the dark, and the run ends when she is out. See `docs/MECHANICS.md`, "The
escape, which is the run's ending".

## The resistance subquest

### Design intent

The subquest must *cost the core resource*. Joining the resistance means deliberately
choosing the worst routes for your baby: alleys, crowds, closed districts, a stranger's
own field. The player trades the thing they have spent the whole game protecting, and every
task is one verb — **get to a guarded place and touch it**, the same day the mark that names it
is touched.

### Structure

A task is one day: she touches the chalk mark, the task is announced there and then, and it is
performed the same day. Every task day starts with a mark. Touching either — the mark or the
task's own contact — is instant: there is no key to hold, and no standing still to pay for. Only
completing the task itself grants **1 resistance progress**; the mark is the note, not the
errand. Reaching `Tuning.RESISTANCE_GOAL` (five) tasks earns the chance at the good ending; the
day-14 sabotage is the act on top of it — see "The finale" below.

The first mark is on the day the curfew is announced, and a task day follows most days after
that through the day before the last night:

| Day | Task | Reached by | Arrow |
| --- | --- | --- | --- |
| 6 | A note for a stranger | Touch whichever `homeless_yeller` she reaches first — several are live at once and look alike, so there is no wrong one to single out first. | any instance |
| 7 | The package | The delivery van's own drop. Picking it up makes the pram heavier for the rest of the day. | red |
| 8 | The burnt shell | Wherever this run's own day-3 fire left its scar. | red |
| 9 | The crossing | One of that day's own region doors, the first day the wall stands at all. | red |
| 10 | Warn the neighbor | The neighbor, out in the city and walking home, by the red arrow that follows them: about `Tuning.NEIGHBOR_WALK_HOME_SECONDS` of their walk from her door when the mark is touched. Reached first, the neighbor runs; reaching the door first, they are taken, and from the next morning the wanted notice crosses their face out. | red, with a deadline |
| 11 | Silence a mast | The foot of one live loudspeaker mast, drawn among those she can reach. Its field makes the approach cost while it broadcasts, so the skill is reaching it between broadcasts; reaching it puts its lamp out, and it stays quiet for the rest of the run. | red |
| 12 | The swing | The playground of one specific park. | red |
| 13 | Into a roadblock's band | Any roadblock's own poured-concrete closure — not a region door's hut — rather than round it. | any instance |
| 14 | The last night | The power station's front door, offered only once the goal is met. Touching it is the sabotage. | red |

**Two kinds of task.** One any live instance of the right thing answers — the man shouting, a
roadblock — and gets no arrow: approaching any of them is still the cost, and whichever one she
reaches is the right one. The rest are one place, and get the red arrow, `HomeArrow`'s own form
in a color of its own (`Palette.TASK_ARROW`) — a decided exception to *no quest log or marker for
the resistance*, narrowed to a task with exactly one place to be.

### Risk

- **Every mark is guarded**, from the day the first one can appear. A robber waits somewhere
  between 66px and 176px of it — inside that band touching the mark is death, always; above
  it he never wakes at all; between them, which side the player approaches from decides whether he
  notices them. Seeded from the run and the day, so the distance that was safe on day 9 of
  this run is safe on day 9 every time you replay it — the pattern is learnable, which is
  the difference between risk and a coin flip.
- **The any-instance contact is whichever look-alike the player hands the note to.** It does
  not wait at the one instance the day happened to seed; it rides onto whichever live
  look-alike — a `homeless_yeller` or a `roadblock` — the player is within reach of, and follows
  them from one to the next until they touch one. There is no exhaustive check to run and no
  wrong candidate to cost the player anything: approaching the field of any of them is still the
  cost, but any one they have noticed and walk up to is the right one. *(2026-09-13: "the task is
  always solved by going to any yeller she notices.")*
- **Only a day the player wins counts.** *"a task is only complete if it is done on the day that won"* —
  a mark touched, the task it unlocked, a contact lost to its deadline, a package picked up or the
  last night's sabotage are all given back when the day is lost, and the retry starts at the mark
  again. So the errand is never spent on an attempt that failed, and a task cannot be lost to a
  day that did not happen; the price of a bad day is the nerve, not the subquest. See
  `GameState.finish_day()`.

### The finale

Reaching `RESISTANCE_GOAL` earns the *chance* at the good ending; the day-14 sabotage is
the act. `GameState.earned_good_ending()` requires both, so a player who does all the
legwork and then walks straight home on the last night gets the neutral ending — and the same
pair is what sends a won day 14 on to the escape rather than to an ending screen, so the good
ending is the one ending nobody is simply told about.

### Feedback

There is no quest log and no marker beyond the red arrow's own narrow exception above. In the
world a mark is a chalk mark on an alley wall, drawn *under* everything that stands on it, found
by walking past it. **The task is announced at the mark and nowhere else**: the instant she
touches it, its own words flash where the walking and running lessons do, and then the HUD
carries one terse line, *somewhere out there* and what she is looking for, for as long as the
task stands. How far in she is belongs between days rather than during one, on the day summary's
own tally. **That HUD line is silent until the first mark has ever been touched**, and only later
ones are named. The day brief is a separate channel and says less, not more: its own line for the
first task day names the rumor of chalk messages in alleys and nothing else — no place, no
pointer to one — and every other day's line is one or two sentences about what is true of the
city that morning, the same words whichever way the day before it went.

**A finished task is shown by the world and never by text.** A touched mark changes to its own
touched picture, which is all a mark needs; nothing is written on the HUD, and there is no
counter, no objective marker and no log. The note for a stranger answers the same way: the
moment she hands it to him, the man she reached stops shouting and walks away, on foot, until he
is out of sight — the same departure any finished event takes, not a word on screen. The
look-alikes she never reached carry on shouting exactly as before.

A chalk mark the player has not actually noticed — stood near, on screen, long enough that
walking past it rather than to it was a choice — has never really been placed, so it follows
the player rather than sitting where the dawn plan first put it: once they are far enough from it
to have missed it, it moves to the alley they have just come near instead, guard and all, skipping
an alley an earlier task's mark already used while another is in reach — so a mark the player can
actually walk up to is what makes the silent first encounter fair rather than a dead end.

## What the tasks are for — never said in the game

A resistance group is forming and recruiting like-minded people by chalk, because nothing spoken
or sent is safe. **It wants her because the neighbor down the hall works at the power station**:
the group cannot approach a watched worker, and a parent in the same building who is out every
day with a stroller can. Everything leads to one night: the city's power is cut, the blackout is
the signal the uprising waits for, since it reaches everybody at once with nothing spoken or
sent, the regime answers the uprising by bombing its own city, and the escape is her getting out
from under it.

Four things hold across every task. **It is the same story for the mother and the father** — no
task rests on which parent she is. **Nothing in the stroller is dangerous to lie next to** (tone
rule 2, above: the baby is never in narrative danger from the regime directly); what she carries
is damning to be caught with and harmless beside the baby. **She is never told the plan**: each
errand is small and deniable, and she learns what they were for only when the windows go dark.
And **nothing before the last night rests on her alone**: the group has other couriers, and a
task she skips is answered by somebody else, which is why she can miss some and it is still
enough — see `Tuning.RESISTANCE_GOAL`. **That number is the group's trust**: only a courier who
has proven reliable is given the key, which is why the last night is offered only at the goal.
The last night has to be her, because under curfew with the army on the streets only a parent
out walking a baby who won't settle reaches that door. **Her cover is never a crying baby**:
crying is a lost day.

The tasks escalate: trust, carry, carry back, scout, protect, rehearse, retrieve, scout again,
act.

| Task | What it accomplishes | If she skips it |
| --- | --- | --- |
| The note for the man shouting | He is the group's lookout: everybody walks around him, so he sees everything and nobody sees him. The note is her answer, yes; walking up to noise with the baby is the test. He leaves because his corner has done its job. Whichever look-alike she reaches is him — which one exactly is decided by how she plays. | Somebody else answers. |
| The package at the van's drop | From the group to the neighbor. The driver is a sympathizer; the package is tools and a lamp. She carries it home, which is where the neighbor lives. | Somebody else risks the building. |
| The burnt shell | From the neighbor to the group: a drawing of the station, which door and which shift. A cordoned ruin is where nobody goes, so it is the dead drop. Whether the fire was an accident is never answered. | The drawing goes out another way. |
| Cross a named door | The districts closed that morning and the station is across one. She finds out whether a stroller gets through. | Somebody else finds out. |
| Warn the neighbor before the raid | The regime has found the worker. She reaches the neighbor out in the city before they walk home into the vans, which are at her own building when she gets back. Warned, the neighbor runs; not warned, the neighbor is taken, and theirs is the face crossed out on the wanted notice. The door is sealed the next morning either way, and the drawing already left at the burnt shell. | The same sealed door, for the worse reason. |
| Silence a mast | The rehearsal: a mast's feed can be cut by hand, nobody comes, and the masts have no power of their own, so a blackout silences them. | Somebody else answers. |
| The swing | Feeling watched, the neighbor hid the station key at the swing before the raid, so it is there whether or not she warned them. The parks are being fenced one at a time and the group knows this one is next, which is why it is today; she gets the key out as the park is taken. | Another courier fetches it. |
| Into a roadblock's band | The army arrived that morning. She finds out how close a parent with a baby who won't settle can come to a held street before its guard moves, because the last night's way passes one; nobody looks twice at a parent walking a baby who won't settle, so the cost of the task is its cover, and the guard's reach is still the guard's reach. | Somebody else answers. |
| The station's front door | A hand-over: she passes the key to the neighbor's colleague on the night shift and walks away. The minutes he needs are why the lights go out once she is at a distance. Blackout, uprising, bombing, escape. | The neutral ending. |

## Endings

### Bad — Nerves at 0

Whichever day it happens on, the run ends. The parent stops going out. The city continues without
them. Short, flat epilogue text over a static shot of the apartment window.

### Neutral — survive 14 days, resistance incomplete

The baby sleeps. On the last night nothing happens: the group gave its key to nobody it
trusted, the uprising waits, and she goes home. The city is quiet now, in the way an occupied
city is quiet. Epilogue over
the same daily walk route, now empty of everything the player learned to avoid.

### Good — resistance complete + day 14 sabotage

She hands the key over at the station's door and walks away, and nothing happens. Then, once the
station is out of sight, the city goes dark around her in one frame: every lit window, every
traffic light, the station's own hall. The loudspeakers cut out mid-sentence — the first real
silence in the run, and it is mechanical rather than described: the masts have no power of their
own, so the blackout stops every one of them at once (`Blackout`, through
`EventManager.silence_all_masts()`), and no mast anywhere in the city is speaking for the first
time since they went up on day 5.

It is also the only moment the HUD says anything out loud — one line, for seven seconds,
where the "not settling" hint normally sits.

**Nothing after it is easy.** *([PLAYTEST-121](playtests/PLAYTEST-121.md): "the escape shouldn't
be easy!")* The walk home is under dead traffic lights, across a main road that no longer stops
for anybody; the blackout is the uprising's signal and the regime answers it by bombing its own
city; and the escape — out of her building, then out of the city — is walked in the dark. The
silence is the one thing the blackout gives her. What the good ending earns is a way out, not an
easy one.

## Tone rules for writing content

1. Never have a character explain the politics. The player infers.
2. The baby is never in narrative danger from the regime directly — the danger is always
   *noise*. Keep the horror ambient.
3. No triumphalism in the good ending. What it earns is a silence and a way out — never a
   victory, and never an easy walk.
