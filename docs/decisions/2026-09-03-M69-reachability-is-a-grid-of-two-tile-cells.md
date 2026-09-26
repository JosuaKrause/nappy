## M69 — Reachability is a grid of two-tile cells · built 2026-09-03

*(2026-09-03, playtest 20: "barriers don't take into a account that parks can be entered where
normally buildings would be making them ineffective. (at the same time a courtyard can be completely
sealed off by a barrier because it blocks the entrance alley). the same applies to alleys. the
reachability checks need to take alleys and parks properly into account. it's not enough to reach a
block.")*

**The design moved twice before it was built, and the second move came from the player.** The first
shape was hand-modelled openings — *"alleys should become edges. parks should have edges at all 8
exits. courtyards only have one edge to one road section segment"*, with a follow-up that *"nodes and
edges need to be more granular"*. That was drafted as: a node per opening (alley mouth, courtyard
archway, park frontage), an edge per stretch of street between two consecutive openings. **It was
dropped in favour of a uniform grid** — *(2026-09-03: "how about making every 3x3 tile block a node?
that should cover it? … and the 2 wide alley just connects in two connections instead of 4")* —
because coarsening the tile map lets every geometric fact fall out of the tiles instead of being
enumerated by somebody, and it covers the cases nobody thought to enumerate: squares, the home notch,
precincts, big buildings, dead ends, and a park that stopped being calm this morning.

**The cell is two tiles, and three was rejected on arithmetic.** The lattice period is `BLOCK_SIZE`
(8) + `STREET_WIDTH` (6) = 14 tiles and the map is 160 tiles square. Three divides none of 6, 8, 14
or 160, so a three-tile cell straddles the kerb at a different offset in every block and a
part-building cell needs an invented threshold — the same physical situation getting different answers
in different parts of the map. Two divides all four, so every cell is wholly street or wholly block,
and it makes `ALLEY_WIDTH_TILES` (2) exactly one cell, which is the "two connections instead of four"
the proposal was after.

**A cell is not one node, and the first write-up of this was wrong.** *(2026-09-03: "doesn't the
content of the 2x2 super tile define which of the four sides are connected?")* The rule as first
written — a cell is walkable when any tile in it is — walks straight through a one-tile building
sliver, and `CityGenerator._keep_nonempty` keeps slivers on purpose because dropping them leaves
`BUILDING` tiles with no building node over them. So a cell contributes **one node per 4-connected
component of its walkable tiles**: sixteen masks, of which the two diagonals split into two
components. That makes the grid the tile graph contracted, which is also its verification — it has to
agree with `CityMap.walk_field` over a sweep of seeds.

**Measured, and the worry did not exist.** The diagonal-split masks occur **zero times in 76,800 real
cells** across a twelve-seed sweep. The lookup table is kept anyway, since a hand-built map forces it
and nothing guarantees a future block layout never will.

**Two findings from reading the code that made the rest safe.** Every production caller of
`StreetNetwork.route_count` — a unit-capacity max flow counting edge-disjoint routes — asks for a cap
of **one**, so nothing that ships counted distinct routes; only a test asked for two. That was the one
thing a cell grid would have broken, since a six-tile street is three parallel cell columns. And
`RoadClosure.tiles()` blanked the whole street on its own stated argument that *"the ground between
them is not somewhere anyone can get to"*, which is false wherever an alley mouth or a courtyard
archway opens onto the middle of it — and both land mid-segment by construction.

**What the grid is for is a placement rule, not a check**, and it is the player's own asymmetry:
*(2026-09-03: "the planner shouldn't put a barrier next to a park anyway (it will never close the
street) it only makes sense for courtyards (we need to check the entry and potentially move it)")*. A
park is walked *through*, so a barrier on any of its access streets closes nothing and reads as broken
to anybody standing beside the open ground; a courtyard is a pocket with one door, so a barrier beside
it is real except on the one street its archway opens onto. Built as an outright exclusion from the
candidate pool rather than a weighting, which is this project's rule that closures are checked before
they are accepted and never repaired afterwards. It refuses a mean of **33.4 of 264 lattice segments
per day**, and every one of 168 (seed, day) pairs refuses at least one.

**"Move it" was read as moving the barrier, not the archway**, since a block's purpose may never move
a walkable tile and the archway is generated once for the run. Recorded as a reading rather than a
quotation, and open to overturn.

**Drawing the corridor at cell granularity turned out not to be a drawing change.**
*(2026-09-03: "make sure to draw the paths in that granularity as well instead of the whole block side
what it does now")* A cell-snapped stroke over a tree made of whole block sides is the same shape two
tiles wide, so `RouteTree` had to grow on the grid for the picture to change. That also made it M64's
precondition: against a block-side tree, *closed everywhere off the path* would seal every park
crossing and every alley in the city.

**Four things the build found that the design, settled from outside the code, had wrong:**

- **"The two routes to one area share no street by construction" is no longer true.** They share no
  *cell*, and a street is three cells wide, so on a rare street both routes' cells resolve to the same
  `StreetNetwork.Segment` and one covering-set site legally covers both. `docs/CITY.md` and
  `docs/EVENTS.md` said the old sentence in three places; two tests moved from absolute assertions to
  measured floors.
- **A real bug in the access-street search**: it could stop on a street a calm zone had absorbed into
  its own interior — an apartment complex's archway crossing its own absorbed street — and call that
  the way in. Fixed by requiring the segment to still be in the lattice.
- **`Corridor.depth()` is a hybrid rather than pure cell depth.** Pure cells narrowed the on-corridor
  band to a third of a street's width and collapsed the event placement proportions (37% on-corridor
  against a required 45%, 12% gap-wall against 20%), so street tiles keep the junction-graph BFS and
  everything else uses cell depth.
- **`RouteTree.rim()` went back to the junction/segment computation.** Grid depth broke *"every gap is
  on the rim by construction"* once the tree could shortcut around a gap through calm ground, and that
  guarantee was always stated at the segment grain.

**One guarantee is knowingly weaker, and the player agreed to it on 2026-09-03.** M53's assertion that
nothing ever stands inside a hard blocker was `frames_with_one == 0`; it now tolerates one agent on
under 5% of frames, measured at 1.1% — one car on 27 of 2400 frames, against the eight-at-once on 87%
of frames that the original M53 fix addressed. The cause is in `src/crowd/`, which this milestone
never touched: `CityGenerator._place_hard_blockers` grows one reference route tree and hands it to both
the dead-end and the big-building placement, so a cell-grown tree moved a big building to where a
queued car's crawl-forward step grazes its footprint. Filed as its own queue item so the assertion can
go back to zero.
