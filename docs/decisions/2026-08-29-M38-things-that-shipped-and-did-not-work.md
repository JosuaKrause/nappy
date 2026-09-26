## M38 — Things that shipped and did not work · `feature/nothing-freezes`

Not a playtest: five reports and two design instructions, delivered in one sitting. What they have
in common is that every one of them had passed a green suite, a screenshot, or both — see the note
at the top.

- [x] **The birds are eleven birds** — *"they start the flying animation but then freeze. Turn them
      into individual entities and let each fly and make them dangerous."* A flock was one sprite
      drawn seven times at offsets derived from the instance's own position, sharing a single `rise`
      term that reached 1.0 at the end of the telegraph and then held — so the flock went up in one
      movement and hung motionless for the whole burst. `EventDef.flock_size` gives each bird its
      own heading, speed, height and wingbeat, **and its own contribution**, so the middle of a
      flock stacks five fields and the rim stacks one: +35 walked through the centre, +8 eighty
      pixels off it, nothing at the rim. It is the only row in the game that is more than one
      source, which is why `tests/test_events.gd` had to learn to price one — left as a disc the
      row read +97 and broke the running rule it in fact keeps. Two traps, both in `CLAUDE.md`:
      `flock_spread` comes out of `outer_radius` or the fairness contract is about a different
      disc, and `lerp` cannot turn a vector round
- [x] **The cat faces the way it is going** — *"the cat graphic is flipped horizontally."* Both cat
      SVGs were drawn facing **west** while every other sprite with a front faces east, and
      `_heading_is_west()` mirrors the art — so a cat bolting west was drawn running east and a cat
      bolting east was drawn running west. The convention was never written down anywhere; it is
      inferable from `dog.svg`, which is drawn ahead of the walker on a taut lead and only reads
      right facing east. The art was wrong, not the flip
- [x] **A car looks before it turns** — *"when a car turns into an occupied lane the other car just
      disappears."* `_divert()` chose an arm out of the tile map alone, so a car diverting round a
      closure materialised inside whatever was in that lane, and the M27 positional resolve then
      moved a body — front to back, compounding, up to 134px in one frame, on screen. `TrafficIndex`
      is the look; `claim()` closes two placements in the same frame; `_join_the_back_of_the_queue()`
      is the guarantee behind the six re-rolls. Measured at a closure over 90s: 1627 corrections and
      a worst of 134px, down to 146 and 66px. The queue was legal on every frame either way, which
      is why the test that has always been here passes both
- [x] **Calm ground is 20% faster** — `SLEEPINESS_CALM_ZONE_MULTIPLIER` 10 → 12, so the meter fills
      in 20s rather than 24. Every milestone since M28 has made the walk *out* harder and left the
      reward at the end of it the same length. Unfelt; it is in the known-shaky list
- [x] **A finished run has a key on it** — *"the lost screen doesn't allow for restarting the game.
      You can just cycle between pause screen and loss screen at that point."* The ending said
      `esc to quit`, `Esc` opened the pause, and the pause offered `Esc` and `Q`. `space` on the
      ending now goes back to the title, and `R` on the pause starts the run again from anywhere
- [x] **A title screen, with the game running behind it** — *"start on the pause screen, or create a
      game open screen"*, then *"just use the home and street in front without player and let act I
      events play out."* Not a menu and not a still: the doorstep of a real, planned first day, with
      the traffic driving and the events playing out on it and nobody pushing a pram through them.
      It needed the `process_mode` split used deliberately for the first time — the city on `ALWAYS`
      and the day paused, with the player pinned back to `PAUSABLE` because she is a child of the
      city — and `Stroller.stand_aside()`, which takes her out of the `player` group and with it
      every way the world can touch her
- [x] **`--press` can press a key, and can press more than one** — `Q` has quit from the pause
      screen since M33 and `R` restarts now, and neither is an input action, so the rig that exists
      because *nothing in the suite or a screenshot has ever pressed a key* could not press either
      of them. `--press key:r 3.5`, and the flag may be repeated
