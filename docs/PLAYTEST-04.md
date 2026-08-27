# Playtest 04 — the world was somewhere else

The fourth human playtest, and the first one after M19 put bodies on the street. One round
only, and the player said so up front: *"I test ran one round but still a lot of improvements
haven't landed yet, so it doesn't carry much information."* Take the findings as a report on
what is in the build, not as a measurement of the design.

**Read [PLAYTEST-03.md](PLAYTEST-03.md) first.** Two of these findings are the ones it left
open, arriving again with the milestone that was supposed to close them already merged.

---

## The seven things

In the order they were said, with what each one turned out to be underneath.

| # | What was said | What it was |
| --- | --- | --- |
| 1 | *"Traffic feels too light — I can just ignore it and cross the street whenever."* | Density, and the density was a whole-city number |
| 2 | *"I still see circles."* | M22, not started |
| 3 | *"Calm areas are still too small, walking around in them still takes too long."* | M21, not started |
| 4 | *"The cat is ineffective since it happens when it spawns."* | Two separate bugs, one of them six milestones old |
| 5 | ***"Don't load everything upfront"*** *— only spawn things in the surrounding few blocks of the player when needed; consistency is not that important, nobody can run after cars anyway to confirm they are still there off screen.* | The architectural finding, and the one that fixes 1 and half of 4 |
| 6 | *"Cars still bump into each other."* | M20, not started |
| 7 | *"The game still doesn't feel like it has any hazards."* | The summary of the other six |

Findings 1, 4, 5 and 6 are **M27**, below, and are done. Findings 2 and 3 are M22 and M21 and
were already queued; nothing here changes what they are, only that they are now the top of the
queue rather than somewhere in it.

---

## The one that reframes the rest

> **Don't load everything upfront** — only load / spawn things in the surrounding few blocks
> of the player when needed; consistency is not that important, nobody can run after cars
> anyway to confirm they are still there off screen.

This reads as a performance note and is not one. The game runs at 120fps with 530 agents; the
frames were never the problem. What it actually says is that **the budget was being spent in
the wrong place**, and once that is seen, four separate complaints turn out to be the same
complaint.

The city is 104×104 tiles. The screen is 40×22 of them — **0.8% of it**. Everything the game
buys with a population number is divided by that: 110 cars over sixteen corridors is a car
every six seconds in your lane, which is exactly *"I can just ignore it and cross the street
whenever."* Thirteen events scattered over forty-nine blocks is playtest 03's day with **zero**
`near` entries — an event with a twenty-second duration, planted across the city at dawn, is
over before the player could have reached it, and the budget bought nothing at all.

And the licence in the second clause is the whole trade. Continuity of a car you cannot see is
**unobservable**, so it is free to give away. Density where somebody is looking is not.

### What the second clause does not license

Two things stay authored across the whole map, and it is worth saying which and why.

- **The day is still planned at dawn, across the whole city.** Every guarantee the game makes
  is stated over a day: one usable park, two distinct routes to two distinct calm areas, a
  one-shot that fires once per run, determinism from a seed. All of those are properties of the
  *plan*. Streaming changes when a plan becomes a node, not when the day decides what it is.
- **The lattice, the block purposes and the closures are unchanged.** Those are the map, and
  the map is the thing the player is supposed to learn.

---

## M27 — the world near you

### The crowd is a field, not a city

The crowd now lives in a 1600×1600 box centred on the player. Agents that leave it are recycled
into a band outside the edge they will come back in through, and the population number in
`Tuning` became a population *of the field*.

Everything below was measured with a throwaway probe over sixty seconds of a real day, seed
4242. It was deleted before this was committed; the numbers are the record.

| | act I (day 1) | act II (day 5) | act III (day 9) | act IV (day 13) |
| --- | --- | --- | --- | --- |
| Agents around her | 246 | 185 | 51 | 88 |
| Arterial excitement /s | 10.1 | 6.7 | 1.7 | 4.0 |
| Arterial safe to jaywalk | **5.5%** of the time | 13% | 73% | 26% |
| Mean wait at the kerb | 5.9s | 5.0s | 1.8s | 3.0s |
| Ordinary street safe to cross | 75% | 78% | 95% | 85% |
| Bumps in a 40s walk, down a lane | 11 | 5 | 0 | 2 |
| Bumps in a 40s walk, holding the line | **1** | 1 | 1 | 0 |

The last two rows are the M19 relationship surviving the new density, and it is the one that
decides whether a crowd is a decision or a toll: walking down the middle of a pavement lane
costs eleven contacts, and holding the midline between two lanes costs one. The crowd is
expensive to be careless in and free to be careful in.

The third row is the answer to finding 1. **The arterial cannot be jaywalked** at act I — there
is a safe gap in it about one time in twenty — and it is crossed at a zebra, where traffic gives
way, and the generator puts one at every junction so nowhere on a street is more than seven
tiles from one. That is the M19 design finally having enough traffic to mean something. Act III
inverts it, as act III inverts everything: the roads are empty, and the city is an easier place
to put a baby to sleep.

### Two numbers moved, and one of them is not what it looks like

`CrowdLanes.ARTERIAL_BUSYNESS` went 5.5 → 5.0, and the reason is a trap worth writing down.
**The weight did not change meaning; its denominator did.** It used to be one street's share of
sixteen corridors and it is now one street's share of the three or four in the box, so the same
number puts half again as much traffic on the arterial. At 5.5 the measured jaywalk window was
**0.6% of the time and a 22-second mean wait**, which is not a hazard, it is a wall.

### Traffic that queues

Finding 6. A car keeps `CAR_HEADWAY_TIME` of clear road in front of it and never closes to less
than `CAR_GAP_MIN`. Over a minute of act I traffic that took two cars sharing a lane from
**5.2 overlapping pairs per frame to zero**.

Three things were learned getting there, none of them from arithmetic:

- **A brake cannot open a gap that does not exist.** Two cars that start inside each other both
  choose zero and stay there forever. The separation had to be *positional*, like the player's
  bump and for the same reason — see the invariant in `CLAUDE.md`.
- **Recycling everybody onto the same pixel is a pile-up generator.** The first version put
  every re-entering agent on the exact edge coordinate. Once cars keep a headway, a pile that
  used to sort itself out by driving through each other becomes a permanent stationary queue
  against the boundary: eight overlapping pairs a frame, on a road nobody could see. They enter
  across a 420px band now.
- **A lane can be over capacity, and then no controller helps.** At the first density the
  arterial wanted 194px of spacing per car and had 118px of lane per car. It jammed solid and
  stayed jammed. The car count is set from what a lane can carry, not from what looks busy.

### The cat, which had two things wrong with it

Finding 4, and the second one had been shipping since M5.

**It was in the wrong place.** A cat was placed on a road tile somewhere in the city at dawn and
ran its two and a half seconds out there, alone. A café spilling across a pavement is a *place*
— knowing it is there changes the route, and walking a street to find out is the game. A cat
bolting is worth nothing as a place: you cannot plan around three seconds, and the player had no
way of ever meeting one. It is the first `AHEAD_OF_PLAYER` event, and `EventDirector` puts it
across her line, `AHEAD_LEAD_DISTANCE` in front of her, while she walks.

**And it had never once been seen to bolt.** `EventInstance` starts a mobile event moving when
the telegraph starts, which is right for a fire engine — its telegraph *is* the approach, and it
has to cover three streets to arrive. It is wrong for a crouch. The cat's route is one street
wide, so at 240px/s **it finished the entire crossing during its own 1.6s telegraph**: it never
reached full intensity, and `CAT_RUNNING` never drew a single frame in six milestones. A green
suite, a passing fairness contract and a screenshot all had nothing to say about it.

### Events wait for her now

Not asked for, and it falls out of the same change. A planned event becomes a node when the
player comes within `EVENT_STREAM_RADIUS` of it and goes away again when she leaves; once it has
run, its plan is spent and walking back past it does not rewind it.

The radius has two floors and the larger wins: half the viewport diagonal (735px), so nothing is
ever *seen* to appear, and the widest field in the catalogue (380px), so an event that streams
in is outside its own outer radius at the moment it becomes visible. That second one is what
makes streaming an event legal at all rather than a way of dropping things on people.

The gameplay consequence is bigger than the frames it saves, and it is playtest 03's finding 1
arriving from the other direction: **an event that waits is an event she meets.**

---

## What is still open

- **Finding 2, the circles.** M22. Standing decision since playtest 02: they are deleted, not
  restyled. The player has now asked twice.
- **Finding 3, the calm areas.** M21, unchanged and unstarted. Four-block calm zones. Playtest
  03 measured the lap at twenty seconds and explained why no balance pass removes it: progress
  requires motion and a calm block is a few tiles across, which is jointly sufficient for a
  circle. It is a generator change, not a number.
- **Finding 7, the hazards.** Findings 1, 4 and 6 were most of what was under it and are done;
  what is left of it is findings 2 and 3, plus M25's *patrols and running that matters*. The
  honest position is that this one cannot be closed by anybody but a player.
- **Nobody has played M27.** The numbers in the table came from a probe, and *"the arterial is
  for crossing"* is still a claim about a player rather than about a rig.
