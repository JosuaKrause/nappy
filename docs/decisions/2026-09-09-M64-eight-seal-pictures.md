## M64 — Eight seal pictures · built 2026-09-09

The last open item of M64: seven pictures appended to `SealPlanner`'s candidate list, so that with
the existing `barricade_seal` a day's seals come in eight kinds and no single barrier is the
city's signature. Built by an agent on `feature/eight-seal-pictures` from the entry below; the
placement code did not change, which was the entry's own requirement.

| candidate | row(s) | strength | `obstructs_radius` | picture |
|---|---|---|---|---|
| `fallen_tree_seal` | `fallen_tree` | hard | 96 | `fallen_tree.svg` and a pre-rotated `fallen_tree_vertical.svg` |
| `car_accident_seal` | `car_accident` | hard | 96 | `car_accident.svg` and `car_accident_vertical.svg` |
| `burst_main_seal` | `burst_water_main` | hard | 96 | `burst_water_main.svg` and `burst_water_main_vertical.svg` |
| `skip_scaffolding_pair` | `skip` at the kerb, `scaffolding` over the band | soft | 22 / 32 | `skip.svg`, `scaffolding.svg` |
| `moving_van_pair` | `moving_van` twice | soft | 28 | `moving_van.svg` — drawn first as a box with one wheel and no cab, and named the removal lorry; redrawn on the player's word as a lorry with a cab, three wheels, open doors and the ramp down, and renamed because *"moving van is more clear"* |
| `burnt_out_car_seal` | `burnt_out_car` | hard | 24 | `burnt_out_car.svg` |
| `collapsed_frontage_seal` | `collapsed_frontage` | hard | 96, drawn as a repeated debris segment | `collapsed_frontage.svg` |
| `barricade_seal` | `barricade` | hard | 62 | already there: "a stacked barricade" is the existing candidate, confirmed rather than duplicated |

Every row is `SCRIPTED` with `scripted_day` 0 and `intensity` 0 — *"static blockages in general
shouldn't increase excitement"* — with `barricade`'s own radii and telegraph copied so `validate()`
passes at intensity 0, and `act_tag` deciding the first day a seal may use it: 1 for the five act I
pictures, 2 for the burnt-out car and the collapsed frontage, which `SealPlanner._effective_first_
day` reads as day 4.

**Choices made where the entry was silent, each open to overturn.**

- *"Reuses `Look.LORRY`"* and *"the `RUBBLE` texture `_draw_spread` already uses"* were read as
  reusing the silhouette family and drawing approach, not the enum value or the file:
  `tests/test_events.gd` forbids two rows sharing a look or a picture, and `reversing_lorry` and
  `burnt_shell` own those. Each got its own look and SVG at the same scale and style.
- *"A skip and scaffolding"* is two rows, one per pavement, rather than one row placed twice — the
  skip kerb-pinned like `delivery_van`, the boards filling the band like `construction`.
- The tree, the accident and the burst main are one continuous scene at `obstructs_radius` 96,
  exactly half the 192px street, so `_hard_positions` places one body; the burnt-out car keeps
  vehicle scale and is placed four across, a pile-up. `tests/test_seals.gd` pins both shapes and
  checks every hard candidate covers the street edge to edge with no gap.
- `assets/closures/fallen_tree.svg` and `crashed_car.svg` were not reused: the closure marker draws
  a fixed-size cause beside fence panels in a different pipeline and at a scale too small to span
  a street.

**The review found one defect and it was fixed on the branch.** `_draw_spread` never rotates a
texture's pixels; on a vertical spread it only swaps which of the texture's dimensions is "along".
For the three 200×50 scenes that meant an east–west street drew `ceil(192/50)` = four squashed
copies stacked across it. The fix is a pre-rotated 50×200 sibling SVG per scene, chosen by
`EventInstance._wide_scene_texture()` from `_spread_vertical`, with a test in `tests/test_events.gd`
that the vertical case resolves the rotated asset and comes out to one body on either axis. A
runtime `draw_set_transform` was rejected because the instance's `_draw()` is re-run for the halo
and the shadow and the state restore would have to be right against all of it, and a second file
can be opened and judged on its own.

**Evidence**, `docs/evidence/`: `shot-2026-09-09-seed4242-d29eec6-seal-skip.png` (the skip at the
kerb, day 1), `shot-2026-09-09-seed4242-d29eec6-seal-burnt-out-car.png` (the four charred bodies
across a street, day 5) and `shot-2026-09-09-seed4000-1e3995b-seal-car-accident-east-west.png`
(the rotated accident on an east–west street). Gate: `./tools/check.sh`, `./tools/test.sh seals
events`, `./tools/lint.sh`.

**Two things the player found on the branch the same day, playtest 50, fixed there.** The three
rotated scenes and the older `assets/tiles/fence.svg` were not well-formed XML — a `--` inside a
comment — so Godot drew them and GitHub refused to render them; the comments are fixed and
`tools/lint.sh` now parses every tracked SVG with python3, reporting a missing python3 as a hit
rather than skipping. And the accident's onlookers were a circle and a rectangle drawn small —
*"the people should look like people in the game"* — and are now `person.svg`'s own figure at its
own size in both accident files, upright in the rotated one because a person always stands
upright; `docs/evidence/shot-2026-09-09-seed4242-150985c-seal-car-accident-onlookers.png` is the
capture.

**What the review noticed and left for a played verdict.** At 24px the burnt-out car reads in the
capture as a black oval more than as a car; whether the eight kinds read as a city with reasons
rather than as one barrier row repeated is the question only a walked day answers, and none has
been walked. And `--spawn event:<id>` in `main.gd` offsets the rig along local X whatever the
street's orientation, so on an east–west street it stands her in the carriageway and the day can
end before the frame is taken — filed in `TODO.md` under M100.

### The entry as it stood when the pictures were drawn

**All that remains here is eight drawings.** The sealing itself is built and its record is in
`DECISIONS.md` under M64; the off-screen arrivals item this milestone also carried became M77 and is
built, recorded there too.

**Its open question is a played one** — whether a walled city reads as a route decision or as a
maze. Everything below is the reasoning the pictures are drawn against.

> "there is almost never anything when leaving a path. all events are on the path (restaurant
> yeller etc are all *for* the path they force you to switch street sides) but there is *nothing*
> off the path. we need more things for indicating the path (most events we have are for on the
> path) so we need to come up with more things first then actually add them"

> "also, there is no punishment for staying in the path"

**This is M50's gradient working as built and being the wrong shape.** The corridor is the cheapest
ground on every day by design, and the catalogue that fills it is a catalogue of *obstacles* — a
yeller, a café, a market stall, a reversing lorry — each of which is a reason to **cross the
street**, never a reason not to go somewhere. So the city can say *this way is expensive* and cannot
say *not this way at all*, and the route decision the whole game is built on has one correct answer
every day.

**Off the path is closed, not dear, and that overturns M50's central idea.** *(2026-09-02: "maybe
let's not make it a gradient but instead always have it fully closed everywhere off the path just
not necessarily with a full road closure like a tree or car accident.")* M50 makes the corridor the
*cheapest* ground with everything else merely dearer; under this the corridor is the *only way
through*, and **what varies is the picture rather than the price** — a fallen tree, a car accident,
a skip, not one barrier row repeated.

**The placement comes first and the pictures are independent of it.** *(2026-09-03: "how's that 8
seal pictures gonna solve the issue? the task can be solved right now — having more pictures makes it
nicer with variety but it's independent from actually placing things".)* This reverses the order this
entry carried, and the reversal is the player's own — the earlier instruction was *"we need to come
up with more things first then actually add them"* (2026-09-02), given before the pair mechanism was
worked out.

**The catalogue can seal a street today, from day 1, with nothing new drawn.** A soft seal is one
ordinary obstacle on each pavement, and the rows are already there: `construction` (Roadworks) has
`obstructs_radius` of `SIDEWALK_SPREAD_MAX` — 32px, so 64px wide, exactly a pavement band — from day
2, and `cafe_tables` (48px), `market_stall` (56px), `delivery_van` (pinned at the kerb) and
`homeless_yeller` are all available from day 1. For a hard seal, `barricade` obstructs 62px — 124px,
the whole street — and this entry already says it should be *"placed as a seal rather than rolled as
an event"*. So *empty off the path* is fixable now, and what the eight pictures buy is that no single
barrier becomes the city's signature.

**The city becomes a maze rather than a weighted grid**, and the route decision changes with it:
not *which way is cheaper* but *which of the open ways do I take*. That only remains a decision if
what stays open is the day's **route tree** rather than a single line, which is what
`RouteTree.for_day()` already grows — several strands, with the redundancy guarantee counted as a
max flow. So the policy is: the tree is open, everything off it is closed.

**Two of its three preconditions are built, and each was a precondition for a different reason. The
third is the first item below and is not.**

- **M69 put the tree on cells.** A tree made of whole block sides would have put every park crossing
  and every alley in the city off the tree, so *closed everywhere off the path* would have sealed the
  shortcuts the city is built around. `RouteTree` now grows on `ReachabilityGrid` cells, so a branch
  can cut a park corner or run down an alley.
- **M48 made a spread face its street.** A seal is a thing lying *across* a street, so its whole
  content is which way it faces, and every barrier in the game used to be drawn east–west whatever
  street it stood on. `EventInstance._spread_is_vertical()` now asks `CityMap.corridor_offset()` of
  both of a tile's coordinates and swaps the layout onto local Y on a north–south street. **It answers
  a street tile only**: a junction, a square, a park and a courtyard all keep the unrotated lay along
  local X, which is worth knowing before ~150 seals a day are placed against it.
- **A corner is refused as a site for anything that lies across a street**, which is where M48's two
  fixes both switched themselves off — a junction belongs to two streets at once and has no single
  direction to be wrong about. That was the third precondition and it is built, along with the second
  barrier defect playtest 22 named: a spread's end caps no longer draw wider than it obstructs. The
  record, with the measured cost and the screenshot that remains unexplained, is in `DECISIONS.md`
  under M64.

**The whole tree stays open, and everything off it is sealed a full block at a time.**
*(2026-09-03, answering the two questions this milestone could not be built without, and corrected
the same day by playtest 21.)* So the difficulty dial is set at its most forgiving end and the
sealing at its most complete: every calm area still worth reaching keeps its branch, both of its
routes where the map allowed a second one — a day plans **about fifteen routes to five to seven
areas** (`MIN_CALM_BLOCKS` 5 to `MAX_CALM_BLOCKS` 7, which the constant's own comment calls
*"places to go"*) — and what is closed is not merely the rim but everything the tree does not touch.
The city's day has 264 lattice streets in it, so this is most of them.

**The unit of sealing is a block, not a street.** *(2026-09-03, playtest 21: "we wanted full blocks
off-path which can be hard or one normal event on both sides of the street".)* An earlier reading of
this entry said *every street off the tree*, which is a street-level unit and leaves a block with one
side on the corridor getting its other three closed one segment at a time. A block-level unit closes
a whole block's worth of frontage, so the off-path city reads as **solid** rather than as a scatter
of blocked segments. Each sealed street is still either strength — hard, or the ordinary-event pair.

**The density on the corridor is already right, and nothing about it changes.** *(2026-09-03, the
design restated in full: "on the path there should be a normal amount of events that remain passable
— that looks like it is the case here. off the path there should be fully blocking events on every
segment — there should be no (easy) way to go off the path".)* The first clause is a **verdict on
what is built**, given after the measurement below: the corridor's event load is normal, the rows on
it stay passable, and the milestone touches none of it. `EventScheduler._copies_of` keeps offering a
friction row `EVENT_CORRIDOR_WEIGHT` (4) extra copies of a corridor tile, and `Corridor.depth()`
keeps pricing what it prices.

**So M64 is one change, not two: everything it does is off the path.** An earlier reading of this
entry had the corridor's discount as *"the other half of superseding M50"* and queued a second item
to remove it. That item is gone — it was aimed at a cause the measurement could not find, and the
design says the on-path half is already as it should be.

**What *"no (easy) way"* rules in and out.** Not *no way*: a soft seal takes both pavements and
leaves the carriageway to be risked, and an alley stays open at 3.0 excitement a second. Those are
the priced ways through and they are the point. What has to stop existing is the **free** way — an
off-path segment she can simply walk down, which today is most of them.

**Which park to walk to therefore stays exactly as open a question as it is today**, and what
changes is that the answer can no longer be reached any old way. That is the deliberate order: the
policy is the change being measured, and the strand count is a dial to turn afterwards if the whole
tree turns out to be too generous.

**Three consequences of *every street off the tree*, and each is load-bearing rather than a detail:**

- **The doorstep is exempt, and the join to the corridor is on the tree.** The home street is
  deliberately not coloured by any branch — *"a door is not a route"* — so a rule stated as *seal
  every street off the tree* would seal her in on the first frame, which is `CLAUDE.md`'s doorstep
  exemption arriving in a new place. `RouteTree._grow_the_trunk()` closes it: a BFS from the home
  street outward to the nearest cell already on the tree, so `is_on_the_tree()` is true of the join
  and the sealing's own rule covers it without an extra exemption.
- **The seals are their own placement pass with their own budget.** ~150–200 sealed streets is two
  bodies each, which is an order of magnitude past the day's event budget, and that budget exists to
  decide *variety*, not to price the city's walls. A seal is a fact about where she may walk, so it
  is planned where the day's closures are planned — beside `ClosurePlanner` — and counted separately
  from the catalogue's density. **Chosen where the design was silent, and cheap to overturn:** the
  alternative is seals drawn from the ordinary event budget, which would leave a day with either no
  walls or no events.
- **The winnability check stops being the guarantee and becomes an assertion.**
  `EventScheduler._ensure_the_city_is_still_walkable` drops the widest blocker until a park is
  reachable again; against seals placed *by construction* off a tree that is walkable by
  construction, there is nothing to repair and dropping one would open a hole in a wall. The
  guarantee moves to the placement — this is the project's own rule that closures are checked before
  they are accepted, never repaired afterwards — and the check becomes what proves it.

**Two things it collides with, neither fatal:**

- **M45's trap, restated at full strength.** *A nudge that removes the decision is worse than a
  closure that does nothing.* Sealing everything off the tree is the largest possible nudge. The
  answer taken is that the tree is left at full width so the decision survives inside it, which
  makes **the tree's own strand count the difficulty dial** — turned only once this has been walked.
- **A fixed city is knowledge you earn.** The lattice does not move, so what a player learns still
  pays; what changes daily is which ways through are open. Worth checking that it still *feels* like
  earned knowledge rather than a new maze each morning.

**Two obstacles facing each other are already a closure, and that is the cheap way to build this.**
*(2026-09-02: "placing an obstacle that would force you to switch sides on both sides (eg restaurant
on one side and yeller on the other) is effectively a full closure and can be used to demarkate
paths.")* Every obstacle in the catalogue is *walk around it at a price*, and the price is paid by
crossing to the other side — so **two of them, one per side, leave no line to walk**. No new row is
needed for the mechanism; the catalogue already contains the wall, split in half and never yet
placed as one.

**A seal comes in two strengths, and both were asked for.** *(2026-09-03.)* A **hard** seal spans
the street frontage to frontage and nothing gets past it — the fallen tree, the accident, the burst
main. A **soft** seal is the obstacle pair: both pavements taken, and the carriageway still there to
be risked. The distinction is real because of the cross-section — a street is sidewalk 2 tiles, road
2, sidewalk 2, and `Tile.is_walkable()` refuses only `BUILDING`, so the asphalt is walkable ground
with traffic on it. The `construction` row's own docstring is the sentence that names the
consequence: *"since a street is sidewalk|road|sidewalk, the road is always still there, so it costs
time and exposure, never the day."*

**So how closed a street is becomes a variable alongside what it looks like**, which is the answer
to M45's trap in its own terms: a soft seal removes the easy way and leaves a decision — *walk the
carriageway with the cars, or go round* — where a hard seal removes the street. Neither of them may
ever be the only thing between her and every calm area, because the tree is what guarantees that and
the tree is left at full width.

**An alley on the corridor is where this gets interesting, and it is already possible.**
*(2026-09-03: "with the granular reachability can we make alleyways part of paths, too? that might
force some interesting routes".)* It is what M69 built: the tree grows on the reachability grid, so
a branch may *"cut through a park corner or take an alley exactly where the ground allows it"*, and
`Corridor` prices such a cell as depth zero — genuinely on the corridor rather than a shortcut
beside it. M69 also rolled an alley's offset even so that a two-tile alley is exactly one cell wide
and connects end to end, which is what makes a branch able to run down one at all.

**It stays luck, and that was the decision.** *(2026-09-03: "if they already can happen naturally,
that is fine. no changes needed".)* Nothing prefers an alley — the two probes are a loop-erased
random walk and the shortest way home, and neither knows an alley from a pavement, so a one-cell
passage is entered only where the ground happens to lead there. A bias toward alleys, and a
guarantee of one a day, were both offered and both declined: the natural rate is wanted. **So do not
propose weighting the probes again without a reason that is not this one** — what would make it
worth discussing is a played day, not an argument.

**An alley is never mandatory, because an alley is always a toll.** *(2026-09-03: "since alleys are
always a toll lets not make them mandatory".)* Standing in one adds a constant
`EXCITEMENT_FROM_ALLEY` of 3.0 a second, and a cost with no alternative is a tax rather than a
decision — which is the whole verb of this game being taken away on the narrowest ground in the
city. So a day may put an alley on the corridor and may never leave her no way but through it.

**Read as a day-level guarantee, mirroring the one the city already keeps.**
`EventScheduler._ensure_the_city_is_still_walkable` promises that *some* calm is reachable rather
than that every area is, and this is the same sentence one step further in: **a day's open network
always offers a route to at least one usable calm area that uses no alley.** An individual branch
may still run down one — that is the shortcut she may choose to take at a price, which is what an
alley has always been here — and choosing it stays a choice because a park she can reach without one
exists. **Chosen as the smallest form consistent with the existing guarantee and open to overturn:**
the stricter reading is that every alley stretch on the tree has a parallel open way round it, which
constrains the seal placement far harder for a fairness the day-level version already buys.

**And no robber stands in an alley she has to walk down.** *(2026-09-03: "alley robber should not
happen on required alleys".)* `alley_robbery` — placed on `ALLEY` tiles from day 8, lethal inside
30px, with an explicit design note that *"a robbery has no telegraph you could see coming, and it
never did"* — is a risk she is meant to have chosen by entering the alley. On ground she has no way
around, a row whose only warning is the alley itself is unfair by its own description.

**The guarantee above mostly satisfies this one**, since an alley she can avoid is not a required
one. It is written down separately because it is the fallback that holds if the day-level guarantee
is ever loosened, and because it is the cheaper check of the two: **`alley_robbery` is refused on any
alley cell the day's corridor runs down** — an outright exclusion from the candidate pool rather than
a weighting, which is this project's rule that placement is checked before it is accepted and never
repaired afterwards, and the same shape M69 used to refuse a barrier beside a calm area's access
street. **Read conservatively on purpose:** every on-tree alley rather than only the provably
unavoidable ones, since the corridor touches few alleys and proving one unavoidable is a question
about the whole day's open network. Open to overturn if it turns out to cost the row too many sites.

**Whether the same exclusion should cover every lethal row rather than only this one is a question
for the build**, not a widening to assume: the instruction named the robber, and `charging_dog` and
the heated rows reach an alley by different paths.

**What alleys are for, then, is going round a wall.** *(2026-09-03: "let's use them as option to
avoid obstacles and as chalk mark carriers".)* This is the job the sealing gives them, and it falls
out of a distinction the seal rule already makes: **a seal is placed on a street, and an alley is
not a street.** An alley is `ALLEY` tiles cut through a block, not a `StreetNetwork` segment, so
*seal every street off the tree* leaves every alley in the city open by construction. That is not an
oversight to close — it is the answer. The off-path city is walled, and the alleys through it are the
doors, priced at 3.0 a second of dread.

**So the day has two kinds of ground she may walk and they read differently**: the corridor, which is
free and goes where the day wants her; and the alleys, which go through the walls and charge her for
it. An obstacle in front of her stops being *walk round the block* and becomes *take the alley or
turn back*, which is a decision on the one verb the game has.

**Which alleys stay open is the detail the instruction is silent on, and the smallest reading is
taken: an alley bypasses an obstacle rather than opening a second city.** An alley kept open is one
that rejoins the corridor — it goes round a wall and puts her back on the path — and alleys leading
away into sealed ground may themselves be sealed at the mouth. **The alternative, named so it is
cheap to pick instead:** every alley in the city stays open, which gives a complete shadow network
through the walled city and a much larger game than the corridor policy describes. Decide it against
a played day rather than in the abstract; the conservative version is the one that keeps M64's
central claim — the corridor is the way through — true.

**The sealing itself is built — `SealPlanner` places one on every real street off the day's tree —
and the record is in `DECISIONS.md` under M64.** Off-path density measured 0.330 events per street
before and **2.173** after, over 8 seeds × days 1, 5, 8, 11 and 14, with the on-tree figure unmoved.
Two facts from that build govern what is left here: **a seal candidate is data** — an id, a strength
and one or two catalogue rows — so the item below costs one appended entry each and no branch in the
placement code; and **hard seals are act IV only today**, because `barricade` is the sole catalogue
row wide enough to span a street. **Whether a walled city reads as a route decision or as a maze is
the played question**, and nobody has walked one.

- [ ] **Eight seal pictures, so that no single barrier becomes the city's signature.** Agreed
      2026-09-03. Five for act I, where a closed street has a municipal reason, and three for acts
      II–IV, where it is the city coming apart. **With every street off the tree sealed, a day places
      about 187 of these** — the lattice's 264 streets less the 76.6 the day's tree covers, measured
      — **and she walks past perhaps twenty-five**, so eight kinds is each one met three or four
      times in a day.

      **This is variety, and it is independent of the item above.** *(2026-09-03: "having more
      pictures makes it nicer with variety but it's independent from actually placing things".)* It
      is finished when the eight are drawn and added to the candidate list, and it should change no
      other code.

      Act I: **a fallen tree**, root plate at one kerb and crown over the far footway (hard); **a car
      accident**, two cars locked together with debris and onlookers on both pavements (hard); **a
      skip and scaffolding**, skip at the kerb and boards over the far footway (soft); **a burst
      water main**, a crater with water across the asphalt and municipal barriers at both kerbs
      (hard — it is the one that explains why the road is out too); **a removal lorry with its ramp
      down** (soft), which reuses `Look.LORRY`, the biggest silhouette in act I.

      Acts II–IV: **a burnt-out car** (hard), which is `Look.BURNT_SHELL`'s charred palette at
      vehicle scale; **a collapsed frontage** (hard), rubble spilled frontage to frontage, and the
      `RUBBLE` texture `_draw_spread` already uses exists; **a stacked barricade** (hard), which is
      the `barricade` row that already exists in act IV — *"whatever was on the street, stacked by
      somebody"* — placed as a seal rather than rolled as an event.

      **The first two are the player's own examples** and the rest were proposed and agreed in the
      same exchange

**Measured over 8 seeds × days 1, 5, 8, 11 and 14. Only the events on the path exist; everything else
is bare — and it is a factor of three and a half.** *(2026-09-03: "if you look at any of those
pictures it's immediately clear only the events on the path currently exist. everything else is
empty", and "they meant literally empty — nothing on the street".)* The unit is **events standing on
a street, per street, per day**, which is the question somebody walking down one is asking:

| band | streets a day | events a day | **per street** |
|---|---|---|---|
| on the tree | 76.6 | 62.8 | **0.82** |
| the rim | 94.1 | 20.9 | **0.22** |
| further out | 93.3 | 22.7 | **0.24** |
| the whole city | 264 | 106.4 | 0.40 |

A street on the day's route carries **0.82 events**; a street off it carries **0.23**, which is one
event every four streets. The corridor is **29% of the lattice** and holds **59% of everything
standing on a street**. `_copies_of` is what does it — a friction row is offered
`EVENT_CORRIDOR_WEIGHT` (4) extra copies of any tile whose corridor depth is zero — and friction is
4489 of 5633 placements, so the furniture is pulled onto the tree and the rest of the city is left
bare.

**And the run log says she was not on the tree.** *(2026-09-03: "maybe what the playtester thought
was the path was indeed something else. that would beg the question why were they able to leave the
path?")* The `path` telemetry line closes each day with the share of her street time spent on the
day's route, and playtest 20's run reads **52%, 29%, 51%, 30%, 20%, 52%, 33%, 36%, 0%, 0%, 59%** — a
mean around a third, and two days on which she never set foot on it. So she spent most of her walking
on 0.23-events-per-street ground. *Empty* is the accurate word for it.

**Neither cause playtest 21 proposed survives, and both were tested.** The rows that force a pavement
change are not priced out of the corridor: `_role_for` calls a row a wall when it is lethal or costs
`WALL_WORTH_OF_COST` (40 points of a 100-point meter) or more to walk through, and `cafe_tables`
costs 20.1, `market_stall` 27.9, `construction` 20.3 and `delivery_van` 8.3 — all friction, each
landing on the corridor about half the time. And M69's closure refusal moves almost nothing: planning
every day twice on the same seeds, with and without the calm-area exclusion, moves **45 of 280
closures** and shifts the share landing on the rim from **86.4% to 88.6%**, at an identical 2.50 a
day. The refusal takes 35 streets a day out of the pool and only 34.7% of them are rim at all.

**So the fix is the sealing, and the sealing has a size: 264 − 76.6 = about 187 segments a day.**

**This makes playtest 19's older finding a measurement rather than an impression** — *going off the
paths lets me skip events and is safer than going on the path.* Off-path is emptier, so off-path is
safer, which is the exact inversion M64 exists to fix. And *why was she able to leave* has a plain
answer: nothing stops her. M50 only makes the corridor **cheapest**, and it buys that cheapness by
putting harmless things on it.

*(`SET_PIECE` is zero in every bucket. A one-shot has no position at dawn, so this is the sweep
looking at plans before the director sites them rather than a day with no set pieces in it.)*

The probe that produced all of this is `tests/probes/m64_density.gd`, run by name with
`tools/test.sh probes/m64_density.gd`, so that *measure it again after* means running the same
thing rather than reinventing it.
