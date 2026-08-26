# Playtest 02 — findings and plan

Second human playtest, taken after M15. Six findings, recorded verbatim in intent, with
what each one implies and what it costs.

The short version: **the loop is right and the street is empty of consequence.** Five of the
six findings say the same thing from different angles — the walk has to be the dangerous
part, and right now the only thing that costs you anything is the clock. One finding (1)
says the reward at the end of the walk is not legible either.

Two of them change the city lattice, which is why the M16 closure work is parked rather
than finished. See "What this does to M16 and M17" below.

---

## The findings

| # | Finding | Size | Blocked by |
| --- | --- | --- | --- |
| 1 | The difference of a park is barely noticeable. The bars should be way shorter — circling a park for two minutes to fill the meter is too long, the multiplier needs to be higher | **S** | — |
| 2 | Going to and from a park bears no risk. I don't bump into people (that should bump excitement and displace us both); I cannot hit cars (that should be an instant loss) | M | — |
| 3 | Cars should stop at crossings when I am close. There should be things that force me to cross the street: sidewalk restaurants that raise excitement very fast, dog walkers that are a fast loss if I get too close. If I see a dog walker ahead I might have to turn around and cross at the zebra, waiting for a car to stop | **L** | 2 |
| 4 | Cars run through each other. A faster car should slow down, or overtake when the opposite lane is clear. Needs 8-direction driving. An overtake into oncoming traffic should crash, and a crash is an exciting event to clear fast | **L** | — |
| 5 | The calm zones are too small — they should be four blocks combined. Needs T-junctions and L-bends, and cars that can turn | **L** | 4 |
| 6 | Main roads with higher traffic and traffic lights instead of crossings; side roads with the current volume and zebras. A main road is a natural excitement source and it should not be possible to walk along a full block of one — it should be crossed, and crossing it should be a challenge | **L** | 4, 5 |

---

## What the findings actually mean

### 1 is the cheapest change on the list and it re-pitches the whole day

M14 pitched the meters against the *day*: a whole day of street walking reaches 79 of 100,
and a calm stretch fills the meter in 119 s. The second number is the complaint. Two
minutes of standing in a park is not a reward, it is a wait, and at 3.5x the street it is
not even obviously faster than what the player was already doing.

The re-pitch this finding asks for:

| | M14 | proposed |
| --- | --- | --- |
| Ordinary street | 0.24/s — 79 of 100 over a whole day | ~0.16/s — about half a bar over a whole day |
| Calm ground | 3.5x — 119 s to fill | **~12x — under a minute to fill** |
| Excitement decay on calm ground | 1.6x | ~2.2x, so the park reads on *both* bars |

That makes a day comfortably winnable once calm ground is reached, which sounds like it
removes the difficulty — and it does, from the meter. **That is the point, and it is what
findings 2 and 3 are for.** The tension moves out of the meter and into the walk. A day
should be lost on the way to the park, not in it.

The M14 relationship that must survive: **a day stays unwinnable on street gain alone.**
Lowering the street rate strengthens it rather than threatening it, so
`tests/test_meters.gd` keeps its shape and only its margins move.

### 2 + 3 + 4 are one finding: the street has no physics

Today the crowd is a *field*. It contributes excitement by distance and nothing else — you
can walk through a person, through a car, through a queue at a bus stop, and the only thing
that happens is a number moves. That is why the route is not a decision: every pavement is
identical and none of them can hurt you.

What the three findings add, in one sentence each:

- **A body is solid.** Walking into someone bumps them, bumps you, and spikes the baby.
- **A car is lethal.** Stepping into the carriageway in front of one ends the day.
- **The pavement can be blocked.** A café spilling onto the pavement, a dog on a long lead:
  things that make *this side of the street* the wrong side, and send you to the crossing.
- **The crossing is a negotiation.** Cars stop for you when you are close enough — so the
  crossing is the safe way over, and jaywalking is the fast way over.

Together those turn the block into the unit of route planning, which is a much finer grain
than the street closures M16 was going to add. **A player choosing which side of the road to
walk down is making the decision finding 12 asked for, forty times a day instead of twice.**

The one to be careful with is the dog walker as a *fast loss*. An instant loss from a mobile
source on the pavement is exactly the case `Tuning.required_telegraph_time()` doubles the
margin for. A dog that kills at 40 px has to be legible about four seconds out, which is
fine for something that moves slower than walking pace — but the fairness contract is not
optional here, and `validate_event()` checks geometry, not whether the player understood.

### 2's collision bump is the first thing that ever pushed a value at the baby

`docs/ARCHITECTURE.md` and `CLAUDE.md` both carry the same invariant: **excitement is a pure
query.** Events never push; the baby asks the world for the total at its position and the
world sums `contribution_at()` over what is live. That is why events compose by addition and
why an event can be tested without a scene.

A collision bump is a push. Keep the invariant by making the bump a *source* rather than a
write: a contact spawns a very short, very intense, very small source at the point of
contact, and it is summed like everything else. Same for the jolt of a car passing close.
The rule to hold on to is the one in `CLAUDE.md`: **do not add a code path that writes to
`Baby.excitement` from outside.**

### 4 is a prerequisite, not a polish item

Overtaking needs cars to leave their lane; leaving a lane needs a car to be somewhere other
than on a rail; and turning off a corridor needs 8-direction driving. Findings 5 and 6 both
need cars that can turn, because a T-junction and an L-bend are turns by definition.

So 4 comes before 5 and 6 even though it looks like the least urgent of the three.

The crash it produces is free content in the best way: an event the *simulation* authored,
in a place the player can see coming, which then has to be walked away from. It should go
through `EventCatalogue` like everything else so it inherits the telegraph contract.

### 5 + 6 rebuild the lattice

These are the expensive ones and they are the same job:

- **A calm zone is four blocks, not one.** So the streets *inside* a calm zone are not
  built, and the lattice stops being a full grid: the junctions on its edge become
  T-junctions, and its corners become L-bends.
- **Roads come in two kinds.** Main roads carry more traffic and are controlled by lights;
  side roads carry today's volume and are crossed at zebras. A main road is a *barrier*: you
  cross it, you do not walk it. That divides the city into quarters joined at the lights,
  which is a permanent, learnable version of what per-day closures were going to do
  temporarily.

Consequences worth writing down before starting:

- `CityMap`'s whole layout maths is "position within the period tells you which band you are
  in". A lattice with holes in it cannot be derived from a coordinate any more; it needs to
  be *generated* and stored. That is the single biggest change in this plan.
- The generator guarantees in `docs/CITY.md` are stated over a full lattice ("a full lattice
  cannot be disconnected by removing any single corridor"). With holes, route redundancy
  stops being true by construction and has to be checked by search. The M16 WIP already has
  the search — see below.
- "It should not be possible to walk along a full block of a main road" needs a mechanism,
  not just a hostile number. Either the main road has no pavement to walk on, or walking it
  is a hazard the way finding 3's café is. The second reads better and reuses 3's work.

### What this does to M16 and M17

**M16 (route pressure — per-day street closures) is parked, not cancelled.** Its first half
is committed on `feature/route-pressure` as a WIP: `src/routes/street_network.gd`, which
turns the lattice into a graph of junctions and streets and counts *segment-disjoint* routes
from the doorstep to each calm area by unit-capacity max flow.

The split, and why parking it costs little:

- The **lattice enumeration** in that file assumes a full grid. Findings 5 and 6 delete that
  assumption, so it gets rewritten.
- The **graph half** — route counting, the two-routes-to-two-areas invariant, the doorstep
  and doorway exemptions — is exactly what a lattice with T-junctions and L-bends needs, and
  it needs it *more*, because redundancy is no longer true by construction.

So M16 is better built after M21 than before it. **M17 (the route map) stays last**, for the
reason PLAYTEST-01 gave: a planning map is only worth drawing once there is something to
plan around, and after M21 there will be much more of it.

---

## The plan

Numbered after the existing milestones rather than renumbering them, so that "M16" means the
same thing in this document as it does in the commit log. Execution order is the order
below, which is **not** numeric.

**M18 — the park has to be worth it.** Finding 1. Re-pitch the sleepiness rates so calm
ground fills the meter in under a minute and reads as obviously different from the street.
Small, and everything after it is judged against it, so it goes first.

**M19 — bodies on the street.** Findings 2 and 3. Collision for pedestrians and the player,
lethal cars, pavement hazards that force a crossing, cars that stop at zebras. The
collision bump stays a *source*, not a write.

**M20 — traffic that behaves.** Finding 4. Car following and overtaking, 8-direction
driving, and the crash as a catalogue event.

**M21 — the city overhaul.** Findings 5 and 6. Four-block calm zones, a generated lattice
with T-junctions and L-bends, main roads with lights against side roads with zebras.

**M16 — route pressure.** Unparked here, on the new lattice, with the graph half of the WIP
reused and the enumeration half rewritten.

**M17 — the route map.** Last, as before.

### Order rationale

- 1 first because it is one afternoon and it changes how every later playtest feels.
- 2 and 3 before 4, because a car that cannot be hit does not need to avoid other cars yet,
  and because 3 is what makes the pavement a decision.
- 4 before 5 and 6, because a T-junction is a turn and today a car cannot turn.
- 5 and 6 together, because a four-block calm zone and a main-road barrier are the same
  change to the same generator.
- The two parked milestones last, because both read the lattice and the lattice is moving.

### Decisions

1. **The difficulty moves out of the meter and into the walk.** Taken as the reading of
   findings 1–3 together: a day that is comfortably winnable *once you are standing on calm
   ground* is correct, provided getting there and getting home is where the day is lost.
2. **The collision bump is a source, not a write.** Excitement stays a pure query.
3. **A main road is crossed, not walked** — enforced by making walking it hostile, reusing
   finding 3's hazard mechanism, rather than by deleting its pavement.
4. **M16's closures stay planned.** They narrow the choice at city scale; findings 2 and 3
   narrow it at block scale. Both are wanted, in that order.

### Open questions for the next playtest

- Does a day that is winnable in forty seconds of park still feel like a day, or does the
  clock stop mattering? If it does, the answer is a *longer walk* — a calm zone further out
  — rather than a slower meter.
- Is an instant loss the right weight for a dog? It is the same punishment as an abduction,
  which is act III's worst thing.
- With main roads as barriers, is 7x7 blocks still the right city size?
