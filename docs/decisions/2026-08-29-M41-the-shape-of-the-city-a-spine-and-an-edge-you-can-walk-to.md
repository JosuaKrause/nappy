## M41 — The shape of the city: a spine, and an edge you can walk to · `feature/the-shape-of-the-city`

See **[docs/playtests/PLAYTEST-11.md](../playtests/PLAYTEST-11.md)**, section C, and **[docs/playtests/PLAYTEST-12.md](../playtests/PLAYTEST-12.md)**,
which is this milestone played while it was still on the branch. Three entries that are one
milestone, because they are the same sentence: **the city has no hierarchy.** Every street is the
same street, the arterials differ only by how many cars are on them, and the map stops at an
invisible wall.

This also closes the half of **M21** left open by decision — *main roads with lights* — and replaces
the earlier "cliff, fences, harbour" sketch with the design the player gave, which is better for the
reason they gave: *"that way it's not an artificial end but an emergent end."*

**All of it is done.** What follows is what each part turned out to be; the corrections marked
*(playtest 12)* are the ones a person found in it the same day.

- [x] **Three kinds of street, told apart at a glance.** A main road — dark asphalt, an unbroken
      double centre line, doubled clearway markings on its kerbs, signalled at every junction and
      **it does not give way to anybody** — against a retail precinct, which is brick from frontage
      to frontage with no kerb and no cars in it, against the ordinary street that is everything
      else. *(Playtest 12, findings 1, 2 and 7: there is **one** main road and it runs north to
      south, and there are **two** precincts of three blocks each, one along the southern shore.
      The first build made one of each per axis, which is three kinds of street and no hierarchy
      among them.)*
      **A wider main road was tried on paper and rejected**, and the reasoning is in `docs/CITY.md`:
      the corridor cross-section is uniform by construction, a 1-tile pavement is the width M1
      found unwalkable, and doubling a carriageway restates the traffic fairness contract for every
      street at once
- [x] **And the ground is a rate, not a category** — *(playtest 12, finding 8)*, the change that
      makes a route a **recovery rate**: calm 2.2, precinct 1.5, ordinary street 1.0, main road 0.6.
      `WorldContext` grows a fourth question, which generalises the half of `is_calm_zone` that was
      never a threshold. It is the first time since M14 that the ground has done anything except be
      calm or not, and it is what makes a precinct worth walking to although it is loud
- [x] **Traffic lights.** The cycle is **derived** from the block spacing rather than authored —
      `2 × SIGNAL_PROGRESSION_BLOCKS` junction-to-junction travelling times — which is what lets a
      green wave run both ways down the same street. Without a progression two thirds of the traffic
      stands still at any instant, measured. **The "both ways" half of that is wrong and M46
      measured it: the wave serves one direction and cannot serve two on this geometry.** The side
      street's green is the fairness contract
      (`Tuning.validate_signals`), because she crosses a main road while the main road is red; the
      amber is a clearance period, not a warning. *(Playtest 12, finding 4: the four heads at a
      junction are now two drawings — face-on for the arms running up and down the screen, edge-on
      for the ones running across it, so what you can see of the lamp is which street it means.)*
- [x] **A tunnel north, a bridge south, and the main road running out east and west**, plus a ring
      of frontages one block deep outside the whole boundary — and **the camera may see past the
      map**, which it could not, and which is why the edge would have gone on looking like a wall
      however much was built out there. The lattice already ended in T-junctions and nobody could
      see it: the outermost corridor is a whole street and every interior street runs into it and
      stops. No walkable tile moved
- [x] **Cars do not enter a junction they cannot leave.** Measured before: **3,776 overlapping
      crossing-axis pairs in ninety seconds of the arterial, one in half of all frames, the deepest
      39px into a 40px footprint** — with every assertion about the traffic passing throughout,
      because each car's own *lane* was legal. Four clauses, all load-bearing, in `CLAUDE.md`. The
      one that decides whether a grid queues or seizes is *nothing enters a box it cannot leave*
- [x] **And a car that does enter an occupied box is an accident** — built as the M19 mechanism
      rather than as a catalogue row: it **startles the cars it happened to**, so it is loud where
      it happened and composes by addition like every other body. Deliberate: with the box rationed
      it happens under one frame in twenty of the busiest street in the city, and an event nobody
      meets in a run is a silhouette and a fairness contract spent on decoration
- [x] **11×11.** *(Playtest 12, finding 9.)* The first resize taken for room rather than for a rule.
      The act I caps went up with it — a budget the catalogue cannot spend is not density (M28) —
      and the suite went from 96s to ~160s, which is the price of 49% more city
- [x] **Judged by eye.** Screenshots of all three kinds of street, a signalled junction across the
      cycle, the promenade, and all three exits. Two things were only visible that way: the tunnel
      opening into the void beyond the frontages, and the four identical signal heads at a junction
- [x] **And every route guarantee re-measured, not assumed.** Nothing moved a walkable tile, which
      is why `tests/test_blocks.gd` and `tests/test_routes.gd` are the measurement rather than a
      hope: a precinct is paving where pavement was, a main road is paint, and an exit is the last
      stretch of a street that was already there

### What playtest 12 changed on top of that

- [x] **One main road, north to south** — finding 2
- [x] **Two precincts of three blocks, one on the shore** — findings 1 and 7, and they are retail:
      `PRECINCT_BUSYNESS` for the foot traffic, `EVENT_PRECINCT_WEIGHT` for the cafés and stalls
- [x] **Walkers use the whole width of a precinct** — finding 1's *"people seem to not go in the
      middle"*, which was right and was not a steering bug: the middle two offsets are the
      carriageway on every other street, so nothing had ever been placed there
- [x] **The spine carries forty cars** — finding 3. It was not that thirty was too few; it was that
      there were two main roads and the weighting split between them. One spine is blocked 81% of
      the time
- [x] **Calm areas: one per day of the longest act, plus one** — finding 5, and the spoiler
      remembers the whole **act** rather than the night before, resetting when the act turns. One
      night's memory makes day 2 a fresh decision and day 3 the same decision as day 1
- [x] **Calm ground fills the meter 20% faster again** — finding 6, `SLEEPINESS_CALM_ZONE_MULTIPLIER`
      12 → 14

### The old plan, for what it said

- [ ] **Two kinds of street, told apart at a glance.** A main road — wide, fast, heavily trafficked,
      signalled — against an ordinary or pedestrianised street that is slow, crowded and has no cars
      in it. The point is not decoration: with one kind of street the route decision is only *which
      way*, and with two it is also *which kind*, which is the trade the whole game is made of. It
      needs a visual difference that reads without a legend
- [ ] **Traffic lights.** A signalled crossing is a **timing** problem where a zebra is a gap-hunting
      one, and it is the honest counterpart to *"the arterial has a safe gap about one time in
      twenty"*. Re-measure the mean wait at a kerb afterwards; that number is the whole of whether an
      arterial is crossable
- [ ] **A tunnel north, a bridge south, and the main road running out east and west.** One of each,
      carrying the spine off the map. **Walkable, and fatal when a car comes** — not a special case,
      just the traffic fairness contract on a stretch of carriageway with no pavement beside it. The
      player walks out of the world rather than being stopped by a wall
- [ ] **T-intersections everywhere else on the edge.** The lattice currently runs into the boundary
      and stops. A T says the street turns rather than being cut off
- [ ] **Cars do not enter a junction they cannot leave.** M38 made a car turning into an occupied
      *lane* look first (`TrafficIndex`); the **junction box** was never modelled, so two cars on
      crossing arms both see a clear lane ahead and both enter, and the positional resolve then does
      the only thing it can — move a body. Same shape as M38's fix, plus the thing a junction needs
      that a lane does not: a **priority rule.** Right-before-left, which settles the symmetric case
      without a negotiation; lights override it where they exist
- [ ] **And a car that does enter an occupied box is an accident**, which is an event, not a
      collision to be resolved away. Deliberate, and worth building rather than losing
- [ ] **Judged by eye.** A headless run never calls `_draw()`. Screenshots of both kinds of street,
      a signalled crossing, all four edges, and a junction under load, on several seeds
- [ ] **And every route guarantee is re-measured, not assumed.** Three walkable exits move the
      walkable set, which `tests/test_blocks.gd` asserts is identical tile for tile across every seed
      and block arc. A route that leaves through a tunnel must not count as a route to a calm area
