# Playtest 20

Played on 2026-09-03, on a local build, a full seven-day run of seed 4070543669 at commit `5d342c9`.
The trace is `docs/evidence/run-2026-09-03T002310-seed4070543669-5d342c9.log`, and the fourteen
telemetry maps that came with it — a day map and a dusk map for each of the seven days — are the
`run-2026-09-03T002310-seed4070543669-5d342c9-map-day0*.png` files beside it.

**The wording below is the player's, verbatim.** Everything under a *"What this side reads into
it"* heading is this side's analysis and is kept apart from it on purpose.

**Four findings**, sent together as one message: a reachability gap in how barriers, parks and
alleys interact, the chalk mark's continuing unfindability with a new idea attached, an inconsistent
calm-area spoiling density, and a pursuing dog whose lead time shrinks after the tutorial.

---

## 1. Barriers don't account for how a park or an alley is entered

> "barriers don't take into a account that parks can be entered where normally buildings would be
> making them ineffective. (at the same time a courtyard can be completely sealed off by a barrier
> because it blocks the entrance alley). the same applies to alleys. the reachability checks need to
> take alleys and parks properly into account. it's not enough to reach a block."

Sent with the day 4 dusk map and a pointer to a specific spot on it: *"this route shows a barrier
next to a park where I walked inside the barrier from the park."* The small courtyard block in the
upper-middle of that map, just south of where the walked line bends east, has a red-and-white
barrier drawn directly against it — and the walked line passes it anyway, on the courtyard's own
side, because the barrier sits across the street the block fronts onto rather than across the
opening the player actually used to reach it.

Two shapes of the same gap, opposite in effect: a barrier meant to seal a street off does nothing
if a park sitting behind it can be walked into from a side normally occupied by a building frontage
— the barrier blocks the street but not the park's own opening. And the reverse: a single barrier
across the one alley that is a courtyard's *only* opening seals the whole courtyard, because nothing
currently checks that a courtyard's interior is still reachable once that alley is closed — only
that some block adjacent to the closure is.

**What this side reads into it.** The dusk maps from this run show both halves. On day 1
(`run-2026-09-03T002310-seed4070543669-5d342c9-map-day01-dusk.png`), the walked line does not
follow any street into the small forest block at the top-left of the map — it cuts across the
block's interior directly, entering from a side with no street or alley drawn against it at all. Day
4's dusk map draws the same thing at the big park in the lower half of the city: the walked line
runs as a straight diagonal from the park's own top-left corner to its bottom-right, crossing the
interior rather than following the paths that trace its edges elsewhere in the run — the walkable
area attached to a park block reaches further than the openings a barrier could ever be placed
against.

The other half — a courtyard sealed shut — shows up over the same run's later days. The narrow
forest strip at the top of the map has red barrier markers drawn directly against its one access
point on days 5 through 7
(`run-2026-09-03T002310-seed4070543669-5d342c9-map-day05-dusk.png` through `-day07-dusk.png`), and
the walked line, which had reached that block on days 1, 2, 4 and 6, does not go near it again once
the barrier sits there.

**"It's not enough to reach a block" is the sharper of the two sentences.** `docs/TODO.md`'s M45
already carries `_park_is_reachable`, the check `EventScheduler._ensure_the_city_is_still_walkable`
runs against the whole set of closures at once — but a park or a courtyard is not one tile, and a
check that only asks whether the block is reachable at all can pass while every one of its usable
openings (a park entered from more than one side, an alley that is a courtyard's sole door) is
individually wrong. The player's own two examples are the fix stated as a test: reachability has to
be asked of the interior a park or courtyard actually offers, through however many openings it has,
not of the block as a single reachable-or-not point.

## 2. The chalk mark is still unfindable, and the resistance has its own answer

> "another thing is the chalk is currently unfindable I spent almost a full day searching for it.
> let's make the protesters point into the direction (with their arms or something) of the current
> objectives (not only chalk marks). and make the protesters more common. they're not really an
> obstacle/event anyway so they can be placed independently."

**This confirms `docs/TODO.md`'s M65 as still open** — *"the chalk mark is findable, and silent
until it is found"*, asked for on 2026-09-02 from playtest 19's own report that a mark placed off
screen is never seen. This run adds a harder number to it than the player's own sentence claims: a
chalk mark is rolled and guarded by a nearby robber on every one of the four days it becomes
eligible (`docs/evidence/…5d342c9.log:240`, `:364`, `:546`, `:602` — the `roll chalk mark guarded:
robber Npx away` line, once per day from day 4 on), and the run's own ending line reads *"bad on day
7 — resistance 0/4, sabotage not done"* (`:701`). Not almost a full day unfound — the whole run,
across every day a mark existed, with no way to narrow the search.

**What is new is the second half — a proposed mechanism, not just the complaint about the
symptom.** The `protest` row already exists in the catalogue (`EventDef.Look.PROTEST`, drawn by
`EventInstance` at `src/events/event_instance.gd:91` with the `protester.svg` sprite). The player's
idea is two changes to it: give the protester figures a pointing pose — arms or a similar cue —
aimed at whatever the current objective is, not narrowly the chalk mark, and increase how often
protesters appear. The player's own reasoning for why the second change is safe: *"they're not
really an obstacle/event anyway so they can be placed independently"* — a protester obstructs
nothing and pursues nothing, so raising its density is not the same kind of change as raising the
density of something that costs the meter, and it does not need to compete with the rest of the
catalogue's placement budget the way an obstacle would.

## 3. Spoiling a calm area is not consistently effective

> "the spoilage of a clam area is not always effective I went to the same park 4 times and only the
> last time had a high enough density of events to actually prevent me from using it. the previous
> time I could just walk at the edge of it. and the time before that didn't have any spoilage at all
> even though it was the second visit."

Four visits to one park, in order: no spoiling at all on the second visit, some spoiling but still
walkable along the edge on a later visit, and only the most recent visit dense enough to actually
deny it.

**What this side reads into it.** The log carries the scheduler's own bias roll for this. Two parks
get tracked as *"the park she used yesterday"* across this run: `(1,1)`, biased with three events on
day 2 and three more on day 3, and `(4,8)`, biased with nine events on day 4 and again on days 5 and
6. Both of those are dense every time they are biased — nothing in this run's log shows a biased
park landing at zero or at a walkable-edge density, so the specific run that produced the player's
four-visit report is not the trace attached here; this is the mechanism the complaint is presumably
about, not yet the evidence for it. `docs/PLAYTEST-02.md` records the intended shape: *"the
scheduler biases a spoiling event toward a calm area the player settled in on day N−1"* — a bias
toward, not a guarantee of a minimum density, which is consistent with a roll landing low enough
on some days to leave a walkable edge and high enough on others to deny it outright. Whether that
variance is the bias roll's own spread or something else determining how many events actually land
is open, and wants its own measured run before being designed against.

## 4. A pursuing dog has less lead time after the tutorial

> "for some reason pursuing dogs after the run tutorial have a shorter lead up time making them much
> harder to react to."

**The log measures this directly, on `charging_dog`, across five encounters in this run.** Every
encounter logs a `chase ... came for her` line when the pursuit starts and either a `chase ... gave
up after` line, timed from that start, or a `lost ... lost_hard_fail` line if it ends in a hit.

The day 3 tutorial encounter (`docs/evidence/…5d342c9.log:175-180`) starts its chase at 7.2s and
gives up at 8.7s — 1.5 seconds, matching the four other encounters in this run that end in an
evasion (day 5's two retries and day 7's, at `:428`, `:496` and `:645`, every one of them also *"gave
up after 1.5s"*). The one encounter in this run that killed her, on day 4
(`:385-392`), starts its chase at 16.5s and hits at 17.3s — **0.8 seconds**, roughly half the other
five. A second lethal encounter on a day 5 retry (`:458-464`) shows the same pattern: chase starts at
51.8s, hits at 52.7s — 0.9 seconds. Both lethal encounters also show the dog covering ground faster
once its telegraph is up: the tutorial encounter's telegraph sits at 148px at 7.4s and is still at
128px at 8.5s — 20px closed in 1.1s — where the day 4 encounter's telegraph sits at 150px at 16.7s
and is down to 82px by 17.0s — roughly 70px closed in 0.3s.

**What this side reads into it.** `charging_dog`'s definition in
`src/events/event_catalogue.gd:832-849` is a single row with one `inner_radius` (26.0), one
`outer_radius` (150.0) and no distinction between `first_day == Tuning.RUN_TAUGHT_DAY` and any later
day — so nothing in the row itself sets a shorter lead time after the tutorial, and whatever
produced the gap this run measured is elsewhere, most likely in what the dog is placed against
rather than in the row's own numbers. `docs/TODO.md`'s M43 already has an open item on this row —
*"the tutorial dog is not a tutorial after day 3"*, deciding that a later `charging_dog` should stop
being sited `AHEAD_OF_PLAYER` and become a thing that is merely *somewhere*, like `alley_robbery` —
which is a placement change large enough to explain a shorter effective lead time as a side effect,
if it has already landed partway. Whether it has, and whether that accounts for the whole gap this
run measured, is worth checking against the code before this is designed as a new item rather than
filed under M43's existing one.
