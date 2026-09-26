## M56 — The resistance is noticed · `feature/the-city-notices`, partly built

Four of the six items shipped on 2026-09-02, and the fifth — the raid, the half of "other dangers
like this" that needed no drawing — on 2026-09-10. The roadblock's hunting posture, the riot van's
end-on view and the measurement against the nerves are still queued; the design for each is in
`TODO.md`.

### The raid hunts · built 2026-09-10

`night_raid` carries `heat_response = HUNTS`. At `Tuning.HEAT_HUNTS_LEVEL` (3) and above, the
derived copy pursues at 130px/s, notices her within 180px, chases for `PURSUIT_TIME` and is
`hard_fail` inside its 70px; below it the row is what it was — a closed block on day 10 that costs
the meter and nothing more. Population and intensity are unmoved at every level, and
`tests/test_heat.gd` states the raid's hot shape by name at every level beside the generic `HUNTS`
loop, so a change to the raid fails under the raid's name. The player took the draft's
recommendation as it stood on 2026-09-10 — *"let's do the next item"* — the raid now, the roadblock
later.

**The raid gains lethality rather than keeping it, and that is the one way it differs from the
precedent.** `abduction` is `hard_fail` cold and stays so; the cold raid has never been able to end
a day. The draft's phrase *"a `HUNTS` row keeps `hard_fail`"* described the van and not the rung —
what `EventDef.at_heat()` actually does is *set* it — so a non-lethal row on the `HUNTS` rung becomes
lethal at the threshold. The agent's first docs said "keeps `hard_fail` throughout" of both rows and
were corrected before merge; the corrected sentences are in `docs/EVENTS.md` and the row's
docstring.

**The threshold is shared, not minted, and the calendar is why.** Performs fall on days 5, 7, 9, 11
and 13, so on day 10 the most progress anybody can hold is 3: sharing `HEAT_HUNTS_LEVEL` is what
makes the raid hunt only a player who has done every task on time, while a player one task behind
meets the cold raid. A row-specific constant was rejected as breaking that sentence for no reason
the row needs.

**The contract was checked by arithmetic before the agent was sent and by boot after.** Running
opens (168 − 130) × 3.0 = 114px over the chase against a 70px lethal radius; the stand-off is
70 + 130 × 0.6 = 148px, under the 180px trigger, under the 330px field; the 44px body plus her 14
is 58, inside 70, so the body is reachable and `EventDef.validate()` accepts the hot copy. The body
comes down the frame it starts hunting through the generic pursuer rule in
`EventInstance._process` that the abduction already uses. Nothing in `event_instance.gd`,
`event_def.gd` or `tuning.gd` changed.

**Choices open to overturn, made where the design was silent.** The test fetches the row through
`EventCatalogue.by_id` and is a named loop rather than an extension of the generic `HUNTS` test.
The agent also reworded two `docs/EVENTS.md` sentences beyond the one the brief named — the
"briefly less dangerous" paragraph and the pursuer-exemption list — which would otherwise have
undercounted the hunting rows.

**Carried forward rather than fixed, and filed in `TODO.md` under M56:** `Look.RIOT_VAN` is drawn
by `_draw_simple`, a single side view mirrored for west, so a raid van chasing north or south is
drawn side-on, where the unmarked van has an end view for exactly that moment. `docs/EVENTS.md`'s
rule that a vehicle needs two pictures the moment it can face more than one way has the raid as its
counterexample until that view is drawn.

**The roadblock was not built**, by the draft's own recommendation: a band does not chase, and a
hunting roadblock is guards leaving their post — a second posture, and so a drawing. The
`checkpoint_*` rows are never rolled by the scheduler and were never candidates; `police_patrol` is
the `PRESSES` rung and never gains `hard_fail`, on the player's instruction of 2026-09-01.

### The van takes somebody, and then it takes you · built 2026-09-02

Two commits. `HEAT_HUNTS_LEVEL` is **3** of four, on the player's own instruction — *"after the
patrol but still early enough to happen more than just once"* — so the ladder's three steps land in
three separate moments rather than two of them arriving together.

**The victim is the event's own scripted figure and the precedent that matters is what it did not
do.** Nothing in the catalogue has ever acted on the crowd; the van still has not. The take is
drawing and one telemetry entry, it begins the first time she comes inside the van's own 250px
field — the design's sentence was *it only means anything where she can see it happen*, so a van she
never approaches takes nobody — and it refuses to start without enough of the van's remaining life
to finish in, because a take cut short by the van expiring mid-walk reads as a bug rather than as an
abduction.

**The heated shape moves only what the rung is about.** Population and intensity are `PRESSES`'s
axes and `HUNTS` touches neither; the test states that at *every* level rather than only below the
threshold. At and above it the derived copy gains `pursues`, 130px/s (the one speed everything in
this game pursues at), a 180px trigger sitting between its 132px stand-off and its 250px field, and
`Tuning.PURSUIT_TIME` as the chase length in place of the 34s idle. The 4.6s telegraph is unchanged
and that is deliberate: for a pursuer a telegraph buys the *notice of it coming* rather than an
escape distance, and 4.6 is comfortably over the 1.5s floor.

**The body is there exactly while it stands still**, which is the existing rule rather than a new
one. A heated van waiting at the kerb is solid at 22px like any parked vehicle; the frame it stops
waiting, the obstruction is freed, because a moving pursuer with a body is a wall that can pin her
against a building on a two-tile pavement.

**A consequence documented rather than fixed:** a heated van is *briefly less dangerous* than a cold
one. Nothing is lethal while it is only `is_waiting()`, so a van at the kerb can be brushed past for
free until she comes inside its trigger — the same shape `alley_robbery` has always had, now that a
second row carries it.

**The screenshots, and one of the two questions came back weaker than the report claimed.**
The hunting shot in `docs/evidence/` (`shot-2026-09-02-seed2422590514-5fa7bd8-abduction-hunting.png`)
answers the menacing-or-comic question well: the van end-on, closing, with the caret over her at a
zebra — it reads as a thing coming for you rather than as a van at a fast walk. The victim shot
(`shot-2026-09-02-seed2422590514-5fa7bd8-abduction-victim.png`) is the weaker one. It reads as
*a person standing beside a van*, not as a person being taken: the figure is upright and unheld,
and the whole of the
"taken" is carried by it walking in and vanishing over 2.5s, which a still cannot show. Worth a
second look from somebody watching it happen before deciding the posture is enough.

**And the hunting van drives on the footway.** A pursuer steers straight at her over any walkable
tile, so a van chasing her along a pavement is what the mechanic produces. It is what every pursuer
in the game already does and it is the first time the thing doing it is four metres of metal.

**Three choices open to overturn**, made where the design was silent. The walk takes **2.5s** from a
**32px** standing offset — both picked by the implementer, neither derived. The `taken` entry is
written by `EventInstance` itself rather than by `EventManager`, which is a new precedent for who
writes the log: the argument for it is that the scene needs nothing the instance does not already
carry, which is what lets a rig assert it with no map or city behind it. And the four copies of
`130.0` across the pursuing rows were deliberately *not* collapsed into one shared constant, being a
separate change from this one.

**The three forks that were put back to the player, and what each rejected.**

- **Heat is a declarative field on `EventDef` rather than extra days.** Adding
  `resistance_progress` to the day number the scheduler plans against would have reused
  `budget_for(day)` — the linear growth in the event budget — for nothing. Rejected because it also
  moves `first_day`: a player doing well at the optional path would meet act III's vans in act II,
  and the calendar `docs/EVENTS.md` publishes would stop being what the game does. A third option,
  heat raising only how many dangerous rows a day places, was rejected as unable to express "the
  van comes for you" at all.
- **The patrol's escalation moves population, intensity and whether it investigates — not its outer
  radius.** Widening the 185px field is the axis that most obviously changes routing and also the
  one that costs something invisible: `Tuning.required_telegraph_time` is stated over the gap
  between the inner and outer radii, so a wider field silently owes a longer telegraph than the
  1.7s the row ships with.
- **A pursuer is exempt from M28's clearance rule**, rather than the hunting van losing `hard_fail`.
  The alternative kept a rule intact by contradicting the instruction that produced the van.

**Why the heated row is a derived copy rather than a mutation**, which is the load-bearing
implementation choice. Mutating a row in place is fewer lines and breaks the one thing this project
checks on boot: `EventDef.validate()` and `Tuning.validate_pursuit()` run once, over the catalogue,
from data. A def that changed shape mid-run would be validated in the shape it booted in — the
harmless one — and the fairness contract would be stated about a version of the event that no
longer exists. Progress is a bounded integer, so the set of shapes is finite and all of them are
checked.

**What the pursuer exemption turned out to be, which is neither of the two answers expected.** The
clearance rule is `EventScheduler._keeps_its_field_clear`, and it read
`plan.def.hard_fail and plan.role != WALL`. Because `_role_for` routes *any* placed `hard_fail` row
that is not a `ONE_SHOT` to `WALL` before it ever asks whether the row pursues, every lethal pursuer
in the catalogue was **already exempt by accident of that classification** — `charging_dog` because
it is `AHEAD_OF_PLAYER` and never reaches the check at all, `alley_robbery` because `hard_fail`
always routes it to `WALL`. So the answer to "was it already true or did it need fixing" is both: it
held, and it held for a reason nobody had named, and a lethal `SET_PIECE` pursuer would have fallen
straight through it, since kind is checked before `hard_fail` in `_role_for`. The rule is now stated
over `pursues` directly, and `tests/test_events.gd` pins it by forcing a pursuer into a non-`WALL`
role, with a lethal non-pursuing row in the identical forced role as the control.

**Two things the implementing agent chose where the design was silent, and they are open to
overturn.** `is_telegraphing_still()`'s guard was left off the new patrol-while-waiting branch,
because `is_waiting()` implies `not is_telegraphing()` by construction and the check would be dead
code. And `docs/EVENTS.md`'s clearance paragraph had never documented the `WALL` exemption at all —
the agent filled that gap in the same edit rather than adding a third case beside two undocumented
ones, which is slightly more than the brief asked for.

**The finding carried forward rather than fixed**, and it is in `TODO.md`'s small items:
`EventInstance.resume()` restores age and travelled distance but not `_noticed_at`, so a
`pursues_within` row streamed out mid-chase comes back `is_waiting()`, having forgotten it. Shared
with `alley_robbery` since the mechanic was built and never reachable before, because a stationary
pursuer's field never moves far from where the day planted it. `tests/test_heat.gd` pins the actual
behaviour so a fix fails there first.

**Measured, not derived:** a day 9 planned at full heat places more `police_patrol` instances than
the same day cold, from the same seed. Asserted as a relationship rather than as a count, because
the population multiplier raising the cap does not by itself guarantee more of them get rolled
against everything else competing for the budget.
