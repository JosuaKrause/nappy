## M35 — Playtest 08: nothing vanishes, and the dog gives you a chance

See **[docs/playtests/PLAYTEST-08.md](../playtests/PLAYTEST-08.md)**. Five things, all done.

- [x] **The spoiler covers the park rather than standing in it** — finding 1, which is playtest 07's
      finding 10 asked a second time. M24 placed **one** event and nobody did the arithmetic: what
      denies calm ground is out-emitting a decay the calm multiplier has raised to 7.7/s, so a
      busker at intensity 9 has a *useful* radius of 100px in a lot 704px across — three percent of
      a four-block zone. It is a crowd now, on a grid sized by `_denial_radius()` and capped by
      `Tuning.SPOILERS_TO_DENY_A_PARK`, with **each cell rolling its own def** so a spoiled park is a
      busker and a leaf blower and a market stall rather than nine copies of one sprite. Calm ground
      denied goes from 8–12% to **91%** of a courtyard and **99%** of a four-block zone, over five
      seeds and twenty lots. *"I can walk over the robber"* is the same finding from close up and not
      a regression of M34 — a probe confirms the body stops her at 25px exactly; what it does not do
      is cost her anything once she is there
- [x] **Nothing vanishes while you are looking at it** — findings 2 and 3, which are one rule.
      *"Things that move disappear on screen; they should at least run offscreen before despawning"*
      and *"pigeons are also completely ineffective"* — and playtest 07's *"birds just disappear"*, a
      milestone earlier. An event that is over now **leaves**: it stops emitting, it cannot end the
      day, it carries no cue, and it moves until it is past `Tuning.OUT_OF_SIGHT` before it is
      deleted. Anything mobile leaves at its own speed and needed no data; `EventDef.departs_at` is
      for a flock, which has to fly, and a pursuer that has lost interest. Two things never leave and
      both would break something that reads the finishing position — an event with a
      `spawns_on_finish`, and anything that was a place rather than a moment
- [x] **The pigeons are a thing to walk around** — the other half of finding 2. They sit on the
      pavement for their whole telegraph (a flock already in the air is a flock she has walked past),
      the burst outlasts her arrival instead of ending at it, and 20 over 140px moves the row from
      +22.9 to **+34.9** — between a reversing lorry and a dog walker, which is what a flock going up
      in a pram's face should be worth
- [x] **The dog gives her room to answer** — finding 4, and the one that ended the run. Two changes
      and they are the same change twice, the contract restated as **geometry**:
      `Tuning.pursuit_standoff()`, which the telegraph is spent closing to and *holding* — backing
      off if she walks into it, because she will, since it is sited in front of her and forward is
      where she was going — and a **break-off**, so the chase ends when it is beaten rather than when
      the clock says so. Without the second one the price of the right answer was
      forty points whether she reacted on the first frame or the last, and the trace has her running,
      doing exactly what the HUD asked, and losing to the meter with the dog 87px behind her. The dog
      also came down 148 → 130px/s (symmetric: walking loses 38px a second, running gains 38) and
      intensity 22 → 12, because it is lethal and does not also need to be the loudest thing in act I.
      Measured on a rig: walking loses either way, running costs **21–24 points**, and reacting
      sooner costs less
- [x] **And the log can see a chase** — the question the finding actually asked. Two `chase` entries
      per pursuit, carrying how close it got, how much of it she spent running, and whether it gave
      up or merely stopped. The old trace had an event being sited, four distances and a death, all
      of them about the **world**, while the question is about the **exchange**. `--flee` is the
      other half: a rig that can only hold a direction can only ever demonstrate the wrong answer
- [x] **Five nerves** — *"we need more nerves let's try 5?"* Three was the number from M6, when a
      lost day also advanced the calendar and a nerve cost a day of the fourteen as well as a life.
      M32 took that half away and left the number
