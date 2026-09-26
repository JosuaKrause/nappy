## M45 — A grid with fewer ways through, and closures that point · `feature/closures-that-point`

Not started. Taken as a design instruction in the M43 session, in answer to the measurement in
M43's closure entry above — read that first, because it is what makes this a milestone rather than
a tuning pass.

**The one sentence: a closure was being asked to lengthen a route, and lengthening a route is not
what it is for.** What it is for is *direction* — stopping a player from committing to a way that
cannot win today — and the reason it cannot even do that at the moment is that the city has no
shape to work with: 8 streets of 768 could lengthen the walk if closed alone, 11 of 534 four-street
runs, because a Manhattan lattice has many equal-length staircases and there are 8.9 calm areas
scattered across it.

The design, as given:

> *"In the beginning the player has a lot of freedom to find calm areas. As the game goes on the
> choices go down making it harder to find the calm areas. That causes an issue that later the
> player might walk into the wrong direction first making them not find the last remaining calm
> area in the time given. Closures can come in two ways: 1) a permanent restriction in the city's
> grid — we should have impassable blocks that are not technically a closure but just the city's
> layout, e.g. a cul-de-sac or a scrapyard, a city feature that naturally breaks up the grid; 2) an
> existing road gets closed later in the game for one or more days. 1) is to reduce the total
> number of valid paths making the graph less open. 2) is to guide the player to remaining calm
> zones — those closures should be placed to prevent the player from walking in a wrong,
> unwinnable direction. The goal is to guide/nudge the player to go into the right direction. This
> can be hard (full closure) or soft (multiple events forcing the player to turn around)."*

### The three parts

- [ ] **A city that is not a full grid, permanently.** Impassable blocks that are the *layout*
      rather than an event: a cul-de-sac, a scrapyard, a depot. They are what makes every route
      question downstream answerable at all — with a full lattice, no closure, cut or run of
      closures can change a route, which is measured rather than argued.

      **The mechanism already exists and should be reused rather than reinvented.** M21's calm
      zones absorb the streets between their own blocks: `CityMap.absent_segments` is the set of
      streets this city does not have, and `blocked_segments()` merges it with today's closures for
      **every** route search in the game. A permanent restriction is more absent segments plus
      ground that is not walkable — the same shape, decided at generation, fixed for the run.

      Four things it has to keep true, and each already has a test that will say so: route
      redundancy on day 0 (`StreetNetwork.route_count() >= 2` to two distinct calm areas — the
      thing M21 made true by search rather than by construction); no purpose change may move a
      walkable tile (`tests/test_blocks.gd`); the home's doorstep street stays reachable; and the
      crowd's lanes have to stop at whatever the new edge is, which is the M41 boundary problem one
      scale in — the lattice already ends in T-junctions at the map edge, and a cul-de-sac is that
      shape happening inside the city
- [ ] **A closure that points.** The acceptance test changes from *"does this lengthen the best
      route"*, which nothing can satisfy, to *"does this stop her committing to a direction that
      cannot win today"*. The information to do it already exists at dawn: `build_day` knows which
      calm areas are spoiled and `_ensure_one_usable_park` knows which one is protected, so the
      day knows which way is a wasted journey before the player takes a step.

      The trap to avoid, and it is the whole difficulty of this part: **a nudge that removes the
      decision is worse than a closure that does nothing.** The game's one verb is *where do I
      walk*; a day that fences her into the only right answer has taken the verb away. So this is a
      barrier on the way to somewhere unusable, not a corridor to somewhere usable, and the
      two-distinct-routes invariant stays exactly where it is
- [ ] **And a soft version, which is events rather than barriers.** *"Multiple events forcing the
      player to turn around."* The pieces are all there — `obstructs_radius` since M34, the spacing
      rules since M28, the density since M41 — and what is missing is the **intent**: nothing in
      `EventScheduler` has ever placed events in order to say *not this way*. Worth building second
      and measuring against the hard version, because a soft nudge she can push through is the one
      that keeps the decision hers

### The open question underneath it

**How fast should the choices narrow, and does `MIN_CALM_BLOCKS` survive it?** The narrowing is
half-built already and by a different mechanism: since M41 the park spoiler remembers **the whole
act** and resets when the act turns, so choice narrows within an act and is handed back at the
boundary. This design wants it to narrow across the *run*. `MIN_CALM_BLOCKS` is currently sized as
one per day of the longest act plus one, precisely so that the spoiler can never leave her with
nowhere to go — that sizing is playtest 12 finding 5 and it is the thing this would push against.
Decide it with a measurement, not an argument: the number that matters is how far the *last*
remaining calm area is from the door on the last day of an act, against the 180s she has.

**Absorbed into M47.** The two halves that are still open here — permanent restrictions and
closures that point — need the same machinery as playtest 13's bigger calm areas, and building
`absent_segments` twice is how the second one goes quietly wrong. The design above stands
unchanged and is the second half of M47; read it there.
