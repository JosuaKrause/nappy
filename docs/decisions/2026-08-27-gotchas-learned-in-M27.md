## Gotchas learned in M27

- **A brake cannot open a gap that does not exist.** Two cars that start inside each other both
  choose zero speed and stay there. Separation between bodies is **positional** — now an
  invariant in `CLAUDE.md`, and the same shape as M19's player bump.
- **Recycling everybody onto the same pixel is a pile-up generator.** Re-entering agents placed
  on the exact edge coordinate produced eight overlapping pairs a frame on a road nobody could
  see, and once cars keep a headway the pile never sorts itself out. They enter in a band.
- **A lane has a capacity.** At the first density the arterial wanted 194px of spacing per car
  and had 118px of lane per car: it jammed solid and no controller helped. Car counts come from
  what a lane can carry.
- **A weight whose denominator changed is a trap.** `ARTERIAL_BUSYNESS` used to mean one
  street's share of sixteen corridors and now means its share of the three or four inside the
  field box, so the *same number* put half again as much traffic on the arterial — 0.6%
  crossable, 22s at the kerb. That is a wall, not a hazard. It went 5.5 → 5.0.
- **Code after an unconditional `return` never runs, and the tests are what find it.**
  `CrowdAgent`'s lateral recycle check was written after the along-axis one, so a player walking
  north left everybody on every east-west street she crossed behind forever, and the pavement in
  front of her would have drained over a minute of play.
- **A mobile event starts moving when its telegraph starts**, which is right for a fire engine —
  its telegraph *is* the approach — and was catastrophic for the cat: a one-street crossing at
  240px/s finished during its own 1.6s telegraph, so it never reached full intensity and
  `CAT_RUNNING` had never drawn a single frame in six milestones. A green suite, a passing
  fairness contract and a screenshot all had nothing to say about it.
- **Streaming has two floors on its radius and the larger wins.** Half the viewport diagonal, so
  nothing is seen to appear; and wider than the widest field in the catalogue, so an event is
  outside its own outer radius the moment it becomes visible. Without the second, streaming is a
  way of dropping events on people and the telegraph contract is a lie.
- **Rejected: making the arterial quieter to make it crossable.** It has to stay above the idle
  decay or standing still on the busiest street in the city becomes a strategy, which is the one
  thing the crowd exists to stop. The resolution is the zebra, which the generator puts at every
  junction.
