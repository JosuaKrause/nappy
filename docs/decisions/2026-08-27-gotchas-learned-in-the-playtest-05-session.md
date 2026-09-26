## Gotchas learned in the playtest-05 session

- **A budget the catalogue cannot spend is not density, and this is what that looks like.** Four
  types with caps of three each is a hard ceiling of twelve however large the budget is. When a
  density number refuses to move, check the caps before checking the arithmetic.
- **Measure four numbers, not one.** Placed per day, live inside the stream radius, on screen at
  once, and met on a route. They moved by different multiples in M28 — 3.8×, 6×, 3.3×, 2× — and
  only the last is what a player is complaining about. Quoting whichever one flatters the change
  is the easy mistake.
- **`max_per_day` was doing a second job nobody had written down.** Placement is a uniform
  random tile with no minimum separation anywhere, so the cap of three was the only reason two
  dog walkers had never landed on one pavement. Raising a cap took a rule away.
- **Spacing measured tile-to-tile misses a mobile event entirely.** A dog walker's route is
  thirty tiles long; checking only the tile it starts on let it walk the length of an
  abduction's field. Measure whole route against whole route, from both ends — the closest point
  of two segments is an endpoint of at least *one* of them, and it need not be yours.
- **A convention stated over the wrong variable is invisible to every test.** "Offset 3 runs the
  positive way along the axis" is self-consistent and it is right-hand traffic on one axis and
  left-hand on the other. Separation, headway, capacity and noise are all true either way, and a
  still screenshot cannot see which way a car points. Only a human watching a junction could.
- **Braking toward zero speed is not stopping *somewhere*.** A car aimed at zero stops wherever
  the curve runs out, which with four times the room it needs is most of a block early. Aim at a
  place. And shape the approach with a **gentler** rate than the emergency brake, or the onset
  of braking and the commit point are the same instant and nothing ever stops.
- **Sampling a tile grid by stepping world points aliases where it matters.** The crossing scan
  probed every 32px, which is fine everywhere except at the stop line, where the car is a few
  pixels from the paint, both samples miss, and it pulls away with somebody on the zebra. Walk
  tiles. Now in `CLAUDE.md`.
- **A cue that lives in one class has an invisible edge.** The caret was
  `EventInstance._draw_mark()`, so "the entity carries its own cue" quietly meant "the *event*
  entity does", and the one lethal thing outside the catalogue — a car — had nothing at all.
- **A script error inside a test does not always fail the suite.** GDScript aborts the erroring
  *function* and carries on in the caller, so a `_physics_process` that died half way through
  still let the assertions after it run and pass. Four stack traces in the middle of a green
  run. `CLAUDE.md` says an error *hangs* the runner; that is the other failure mode, and this
  one is quieter.
- **A test can assert more than the design promises and nobody notices until the numbers move.**
  `_test_one_park_stays_usable` measured the whole block lot; `_ensure_one_usable_park` has
  protected only the calm *ground* since M15, deliberately. Invisible at thirteen events a day,
  false on nine days out of fourteen at fifty.
- **Where a trace and a rule want the same fact, the rule keeps its own copy.** M24 is the first
  rule that wanted to read the telemetry. Reading it would have been smaller and would have made
  the game play differently with `--no-telemetry`.
- **The give-way test had been measuring nothing since M27.** The crowd is a field around the
  player and the rig has no player, so two of the three cars it picked were recycled on the
  first frame and every measurement after that was of a different road. Any rig that steps
  crowd agents by hand has to `set_focus()` first.
- **A probe that disagrees with the game is wrong about the game.** M31's walk probe said a
  7,500px round trip peaked at 13 excitement while a real run of the same day died in fifteen
  seconds. It was stepping the agents but never `Crowd._physics_process`, so no contact and no
  horn ever fired — and the crowd is most of what a street costs. The instinct to trust the
  measurement over the observation is the one to resist.
- **Adding rows to a fixed density takes a share from every existing row.** M31 put seven new
  events into act I and the two playtest 05 had named by name immediately thinned out. Their
  weights had to go *up* to stay where the previous milestone had put them. Whenever the
  catalogue grows, re-measure the things an earlier milestone promised.
- **A single total over three seeds fails on noise.** The named-decision assertion broke at 17
  against a bar of 18 while the five-seed mean was comfortably over. A per-seed floor plus an
  average says the same thing and does not.
- **Only half of "a spent plan stays spent" was implemented.** Streaming may take a running
  event away and give it back — and it was giving it back *at the tile the day chose at dawn*.
  A dog walker at 32px/s against her 92 crossed the stream boundary constantly, so it teleported
  home over and over and read as never moving. The invariant now says *and a running one
  resumes*.
- **A thing that moves has to look like it moves.** The same complaint had a second cause with
  no bug in it: every crowd agent has a two-frame stride and an `EventInstance` had none, so a
  tile a second read as parked. A bob driven by distance covered, not by time.
