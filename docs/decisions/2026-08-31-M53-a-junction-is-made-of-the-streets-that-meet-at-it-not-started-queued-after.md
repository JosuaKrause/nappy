## M53 — A junction is made of the streets that meet at it · not started, queued after M52's lights

### Built 2026-09-01 · `feature/junctions-ask-their-arms` — four of six, one fork left open

- **The missing-arm crossings.** Measured before touching code: zero `CROSSING` tiles ever landed
  *inside* a `built_over` rect, but dozens sat in the two-tile band just outside one — for dead
  ends and big buildings across every sampled seed. Zones already had the fix in
  `_absorb_streets`'s stub cleanup; the other two placements never got the equivalent. The shared
  piece became `CityGenerator._seal_stub_crossings()`, stated once over "ground that just stopped
  being a street", called from all three; a property test walks every zone, dead end and big
  building of 12 seeds. **The shore/park four-arm claim did not reproduce as a distinct bug** —
  boundary T/L-junctions are geometrically correct by construction (no tile grid exists past
  `map.size` for a phantom arm), matching M49's earlier "not reproduced" on a near-identical claim.
- **Off the map, both candidates checked.** "The junction should not be there" does not reproduce —
  `StreetNetwork` never enumerates past its own junction count. "The agent is recycled on screen"
  was real and general, not spine-specific: `_recycle`'s all-rolls-missed fallback used
  `ENTRY_SPREAD` (420px, a car's own reach) for every kind, so a walker could settle 238px past the
  true south edge. The fix clamps the settled position to the same room the *exit* side already
  grants (`_keep_within_the_room_beyond_the_map()`), measured down to one tile; a test at the east
  edge holds it away from the spine too, and another asserts a car on the spine still overruns by
  `OUT_OF_SIGHT`, so the bridge stayed lethal.
- **The crowd already agreed with the drawing** — `CrowdAgent._cannot_go_on` reads
  `CityMap.is_street()`, the same predicate the paint fix preserves. That was an inference from
  code, so it got a test: a real day's traffic at a zone, asserting no car ever stands on the
  absorbed corridor.
- **The precinct-junction item was not built, deliberately.** Two pieces of current documentation
  contradict each other: `_street_tile`'s docstring defends "a driveable street crossing [a
  precinct] does so over a zebra six tiles deep" as intentional, while the queue called the same
  junction a bug. Empirically (24 internal precinct junctions over 6 seeds) no `ROAD` tile is ever
  produced there — only `SIDEWALK`/`CROSSING` — so the fix requires deciding whether a real
  street's carriageway should survive through a precinct it merely crosses. Two recorded
  instructions in tension go back to the player; the open half stays in `TODO.md`.

**Ordered by the player: *"queue those fixes after the traffic light fix."*** So M52's third item
goes first and this follows it, which is the right way round for a reason worth writing down — the
lights are a decision about **which junctions are junctions at all**, and three of the four items
below are about what a junction is made of. Building them against a lattice that is about to be
re-asked the same question would be doing the work twice.

Playtest 16, in full in **[docs/playtests/PLAYTEST-16.md](../playtests/PLAYTEST-16.md)**. Five findings; four of them are
one complaint: **the city draws a lattice it does not have, and the crowd walks it.** It walks onto a bridge with no
footway, off a bulkhead into the sea, and through crossroads whose arms are grass — and in every
case it then vanishes where somebody is looking at it. Underneath the first two is one missing
rule: the lattice draws a full crossroads wherever two corridors cross, whether or not the arms of
it are streets.

**Neither of these is news to the repo, which is the part worth noticing.** M41 has carried
*"T-intersections everywhere else on the edge — the lattice currently runs into the boundary and
stops"* as an unbuilt item for twelve milestones, and M51 finding 1 was this exact defect on a
cul-de-sac, fixed there for the crowd's *view* of the wall and not for the junction that should
never have been drawn. A finding that arrives twice from a player after being written down once by
the project is a to-do that was filed and not read.

- [ ] **Cars and people still go off the map** — finding 1, and *"still"* is the word to read.
      M51's fix was deliberately narrow: overrunning the boundary is for **a car on the main road
      going north or south**, because outside the map is water, forest and mountainside. Everybody
      else keeps "the tile of slack they had", and this report is that the slack is visible at an
      edge with nothing beyond it, for people as well as cars. Two candidate causes and they want
      different fixes — the agent is **recycled on screen** (M35's *"nothing vanishes while you are
      looking at it"*, which has never reached the crowd away from the three holes in the border),
      or the **junction should not be there**, which is finding 2
- [ ] **A junction between two precinct arms is still asphalt with zebras on it.** A precinct is
      laid `SIDEWALK` frontage to frontage by `CityGenerator._street_tile`; the junction between two
      of them was never included, so a pedestrianised stretch has a road crossing in the middle of
      it
- [ ] **A junction whose arm is not a street has three arms, not four.** The shore, a park, a calm
      zone's absorbed corridor, a dead end's plug — `CityMap.absent_segments`, `built_over` and the
      map edge already say which arms exist. Nothing that draws a junction asks
- [ ] **No crossing onto a wall** — finding 5, *"the backside of a cul-de-sac should not have a
      pedestrian crossing"*, and it is the item above stated where it cannot be argued with:
      `CityMap.built_over` names the tiles, and there is a zebra painted onto them with a traffic
      light beside it. A crossing marks **where to cross to**, so this one is worth doing even if
      the full three-armed junction is not — the paint is the promise
- [ ] **Only cars go over the bridge** — finding 3, and it is M51 finding 7's own sentence read
      back. A bridge is *"a stretch of carriageway with no pavement beside it"*, which is the whole
      design and is why she may walk onto it and be run over rather than be stopped by a wall. The
      **overrun permission** was narrowed to a car on the spine and the **lane** was not, so a
      walker's lanes still run the length of a corridor that at the boundary is a bridge. Note what
      is not being asked for: the bridge is not to be made safe
- [ ] **And the crowd has to agree with the drawing**, which is M51 finding 1's lesson arriving
      where it was pointing: a T-junction the paint knows about and `CrowdAgent._divert` does not is
      the same bug in the other direction
- [ ] **Calm areas at the edge of the map** — finding 4, *"which should be impossible"*, and it is
      **not this milestone's to build**. The rule is already written down, unbuilt, in M47: *"make a
      rule to not have a calm area at the edge of the map or next to the main road"*, with the
      measurement (96 eligible blocks → 56 with the edge rule → 48 with the spine rule) and the
      three things to get right already beside it. Recorded here so the finding is not lost, and
      **closed from M47** rather than re-designed. It is the third item in one session that this
      file had filed and not read
