## M50 — The city points somewhere · `feature/the-city-points-somewhere`

**The plan for the diversion design.** The design itself is `docs/CITY.md`, "Diversions — the
design"; this is only *how*. Nothing here is started.

**The one sentence: the corridor already exists in the code and nothing is allowed to see it.**
`ClosurePlanner._streets_on_a_route` computes, today, the set of streets on a near-shortest way
from the door to some calm ground — distances from home, distances to each calm area's access
streets, and a street counts if the best route through it is within `CLOSURE_ROUTE_SLACK` of the
best route overall. **That is a corridor.** It is private, it is thrown away every time it is
computed, it is unioned across all calm areas so the individual paths are lost, and the only thing
it is used for is weighting *which street to close*. So this milestone is much less about inventing
a structure than about **promoting one that is already there** and letting everything place against
it.

And one thing found by reading it, now decided: **closures are currently biased
`CLOSURE_ROUTE_BIAS = 5.0` toward streets that are on a route, and that flips.** *"A road block
becomes guidance and is not a hindrance. It flips its role."* Today a closure is placed where it
will be **met**, which degrades the good ways; under the design it is a **wall**, placed off the
tree to prune the ways that lead nowhere she should go. The purpose changes with it: a closure
used to exist to make a route harder, and now exists to make a route **obvious**.

Two consequences worth having in mind while building, because they run opposite ways. Closures stop
being a threat to winnability almost by construction — a wall sited off the tree cannot cut the
tree — which takes pressure off the two-routes check from the closure side. And the old sanity rule
inverts: *"a closure nobody would have walked is pointless"* was right when a closure was an
obstacle, and is exactly backwards for one that is a signpost.

### Step 0 — the tree, and it is a tree on purpose

**A tree, not a bundle of shortest paths.** *"Don't take the strictly shortest path. Aim for paths
that share prefixes. The paths to some calm zones might not be optimal or short but that is
okay."* This is the instruction that decides the whole structure, and it is why the day's plan was
called a **tree** from the first sentence of the design rather than a set of routes.

`_streets_on_a_route` is exactly the wrong primitive for it: it keeps every street within
`CLOSURE_ROUTE_SLACK` of the **best route to that area**, computed per area and then unioned — which
is the definition of *independent* shortest paths. Run it on a day with five calm areas and you get
five rays fanning out of the doorstep sharing almost nothing, which is a star, and a star has no
bundles, no chokepoints, and a fan-out equal to the number of destinations. Everything the placement
depends on comes from the sharing.

**The construction is probes and colours, grown from the calm areas back toward the door.**
*(The player's algorithm. It replaces a greedy Steiner attachment proposed here first, which was
worse: it needed a global cost function, it made the trunk point at whatever calm happened to be
nearest home on every seed, and it had nothing to say about the second route.)*

- [x] **Two probes at each calm area, walking in random directions.** Not one probe from home —
      the growth runs **backwards**, from every destination toward the doorstep, and the trunk is
      what is left where they have all come together
- [x] **A path carries the colour of its origin**, and both probes from one calm area carry the
      same colour
- [x] **Same colours may not merge.** The two probes from one area can never become one path, so
      where a second route exists at all the area is reached **two genuinely distinct ways**. It is
      an offer rather than a guarantee — see below
- [x] **Different colours merge, and the colours add up.** A probe that touches a differently
      coloured path joins it, and the joined path carries the **union** of both colour sets. Which
      is the elegant half: once the `A`+`B` path exists, `A`'s other probe is locked out of it by
      the rule above, so the guarantee maintains itself as the tree grows and nothing has to police
      it
- [x] **"Touch" means *merge*, not *be near*.** Non-mergeable paths may run **directly adjacent** —
      *"the player can walk the beginning of path A and then switch to path B without noticing"*,
      and that is fine, because both go to the same place. Optionally they can be separated with a
      road block, *"but that is not a hard requirement"*. So the constraint is on the graph, never
      on spacing, and any implementation that enforces a distance between paths has misread it

**The five details, answered:**

1. **A probe stops on either** — reaching the doorstep, or merging. A probe that gets home unmerged
   is a direct route and is finished.
2. **A step is a segment on the `StreetNetwork` junction graph.** Not tiles: a corridor is a set of
   segment keys everywhere else in this design, and tile-walking would produce something no other
   part can consume.
3. **Loop-erased random walk.** Wilson's algorithm — walk randomly, delete loops as they close —
   rather than a drift toward home. It is the standard tool for exactly this shape and it gives
   variety without wandering.
4. **Probes go out sequentially, and the second one is optional.** *"No swapping — if we send out
   the probes sequentially we can check if there is another path left, via a shortest path
   algorithm that avoids path A. Having two distinct paths is really a niceness to the user. If we
   cannot construct a path B at all, let's not try."* So: grow probe 1, then ask whether a route to
   that area exists **avoiding probe 1's segments**. If it does, that is probe 2. If it does not,
   the area has one way in and the day is fine.
5. **Hard blockers are placed against a tree, not before one.** *"First construct an example tree
   from the initial map, then place the hard blockers — that way we can't block off regions
   entirely. Then when a day starts we construct a tree for real."* So generation runs: lay the
   city → grow a **reference tree** → place hard blockers that leave it intact → and only then does
   each day grow its own tree on what is left.

### Dropping the swap removes every hard case at once

The swap was proposed to rescue a probe that could not merge, and it carried three problems: it
could ping-pong with no decreasing quantity so nothing guaranteed termination; it was undefined
against a **merged** path, where re-designating a tail carrying `{A, B, C}` would silently re-route
`B` and `C` and could collapse *their* second routes; and it could not fix a pocket anyway. **All
three are gone** — sequential probes with an existence check have no collision to resolve, so there
is nothing to ping-pong, nothing to re-designate, and a pocket is simply an area with one way in.

**What it costs is a guarantee, and that is a deliberate trade.** *"Having two distinct paths is
really a niceness to the user."* So a second route is an **offer the day makes when the map allows
it**, not a promise. This is the right way round — the alternative was a construction bending
itself to preserve a property nobody had asked to be absolute — but it has to be taken with the
consequence below open-eyed, not discovered later.

**The consequence: winnability loses one of its two protections.** `MIN_CALM_AREAS_WITH_TWO_ROUTES`
existed so that no single closure could cut every route to the calm. Under this design that
protection comes instead from **where a wall is placed** — off the tree, by construction — so the
redundancy is no longer the backstop, the placement is. That is coherent, and it means one bug in
wall placement is now the whole distance between a normal day and an unwinnable one. *(Taken
2026-08-31: the constant is `MIN_CALM_AREAS_REACHABLE` and asks for reachability. The count of
areas deliberately stayed at two — see "The two invariant decisions" below.)*

- [x] **Keep a reachability check as the last line.** `_ensure_the_city_is_still_walkable` /
      `_park_is_reachable` already asks only that *some* calm area is reachable, which is exactly
      the weakened guarantee and costs one BFS. **It was not deleted when
      `MIN_CALM_AREAS_WITH_TWO_ROUTES` went** *(2026-08-31)*, and neither was the closure planner's
      own check — it asks for reachability now instead of for two routes. Two independent
      mechanisms rather than one, cheaply, which is the difference between a placement bug being a
      bad day and being an unwinnable one

**And this makes step 1's gate much weaker, which is a gift.** *(Taken 2026-08-31.)* Hard blockers
no longer have to leave two edge-disjoint routes to every calm area — only **reachability**.
Cul-de-sacs and dead ends were always the point of hard blockers and the old gate fought them; a
`route_count >= 2` requirement would have refused most of the interesting ones.
`CityGenerator._the_calm_survives` uses `route_count >= 1` now, over every calm area rather than
over a count, because a hard blocker holds for the whole run: a day can be bad, a run cannot be
dead.

**Decided: B is the shortest remaining path.** The same computation that answers *does a second
route exist* also is the route — no second walk.

The reason is not simplicity, and it is worth keeping because it points the other way from the
usual instinct: **a shorter B puts less of the map in play.** *"The shortest path also reduces the
overall number of available blocks, which makes the area more approachable — the player feels less
lost."* A wandering B would be more interesting per street and would spread the day's ground over
more of the city, and being spread thin is the thing that reads as *lost*. The tree is a way of
saying *here is where today happens*, and a tight second route says it more clearly than a scenic
one.

**The known risk, recorded rather than designed away: B may run alongside A.** A shortest path
avoiding A's segments is often the next street over. That is **not a correctness problem** — the
design already blesses it explicitly, *"non-mergeable paths can be directly adjacent… the player
can walk the beginning of path A and then switch to path B without noticing"* — so what is at
stake is only whether the pair **reads** as two options or as one thick one. A map question, for
the first day this can be drawn, and the answer if it reads badly is a separating road block, which
the design already offers as optional
- [x] **`RouteTree`, in `src/routes/`.** Built from `map`, the day's closed set and the available
      calm areas. It holds, per calm area, the **branch** that reaches it; over the whole day, the
      **bundles** — edges carried by two or more branches — and the **fan-out**, meaning the
      smallest set of sites touching every route, which is what a set piece needs
- [x] **Leave `_streets_on_a_route` alone for now.** It is not `RouteTree`'s constructor and
      swapping it would change what closures do as a side effect of a refactor. `RouteTree` lands
      beside it; the two converge in step 2, where what a closure is *for* is being decided anyway.
      `StreetNetwork.junction_distances` is the piece that genuinely is shared

**Built, and here is what it came out as.** `src/routes/route_tree.gd` and
`tests/test_route_tree.gd`, measured with a throwaway probe over 32 planned days (8 seeds × days
1, 5, 9, 14) and deleted before committing, per the rule in `CLAUDE.md`:

| | |
|---|---|
| calm areas per day / branches grown | 7.6 / 7.5 |
| areas offered a second route | **241 of 241** that the map allowed one to |
| streets on the tree per day | 68.9, of which **50% carry more than one area** |
| probe 1 length vs the shortest way | **13.2 streets vs 4.4** |
| probe 2 length | 6.6 streets |
| fan-out | 2–6 sites against ~15 routes |

Three things in it are worth carrying, and the first two are corrections to what was written here
before anything was built.

**The fan-out covers *routes*, not branches — and covering branches is the design's own warning
arriving through the back door.** The item above said "touching every branch", which reads as the
obvious meaning of *"make sure all routes touch at least one of them"* and is not it: a branch
counts as covered when **either** of its routes is, and measured that way nine days out of 32 came
back with a **single** street. That street is on route one of every area and route two of none, so
a fire engine placed there is met by a player who takes the first way out of everywhere and missed
entirely by one who takes the second. It is *"the tile she must cross"* — which this design names
as its first draft's mistake — restated as a bug. Covering routes gets the right answer for
nothing, because the two routes of one area share no street by construction, so **no single site
can ever cover both** and the *"at least two places"* arithmetic falls out rather than being
enforced.

**A tail is everything hanging off a stretch, not the stretch that was just walked.** The
same-colour rule is enforced by asking whether a junction's way home already carries this area's
colour, and the first version marked only the junctions the probe had walked. That under-reports
transitively — a junction upstream of a merge keeps a tail that does not mention the colour — so
an area's second probe merged at it and then ran straight back down into the streets its first
probe had spent. **The two routes shared ground while every explicit check in the construction
said they could not.** `RouteTree._resettle_the_tails` recomputes the lot from the doorstep
outwards after each adoption, which is O(the tree) a dozen times a day and is the version whose
correctness can be read off the definition.

**And one measurement is a question rather than a result: probe 1 is three times the shortest
way.** 13.2 streets against 4.4, and the corridor is about a quarter of the lattice. That is not
a bug — *"the paths to some calm zones might not be optimal or short but that is okay"* is
explicit, and detail 3's random walk is what produces the variety the design wants. But detail 3
also claims Wilson's *"gives variety without wandering"*, and on a 12×12 junction graph it
measurably wanders; and the reason given for making probe **B** the shortest — *"reduces the
overall number of available blocks, which makes the area more approachable — the player feels less
lost"* — is an argument that points the same way at probe A. **This is a question for the player
and not a number to quietly bias**, and the map picture below is what it should be asked against.

**Asked, and decided 2026-08-31: leave it.** *"Let's try it like this for now and keep the other
options as potential improvements in the future if playtesting shows issues with the design."* So
the wander ships, and the two answers that were on the table are recorded here rather than
discarded.

**What they are not is pre-approved, and the earlier wording of this paragraph implied they were.**
*(2026-08-31, the player: "I want to make very clear that saying 'I'm feeling lost' is not an
endorsement of those ideas and doesn't count as approval. The most it does is bringing those items
back to discussion.")* It said the thing that would make one of them right is a playtest sentence
about feeling lost — which reads as a **trigger**: hear the sentence, apply the fix. It is not one.
A complaint says the design has a problem; it says nothing about which of these two is the answer,
or whether the answer is either of them. **A parked option comes back as a question, never as a
plan.** The same holds for every other option parked anywhere in this file against a future
sentence:

- **Cap the wander, keep the walk.** Re-roll a probe whose route exceeds some multiple of the
  shortest way. One constant, still deterministic, and detail 3 stays literally true — it is still
  a loop-erased random walk, it is just rejected when it rambles. The first thing to reach for.
- **Bias the walk toward home.** Weight each step by whether it closes the distance. Tighter, and
  it is the *"drift toward home"* detail 3 rules out by name, so it would be an overturn rather
  than a tuning. Only if the tight map turns out to be worth more than the variety.

**And the knob this creates has to be watched, because it cuts against winnability.** Sharing is
what makes placement cheap, and it is also what makes **one closure decide the day** — a trunk that
every branch runs up is a bridge, and cutting it takes all the calm with it. The design already
bounds this: *"you have to account for things to be potentially in one of two places at the very
least, in the ideal case where there are exactly two distinct paths."* So the rule is **maximise
sharing subject to at least two genuinely distinct paths surviving**, and the tree is never allowed
to become a single trunk. That is the same quantity as the invariant decision below, approached
from the other side, and the two should be settled together

### Step 1 — hard blockers exist *(once per run, and it gates everything)*

*"Cul-de-sacs and big buildings don't exist yet — but we need them to implement proper hard
blockers."*

- [x] **A cul-de-sac is an `absent_segment` with a dead end at one end.** The mechanism is already
      built and proven: M21's calm zones absorb the streets between their blocks, `absent_segments`
      is the set of lattice edges this city does not have, and `blocked_segments()` merges it with
      the day's closures. What is new is **choosing** them for a reason rather than as a
      side effect of a zone. Note the M21 rule that comes with it: an absorbed street is still
      *ground* — so a cul-de-sac must be a street that genuinely stops, not a park to walk through
- [x] **A big building is a block whose lot is solid**, removing the streets around it from the
      lattice. This is a `BlockPurpose` and an arc, per the "Add a block purpose" recipe
- [x] **They are placed against a tree, not before one**, in `CityGenerator`, from the city RNG —
      so they hold still for the whole run and are what the player learns. Grow a **reference
      tree** on the finished lattice first, then place blockers that leave it intact, *"that way we
      can't block off regions entirely"*. The gate is **reachability**, for every calm area the run
      will ever use including act IV ones — not two routes, which a cul-de-sac would fail by
      definition. The reference tree is the readable sanity check beside it, not the check itself
- [x] **`CityGenerator.validate()` gains the new condition** and it runs on every seed, like the
      rest. `tests/test_blocks.gd` already asserts the walkable set is identical tile-for-tile
      across every block arc — hard blockers must not move a walkable tile after generation

**Dead ends are built. What they came out as, and the three things worth carrying:**

**The gate stayed the strong one while dead ends were built, and the plan above is why that needed
a decision.** *"The gate is reachability — not two routes, which a cul-de-sac would fail by
definition"* is written just above, and it is a **weakening of a guarantee three other things rest
on**: `MIN_CALM_AREAS_WITH_TWO_ROUTES`, `ClosurePlanner`'s day-level invariant, and
`tests/test_routes.gd`'s *"an open city has two routes to everywhere calm"* all assumed the
generator hands them a city where it holds. Taking that as a **side effect of adding dead ends**
is the exact shape of overturn `CLAUDE.md` has a rule about, so the gate kept demanding two routes
until the invariant itself was restated — which happened on 2026-08-31 and is where the gate moved
with it. And the fear turned out to be unfounded either way: with candidates already off the
reference tree, **99% of them pass either gate**, and a city gets **5.9 dead ends against a rolled
4–8**.

**A dead end is a claim on the lattice paid for on the tiles, and calm ground beside one breaks
it.** Found by building it: `tests/test_routes.gd` failed with *"the way in (5, 11, 0) is a real
street"*, because a dead end had been placed on one of a four-block zone's eight ways in. The
graph said the street was gone; the player walks on tiles, and a street with a park down one side
is one you walk into and step **sideways** out of. It is M21's *"an absorbed street is calm ground,
not a closure"* read backwards, and the fix is a candidate filter: nothing beside calm.

**And `absent_segments` stopped being the zone set, which broke a test's sentence rather than its
assertion.** `tests/test_generator.gd` asserted *"no zone swallowed a stretch of the arterial"*
over every absent segment, which was the same set right up until dead ends joined it.
`CityMap.dead_ends` is the split, and it is worth having for its own sake — the two are absent for
opposite reasons and the telemetry map needs to draw them differently. The general shape is one
this project already has a name for: **an identity standing in for the property.**

**The picture had to be fixed too**, and that is a note about tooling rather than about walls: the
first version left a dead end showing through as ordinary building, which is a dark slab inside a
dark street and is invisible. A hard blocker nobody can find in the one picture built to check
placements might as well not have been placed. It has its own colour now.

**Big buildings are built too, and the interesting part is what they exposed rather than what they
are.** One or two per city: **two neighbouring blocks joined into one mass**, twenty-two tiles
long, with the one street between them built over and every other street around them left alone.
Chosen late and converted rather than assigned with the other purposes, because the choice needs
the reference tree, the tree needs the calm areas and those need the block layouts — by the time it
can be decided the blocks have already been carved. Three things came out of it:

- **The first version took the whole ring, and the player corrected it.** *(2026-08-31: "why do big
  buildings close off four streets each? a big building just connects two blocks… we can add a
  building type with all four roads closed but that's a different building type. but I want one
  that just connects two blocks (closes one road)".)* A block with all four of its streets built
  over is an **island in the lattice** — one roll of the dice removing four streets — where what
  was asked for is a landmark that removes one. The four-sided kind is recorded below as a type of
  its own and is not built.
- **A candidate list is a snapshot; a placement is a change.** The pool was enumerated once and
  the first big building's streets were news to the second one's check, so two of them shared a
  street and drew two buildings on the same tiles. It is re-checked at placement now. The same
  shape as M38's *"two placements in the same frame cannot see each other"*, one scale out.
- **And a density floor failed for a reason that had nothing to do with hard blockers.** Day 1
  planned 93 events against a floor of 96 on two seeds of eight, and the cause was neither lost
  ground nor the walkability cull (which drops nothing): it was
  `EventScheduler._ensure_one_usable_park` **stripping twenty-one events** — the spoilers of every
  calm area she has not used, removed *after* the fill has spent its budget. So the day plans to
  target and then falls short of it, and the budget has never accounted for the strip. `69 → 76`
  per block, agreed with the player, puts a typical day 1 at **121–125 placed — which is the
  stated one-per-block target it had been sitting 12 under** — and the worst seed at 102. It
  lifts days 1–7 and leaves day 14 alone, because day 14 is bound by the catalogue's caps rather
  than by the budget.

**And a defect was found on the way past it that is not M50's to fix.**
`_ensure_one_usable_park` returns early if **any** calm area happens to come out clean — and the
rule written underneath that early return is playtest 14's, *"every calm area she has not used
this act stays clean, not just one of them"*. So the newer, stronger guarantee only fires on days
where the older one already failed, which is a coin flip: on seed 4242 it strips 21 events and on
seed 90210 it strips none. That is the **old rule silently defeating the new one written under
it**, and it is why the density shortfall looked like a hard-blocker problem — a big building
moves enough placements to tip the coin. Worth its own item; see "Open design questions".

- [ ] **A building type that closes all four of its streets.** *(2026-08-31, recorded rather than
      built: "we can add a building type with all four roads closed but that's a different building
      type".)* It is what the first version of the big building accidentally was, and the code for
      it is in this branch's history — a block whose lot is solid with its whole ring taken and the
      four corner junctions kept. What makes it a different type rather than a bigger one is what
      it does to the lattice: a landmark that joins two blocks removes one street and leaves the
      grid around it, and this removes four and makes an island. So it needs its own name, its own
      count, and its own answer to *how many of these can a city take before the corridor has
      nowhere to run* — none of which the two-block one has to answer

### Step 2 — placement by role

- [x] **`EventScheduler.build_day` takes the `RouteTree`.** The phase list stays and gains the tree
      as an input; each placement phase gets a **role** and asks the tree a different question —
      walls for segments just *outside* a corridor, friction for segments *inside* one, set pieces
      for a covering set. Keep `_stream(base, salt)` per phase; a phase whose consumption changes
      needs its own stream, which is M39's rule and this changes several

      **Built, and the role turned out to be a property of the *row* rather than of the phase.**
      The item above says "each placement phase gets a role", and written that way it is wrong in
      the one case that matters: the recurring fill is a single phase and it places both the walls
      and the friction, because what decides which a thing is is whether it ends the day.
      `EventScheduler._role_for` is four lines and no row in the catalogue carries a role field.
      *(The phase salts did not have to move for the same reason — no phase changed how much it
      draws, only which tiles the array it draws from contains.)*

      Four things worth carrying:

      - **The mechanism is the precinct weight, not a new one.** A tile is offered to the roll
        several times over, so the roll, the spacing and the room measurement all keep working
        unchanged and nothing new can refuse a placement. **One thing is a rule and not a weight**
        — a wall is never inside the corridor — and that one is safe to state absolutely only
        because the rest of the city stays available to it.
      - **`Corridor` is the translation, and it had to exist.** `RouteTree` is segment keys and a
        placement is a **tile**, and sixteen rows of the catalogue stand on alley, park, square or
        courtyard ground where `segment_containing` returns null. A classification written over
        segments alone would have made `alley_robbery` unplaceable while the whole suite passed. A
        block interior answers for the four streets around it; a junction for the streets that meet
        at it.
      - **Measured, and the two numbers that had to *not* move did not.** Placed per day is
        identical (111 / 145 / 175 / 201 over six seeds), and so is the count of lethal rows —
        which was the real risk, since a `hard_fail` placement must clear its whole outer radius of
        everything else with no fallback, and refusing it a quarter of the city could have quietly
        stopped placing it. What moved is where: costly rows on the corridor 34% → 64% on day 1,
        lethal rows on the rim 63% → 80% on day 5. Measured 2026-08-31 over six seeds, per day, with
        both weights flattened to 1 and then at 4 — flattened is the honest control, since it leaves
        the *rule* in place and takes only the *preference* away, so what the arrows show is what
        the weighting buys:

        | | day 1 | day 5 | day 9 | day 14 |
        | --- | --- | --- | --- | --- |
        | placed | 111 → 111 | 145 → 145 | 175 → 175 | 201 → 201 |
        | costly rows on the corridor | 34% → **64%** | 39% → **63%** | 33% → **53%** | 31% → **52%** |
        | lethal rows on the rim | — | 63% → **80%** | 40% → **64%** | 31% → **59%** |
        | lethal rows placed | — | 8.8 → 9.0 | 16.7 → 16.7 | 17.0 → 17.0 |

        The share drifting down with the day is the corridor filling up and `EVENT_SPACING_SAME`
        pushing the overflow outward — the spacing rule doing its job rather than the weight
        failing.
      - **And it cost the suite time, which is worth writing down because the first version cost
        twice as much.** Every `build_day` now grows a tree, and `tests/test_events.gd` plans a lot
        of days. The first version also keyed the *whole ground scan* by role, so two passes over
        every sidewalk in the city ran three times a day instead of once — 44s → 88s. The role only
        ever re-weights tiles the scan already accepted, so it is a second pass over a list already
        in memory (`_open_ground_for`), and `Corridor` caches its answer per lattice cell rather
        than allocating an array per tile. 88 → 68s, of which about ten is the new test itself
- [x] **`ClosurePlanner` places closures as walls, off the tree.** `CLOSURE_ROUTE_BIAS` inverts:
      the weight goes to segments that are *not* on a branch, and preferentially to those leading
      away from calm. Keep the `_invariant_holds` check on each candidate — a wall off the tree
      should never fail it, so a failure means the tree and the wall disagree about where she is
      going, which is worth an assertion rather than a silent skip

      **Built, and it was taken first rather than second.** The bullet above it needs the tree
      threaded from `City` into the scheduler, and doing that while closures were still biased
      *onto* the corridor would have left a commit in which friction is aimed at a route that a
      closure is aimed at cutting. The order is one commit's worth of difference and the transient
      is the kind of thing that gets shipped.

      Three things came out of it:

      - **The tree is excluded rather than weighted against, and that is what the rest of the
        milestone rests on.** A wall across the route is not a worse wall, it is the opposite of
        one — so `City.start_day` grows the corridor *before* the closures and every street on it
        is refused, which is what makes it still walkable when the barriers go up. It is also why
        `RouteTree.for_day` stopped taking the day's closures: a tree grown against them would be
        grown against decisions taken by consulting it.
      - **The rim is the unit both halves of step 2 needed**, and it is one method. `RouteTree.rim()`
        is the off-tree streets meeting an on-tree one at a junction, which is exactly *the turning
        she can see from the corridor*. A wall further out is legal and bounds less; a wall in the
        far corner of the map is the scenery the old bias existed to avoid, so the constant
        survived the inversion at the same strength with a different thing to measure against.
      - **The assertion asked for is a test rather than an `assert`.** A failing `assert` aborts a
        headless suite, which in this project prints nothing at all and looks exactly like a hang
        (`CLAUDE.md`). So the planner writes a `plan` line and skips, and `tests/test_routes.gd`
        proves the branch is dead by trying **every** off-corridor street of every day on four
        seeds rather than the one or two a day happens to reach.

      And one defect the first version of the test had, which is the same shape as several already
      in this file: it grew its own tree to check the planner's answer against, and grew it
      **before** `map.repaint(state)`. Which blocks are calm is what a tree grows from, so it was
      comparing against a corridor for yesterday's city — 26 failures that were all the test being
      wrong. A tree is a fact about a *repainted* map, and nothing in the type says so
- [x] **Set pieces get a covering set.** Candidate sites such that every corridor touches at least
      one — *not* a single site on her chosen route. `fire_truck` first, then the resistance
      note's alley. **A bundle is not a guarantee**: two distinct paths means at least two sites,
      and any code that assumes one is wrong

      **Built for the catalogue's one-shots, which is `fire_truck` and nothing else.** The day
      plans the row at **every** site and the placements share a `set_piece_group`; the first one
      to enter the world spends the rest, in `EventManager._stream_in`. That hook is where an
      event becomes real — it is where the scar is recorded and the block moves along its arc — so
      the alternatives have to stop being possible on the same frame rather than when it finishes.

      **The resistance note's alley is not done**, and it is deliberately left: `ResistanceDirector`
      places a contact rather than an event, on its own schedule and with its own expiry, so it is
      a second caller of this idea rather than a second row of the same one. It is written down as
      a to-do below rather than folded in silently.

      What it moved that was not obvious: **three counts came apart that used to be one.**
      `max_per_day` is a cap on *instances*, and the number of offers is not one — so a one-shot is
      exempt from the cap assertion in `tests/test_events.gd` and the real count moved to
      `tests/test_event_manager.gd`, where an instance actually exists. And *"the retry has one
      fewer of a spent one-shot"* became *"none"*, because the whole group goes with it. Both
      tests failed on the first run and both were the test being narrower than the sentence it
      was written from.

      **And a third thing it broke, which took a second commit and is the one worth reading.** With
      the offers spacing the rest of the day around all of them, *"a retried day is the same day"*
      stopped being true — the day after a set piece fires has two to six long routes' worth of
      ground freed rather than one, so the fill lands differently: `leaf_blower` seven to five and
      eight kinds moving, on seed 4242. It surfaced a commit late and by luck, because the calm-area
      fix below changed which city seed 4242 generates; the suite had been green on the old one.

      Two answers were tried and the first was wrong in an instructive way. **Placing the set piece
      after the fill** makes the fill identical by construction — and it cannot find its own sites:
      a fire engine's route is 1920px long and `_room_around` refuses anything within 64px of
      anything, so on a map with 120 events already on it every candidate on every covering site is
      illegal and only the fallback places. The rule that shipped is the other one: **an offer takes
      up no room**, because it is not in the world and only one of the group ever will be. That
      makes the fill *identical* between attempts rather than merely close, which is stronger than
      M39 could promise with a single one-shot — and it is the direction step 3 is going anyway,
      *"budget is not really used up if the player doesn't see it."*

- [~] **Off the corridor is not merely unweighted, it is closed.** *(2026-08-31, and it is the
      player's own sentence: "also make sure that areas that outside the paths should have blocking
      events all over — we don't want the player to step in those areas and it ranges from very
      costly to deadly.")*

      **This is a stronger instruction than what step 2 built, and the difference is the point.**
      What shipped weights walls onto the **rim** — the off-tree streets meeting an on-tree one at a
      junction, *the turning she can see from the corridor* — and leaves everything beyond the rim
      to whatever the fill happens to drop there. Measured, that put lethal rows on the rim 63% →
      80% on day 5, which is a bias. The sentence above is not a bias: **the ground off the paths is
      somewhere she must not go**, and it is priced so, from *very costly* at the edge to *deadly*
      further in.

      Recorded before it is built, with the two things it collides with named rather than resolved,
      because both are invariants somebody would have to move on purpose:

      - **A lethal row has to keep its whole `outer_radius` clear of every other event, with no
        fallback** — M28's rule, and the reason it exists is that the telegraph contract is stated
        per event while the player experiences the sum. "Deadly all over" and "nothing else happens
        inside a lethal event's field" are in direct tension, and the second one is what stops an
        abduction being walked into out of somebody else's field.
      - **The catalogue has few lethal rows and they have caps.** Saturating the off-corridor
        ground is a question about `max_per_day` and about how many silhouettes exist before it is
        a question about placement, which is `CLAUDE.md`'s *"a budget the catalogue cannot spend is
        not density"* arriving at the other end of the map.

      **Both were put to the player and both were answered on 2026-08-31.** The gradient is over
      **distance from the corridor** — *"stray one street and you pay, stray three and you die"* —
      and M28's clearance rule is **exempted off the corridor**, keeping its full strength on the
      ground she is being guided along.

      **Built, and here is what it came out as.** `Corridor.depth()` is the range's axis, a BFS in
      turnings over `RouteTree.depths()`; a **very costly** row is a wall now as well as a lethal
      one, `Tuning.WALL_WORTH_OF_COST`; and `_copies_of` pulls the costly end to the rim and the
      deadly end past it. Measured over five seeds:

      | day | placed | inside | rim | deep | lethal in / rim / deep |
      |---|---:|---:|---:|---:|---|
      | 1 (before) | 113.6 | 69.6 | 21.2 | 22.8 | 0 / 0 / 0 |
      | 1 | 113.6 | 60.0 | 29.2 | 24.4 | 0 / 0 / 0 |
      | 5 | 146.4 | 78.8 | 34.2 | 33.4 | 0 / 2.4 / 6.2 |
      | 9 | 177.6 | 88.8 | 44.8 | 44.0 | 0 / 4.2 / 12.8 |
      | 14 | 202.2 | 103.6 | 48.0 | 50.6 | 0 / 4.8 / 12.2 |

      Three things worth carrying, and the first is a mistake caught by measuring:

      - **The threshold was borrowed and it emptied the routes.** `WALL_WORTH_OF_COST` was
        `MARK_WORTH_A_DETOUR` — 25 points, the line where the game raises a caret — with a good
        argument beside it: the cue and the placement would say one sentence. What it did was make
        **two thirds of every day a wall**, taking day 1's corridor from 69.6 placements to 27.8.
        The player asked for the ground off the paths to be closed; nobody asked for the paths to be
        cleared. The line is set by one row instead: **`dog_walker` costs 36.5 and has to stay
        friction**, because *"the dog walker decision should happen meaningfully"* is the route
        decision this game is made of, so the line goes above it at 40 and the first row past it is
        `loose_dog` at 43.3.
      - **The exemption is the `WALL` role and that is by construction.** A wall is offered zero
        copies of any tile inside the corridor, so a lethal placement carrying the role is off the
        routes or it does not exist. A lethal set piece and a lethal `NONE` keep their clearance,
        and `tests/test_events.gd` splits rather than weakens: it checks the ones that keep it and
        asserts the run actually places some of both, so the exemption cannot become a way of
        asserting nothing.
      - **And the gradient is asserted as a relationship, not as two numbers.** *"It ranges from
        very costly to deadly"* is a claim about which end is further out, so the test is
        `deadly_deep > costly_deep`. Two thresholds would have passed on a day where both bands sat
        at the same depth, which is not a gradient.

      **What is left, and it is a catalogue question rather than a placement one.** *"Blocking
      events all over"* is not true yet: day 1 puts 60 placements on the ~25% of the lattice that is
      corridor and 53.6 on the other 75%, so the routes are still **six times denser** than the
      ground she is meant to avoid. Weights cannot close that — they redistribute, and
      redistributing away from the corridor is the mistake above. Only **16.2 of day 1's 113.6
      placements are walls at all**, because the expensive rows have low `max_per_day`, so this is
      `CLAUDE.md`'s *"a budget the catalogue cannot spend is not density"* arriving at the other end
      of the map. Raising those caps is a real balance change and wants its own measurement; day 1
      also has **no lethal row in the catalogue at all**, so its off-path ground cannot be deadly
      whatever the caps say

- [ ] **The resistance note's alley is a set piece too.** *(Split out of the item above rather
      than left implied.)* `ResistanceDirector` chooses where a chalk mark goes, and it has exactly
      the fire engine's problem — an authored thing placed somewhere she may never walk, with a
      run's good ending resting on it. What makes it a separate item rather than the same one is
      that a contact is not an `EventScheduler.Planned`: it has its own schedule, its own expiry
      and no streaming, so the mutual-exclusion mechanism above does not simply apply to it

### Step 3 — placeholders

**What the budget is for was misread here, and the player corrected it before anything was
built.** *(2026-08-31: "I think you are misunderstanding the role of budget. It is to provide
variety in encounters and make sure to not spam the same event over and over again. The amount of
placeholders is almost one per block sometimes multiple per block.")*

The misreading is worth keeping because it is what the three bullets below were about to be built
from. This side read the budget as a **density cap** — a pot of ground the day is allowed to
occupy — and from there the quote *"budget is not really used up if the player doesn't see it"*
can only mean *charge the pot late so the far side of the city is free*, which is order-dependent,
empties out a day the longer she walks, and contradicts the third bullet. The whole question that
went back to the player was built on that reading, and it was the wrong question.

**The budget is a variety ledger.** The count of *sites* is the density and it is roughly one per
block; the budget, the `max_per_day` caps and the weighted pick decide **what fills them**, so that
what she meets is a city rather than nine dog walkers. Which makes the quote mean something quite
different and quite simple: **variety should be measured over the encounters that happen, not over
the whole map.** Fix all ~121 rows at dawn and the twenty she actually walks past can be nine dog
walkers by chance, with the catalogue's caps perfectly satisfied across a city she never saw.

So a placeholder is a **site with a pool**, not an absence:

- [ ] **A `Planned` carries a pool of interchangeable rows**, chosen at dawn, and resolves to one
      of them when she comes within `EVENT_STREAM_RADIUS` — which is already the "she is about to
      be able to see this" boundary. It keeps a **provisional** `def` from the moment it is
      planned, so the day is fully legal at dawn exactly as it is today: every guarantee, every
      spacing rule and both culls run against a concrete row and none of them has to learn about
      pools. Resolution may only *swap* within the pool
- [ ] **The pool is what is interchangeable at that site**, and it is built from what already
      decides placements: the same **role** (so a wall never resolves to friction and the lethal
      spacing rule cannot be broken after the fact), ground that includes the tile, and the same
      `spawn_mode`. The chosen row is re-checked against the day's room and spacing before it is
      taken, which is the same check the provisional row passed — and the provisional row is the
      fallback, so a resolution can never fail
- [ ] **The caps become caps on what she meets.** Resolution prefers a row she has met least today,
      which is the whole of *"do not spam the same event over and over again"*, and a row already
      at its `max_per_day` **in encounters** is not offered
- [ ] **Resolution draws from the placeholder's own stream** — `_stream(base, salt)` keyed by the
      placeholder's identity, never from a stream shared with the rest of the day. Otherwise where
      she walked moves everything planned after it, which is M39's defect with a longer fuse
- [ ] **The test's sentence has to move with the correction, and this is the half that changes.**
      It read *"resolve every placeholder and require the result to match planning it with the
      player walking a different way"*, and under a variety ledger that is false by design: the
      ledger is consumed by encounters, so two walks legitimately meet different rows. What must be
      identical is **the offer** — the sites, the roles, the pools, the paths — which is the M39
      property and the one `docs/CITY.md` states: *"determinism is a property of the offer, never
      of what she did with it."* So: plan a day, walk it two ways, require the plan identical
      placement for placement and require both walks to respect the caps

### The two invariant decisions, which blocked step 2 — both taken 2026-08-31

**And the first of them should never have been a question.** *"I already clarified that the two
routes guarantee is not a hard rule — is that not in your notes?"* It was: step 0 above says *"a
second route is an offer, not a promise"* and *"what it costs is a guarantee, and that is a
deliberate trade"*, `RouteTree`'s own class comment says it, and `docs/CITY.md` carries the
player's *"having two distinct paths is really a niceness to the user"* and *"sealing off a
section of the map is allowed, and it is the point."* The decision was recorded correctly and
then re-opened from this stale heading, which is a smaller version of the failure `CLAUDE.md`'s
overturn rule is about: **a decision that is written down in one place and contradicted by a
to-do list in another is a decision that will be asked again.**

- [x] **Restate the two-routes guarantee.** Done. `MIN_CALM_AREAS_WITH_TWO_ROUTES` is
      `MIN_CALM_AREAS_REACHABLE`, the day-level check asks for one path rather than two, and the
      generator gate is reachability — which is what M50 step 1 deliberately left alone until
      somebody moved it on purpose.

      Two things were kept rather than swept along with it, because the weakening had to be
      deliberate on both sides. **The count of areas did not move**: two, because one of them may
      be the one the day just spoiled, and one reachable area is the unwinnable day the constant
      has existed to prevent since M16. And **the sentence edge-disjointness was standing in for
      is now asserted directly** — by Menger it meant *no single street is a cut*, so
      `tests/test_routes.gd` says that about the **city** rather than about each area: no one
      street cuts off all the calm. The per-area version is false by construction now, because a
      dead end is allowed to take one of an area's ways in
- [x] **`_ensure_one_usable_park` versus the tree.** Answered from the other end on 2026-08-31 and
      it never needed the tree: the guarantee is stated over **where she has been**, not over where
      today's corridor goes, and it is enforced at placement now rather than by a strip. See the
      closed item under "Open design questions"

### What this does not touch

Presentation, in any form. *"How they are presented is already solved. The issue is that they are
not placed properly."* No new cue, no new silhouette, no change to what a closure is, no change to
`City.total_excitement_at`. If this milestone finds itself drawing something, it has gone wrong.
