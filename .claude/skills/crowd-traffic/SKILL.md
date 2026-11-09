---
name: crowd-traffic
description: Rules for the crowd and the traffic — separation, lanes and junction boxes, traffic signals and the green wave, and the fairness contract a lethal carriageway owes. Load this BEFORE touching src/crowd/, Crowd, CrowdAgent, CrowdLanes, TrafficIndex, TrafficSignals, or anything about pedestrians, cars, zebras or lights.
---

# Crowd and traffic

**The rules not to miss:**

- **The traffic fairness contract**: a car is lethal and is not an event, so the painted
  carriageway and a horn long enough to walk its whole width stand in for the telegraph.
- **A crowd car is lethal only in front of it, while it drives**: horn, caret and strike share one box.
- **On the main road the light is the contract**: the side street's green is long enough to cross.
- **Anything else that becomes lethal outside the catalogue needs its own stated contract.**
- **Separation between bodies is positional, never a force**: move them apart.
- **Between the crowd and an event figure only the crowd moves** (plaid-raven #884).
- **Nothing enters a junction box it cannot leave.**
- **A slot a body holds is given back on every way out**, through one function.
- **A rig that steps the crowd calls `Crowd.step()`**, the whole tick, never the agents alone.
- **A number that moves regenerates `docs/COSTS.md` in the same commit** (the **balance** skill).

The detail of one area each is in three reference files beside this one, to be read whole before the
first edit there:

| Before touching | Read |
|---|---|
| how a car or walker is placed, recycled, queued, stopped by a body or barrier, or let through a junction (`TrafficIndex`, `LaneMover`, `LaneStrategy`, `GroundShape`) | `references/lanes-and-junctions.md` |
| `CarTurn`, a turn, a turn-round, anything that reads a car's heading | `references/turns.md` |
| `TrafficSignals`, the cycle, the green wave, the car population | `references/signals.md` |

## Separation between bodies is positional, never a force

A brake, a repulsion, a steering weight — all of them keep a gap that already exists and **none of
them can open one that does not**, so two bodies that start inside each other stay there.

`Crowd._bump()` resolves the player against a pedestrian by moving both;
`Crowd.space_out_the_traffic()` resolves a lane of cars from the front backwards. **If a new pair of
things must not be inside each other, move them apart; do not ask them to want to be apart.**

**Between the crowd and an event figure only the crowd moves** (plaid-raven #884): each
crowd body's proposed step is cleared of, or held short of, the event figures, event cars and
cordon officers at its own step, before its check (`LaneStrategy.give_way_on_the_step()`, through
the map's `SeparationPass`), and nothing an event does reads the crowd. **A move's `radius` is the
circle round the whole body**, which for a vehicle is its length: a car's lane test counts at most
`CarStrategy.FIGURE_WIDEST` of it across the lane, or an event car in the next lane stops the
traffic in this one.

## The traffic fairness contract

A car is lethal and is **not** an event, so `validate_event()` never sees it.
`tests/test_tuning_fairness.gd`'s traffic check is its equivalent and fails the suite. Two things
stand in for the telegraph: the **painted carriageway**, which is permanent and learnable and which
she chooses to step onto, and the **horn**, which must be long enough to walk the whole width of it
with the doubled hard-fail margin.

**The rear half of a crowd car is safe on purpose.** `Crowd._strike()` and
`CrowdExcitement.will_be_lethal()` test only the box from the car's centre forward
(`Tuning.CAR_STRIKE_HALF_LENGTH` long, `Tuning.CAR_STRIKE_HALF_WIDTH` either side), never its whole
body: a car is lethal only in front of it while it drives (minty-hedgehog #433), and one that starts
moving while she walks behind it is driving away from her. Keep the horn, the caret and the strike
on the same box, and do not widen it back to the body.

**The horn can only be as early as the car is watching her, so it gets its own watch.** The crowd's
tick hands the strike and the give-way scan (`LaneMover.pedestrian_ahead`) only the cars within
`Tuning.CAR_ZEBRA_SIGHT` of her — both are about a car that has already noticed her, and neither
needs more — but the horn's own contract needs more warning than that much travel gives a fast car,
so it is checked against a second, wider watch instead: `Crowd.CAR_HORN_SIGHT`, at least
`CAR_SPEED.y × CAR_HORN_TIME` (the fastest car's own warning distance) so the watch is never what
clips a car's horn short of `CAR_HORN_TIME`. `tests/test_tuning_fairness.gd`'s traffic check checks
`CAR_HORN_SIGHT` against the fastest car the same way it checks `CAR_HORN_TIME` against
`Tuning.required_horn_time()`, so **a change to the horn, to `CAR_SPEED`, or to either watch fails
that suite rather than only on the street** if the two stop agreeing. Nothing checks it at boot.

**If anything else ever becomes lethal without being in the catalogue, it needs its own stated
contract in the same place.** A hard fail with no written contract is a bug waiting to be called a
difficulty setting. **The patrol car and the fire engine are in the catalogue and keep this
contract instead of a telegraph** (`EventDef.vehicle`, `EventCarDriving`): each strikes only on the
carriageway, only ahead of its nose, and warns anybody standing in its lane `CAR_HORN_TIME` of its
own travel before the strike, wherever it is created, so the fairness suite's traffic check is its
check too. Where an event car gives way (a zebra she waits at, a red light, never inside a junction
box) is the **events** skill's rule, in its `references/event-cars.md`, which an edit to the car's
code loads.

**The main road replaces the courtesy with a clock, so the clock is the contract.** Traffic on the
spine does not give way at a zebra — what stops it is the light — so the thing standing between her
and a hard fail is the length of the **side street's** green, and `tests/test_tuning_fairness.gd`'s
signals check states it in the same shape: long enough to walk the carriageway with the doubled
margin.

Two things are easy to get backwards. The green that matters is the **other** arm's, because she
crosses the main road while the main road is stopped. And the amber is a **clearance** period rather
than a warning — the crossing arm stays red through it and a car too close to stop is counted as
already in the box — so lengthening it buys her nothing and lengthening the side green buys her
everything.

**A dark light hands the main road back to the side street's contract.** On the last night the
blackout cuts the power (`TrafficSignals.powered`), so `is_signalled()` answers false on the spine
and the box rule negotiates its junctions as it does every other street's — no crowd code knows the
difference, and none should. The spine's traffic still does not give way at a zebra, since that is
the street's kind rather than its light, so the clock is gone and nothing replaces the courtesy:
**what keeps a crossing of the dark spine fair is the painted carriageway and the horn**, and the
horn has to be long enough, at the spine's speed, to walk the spine's whole carriageway with the
doubled margin. The spine's carriageway is `Tuning.carriageway_width()` like every street's and the
horn is seconds of the car's own travel, so the fairness suite's traffic check is the check, and
its signals check says so beside the green it checks.

**The two questions about a light are two functions.** `TrafficSignals.is_signalled()` is the
traffic's question, whether a junction is controlled now, and is false with the power off.
**Anything that asks whether a spine junction has lights standing on it — where to put a head — asks
`has_lights()`, never `is_signalled()`**, or a city built dark draws no heads at all.

## A shared slot has to be given back on every way out, not on the way you were thinking of

A checkpoint hut holds **one walker at a time** (`WalkerDoorHold`), so a walker occupying one that
no longer exists shuts that door to the crowd for the rest of the day — and nothing about it looks
wrong, because the hut is a point on the map and the walker was hidden anyway.

**The way out you will write is the one you are thinking about** — the inspection ending. The ones
that cost a door are the others: a walker **recycled** at the edge of the crowd's field (every
walker eventually, since the field moves with the player and she walks faster than they do), a
walker **turned away** by a barrier while it was still queueing, and the whole crowd being
**cleared** at the end of a day. All four go through one `release`.

**Ask what else ends a body's stay somewhere, and make every answer call the same function.** A
slot handed back in only the expected case is a leak with a picture on it.

## A rig that steps the parts is not running the whole

Several suites walk the crowd by hand — `for agent in crowd.agents(): agent.step(step)` — so that a
minute of traffic does not take a minute. That skips the rest of the tick *around* the agents'
steps: the crowd's own tick, which resolves the queue and rebuilds `TrafficIndex`. `claim()` is
written to outlive one frame and nothing bounds it, so with nothing rebuilding, every recycle stays.

**When a rig drives a subsystem by hand, ask what the engine was doing around it** — and if the
answer is "keeping something bounded", the rig is not slow, it is wrong. `Crowd.step()` is the whole
tick but the player half and is what a rig calls; it and the live tick run the same order, the
traffic and the doors first and the agents' steps last.

## The crowd is one picture on purpose

The whole crowd shares one walker drawing (`art/crowd/walker_*`), because **a crowd is what an
authored event has to stand out from**. This is the deliberate opposite of the one-picture-per-row
rule for the catalogue.
