## M105 — The city degrades · built 2026-09-11

*(2026-09-10: "we need cracked street/sidewalk tiles to be able to deteriorate the city. we need
loose garbage (eg eaten apple, newspaper, etc) … we need garbage sacks that can be placed in
alleyways at first and at the side of buildings later on as the city degrades." and "floor tiles
of the city need different levels of cracks".)* Seven agent commits on
`feature/the-city-degrades`, reviewed here. **One curve.** `Tuning.degradation_for(day)` is zero
before `DEGRADATION_FIRST_DAY` (5 — act II's second day, the later end of the player's "day 4 or
5", so act II opens looking like act I and the decline is what the act does to the city) and
rises to one on the last day the way the budget does; everything below reads it and nothing else.
**Cracks by level**: `GroundTiles` picks hairline, cracked or broken from the curve and a per-tile
hash, the pattern within a level from the same hash, so a tile shows the same crack every day and
more tiles show worse ones as the run goes on; road cracks at 0.6 of the pavement's rate, so
pavement goes first. A crack changes nothing about the tile. **Litter**: decals only, no body and
no field, placed each day from the curve and a seeded roll on pavements, alleys and squares at a
5% share, never on a road's lanes, never in a calm area and never on spoiled ground. **Sacks**:
props with a ground shape and no body, in alleys from the curve's first day and against building
fronts two days later, a 22% share of which 35% are piles; **a pile carries no body in this
version**, by the item's own instruction that the question is decided when a pile is seen in an
alley she has to use. The mouse prefers an alley with a pile through extra copies of the
qualifying tiles in the scheduler's own candidate array — not through the shared ground cache,
which the robber draws from too. **Shutters**: a boarded-up block shows the shuttered storefront
and shuttered windows everywhere, and 30% of commercial blocks shutter from a later point on the
curve. **Found by the pictures and fixed**: the curve's first day computed to exactly zero, so the
first visible decline was a day late; the day-1 and day-5 pictures looked identical until the
fraction was corrected. The four pictures in `docs/evidence/m105-degradation-2026-09-11/`, seed
105 from the doorstep on days 1, 5, 9 and 13, show a clean city, a first crack with litter,
visible cracking with a shuttering storefront, and heavy cracking with sack piles flanking the
door. The tests hold the curve's shape, the per-tile determinism, the non-decreasing shares, and
the placement exclusions. **Chosen where the design was silent**: every share and threshold above,
none in `Tuning` but the first day and the road factor, since none changes a route.
