## Gotchas learned in the M21 session

- **A turn is the one move that commits without looking, and it had been getting away with it.**
  A crowd agent's turn swaps the axes, so the coordinate it had *along* its old corridor becomes
  the one it has *across* the new one — the lane it then steers away from. Turning at the far
  edge of a junction therefore drops a car onto the pavement band for the next three tiles. That
  has been true since M13; four closures a day was too rare for anyone to see it, and four
  dead-end arms per calm zone was not. `_can_turn_here()` waits for the band the agent belongs
  in, and the lookahead went from 26px to a corridor's width so there is time to wait.
- **A spawn point is not a position an agent walked to.** An agent dropped into the middle of a
  junction rolls a turn on its first frame from wherever it was put, which can be the
  carriageway. Also true since M13, also only surfaced because the RNG order changed and
  reshuffled the crowd. `_settle_junction()` marks the junction it starts in so it does not.
- **Five seeds is not a measurement of a noisy number.** The first density comparison said M21
  had cut "events met on a walk" from 3.6 to 2.0, which would have been most of the difficulty
  playtest 06 had just approved. Over 24 seeds and four directions each it is 2.91 → 2.85. The
  handoff already said *"a single total over three seeds fails on noise"*; this is the same
  lesson costing an hour in the other direction.
- **The obvious tidy-up round a zone's edge was wrong, and only a tile-by-tile check said so.**
  A zebra whose road runs into a park looks like nonsense to remove — but a crossing sits where a
  *pavement* lane meets a *carriageway*, and both are still there. Repainting them put pavement
  in the middle of a junction cars turn through. What is genuinely dead is only the **stub**: the
  quarter of each T-junction on the zone's side, which is exactly `grow(SIDEWALK_WIDTH)`.
- **A repaint that clears as it goes cannot have two lots sharing ground.** `CityMap.repaint()`
  filled each block with building and then painted its carves, which is order-dependent the
  moment one lot's open rect covers another lot's block: whichever came later in the dictionary
  punched a building-shaped hole in the park. Clear everything, then paint everything.
- **A default in a lookup is a wrong answer waiting to be believed.** The generator's
  "no two calm areas adjacent" check read `owner.get(neighbour, member)`, so a block with no
  calm neighbour compared its own coordinate against its anchor and reported every zone as
  adjacent to itself. Every seed failed validation and the generator quietly fell through 64
  attempts and returned the last one.
