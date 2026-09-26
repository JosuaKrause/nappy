## M43 — Things that are in the way of nothing · `feature/in-the-way-of-nothing`

Playtest 11's remaining findings. See **[docs/playtests/PLAYTEST-11.md](../playtests/PLAYTEST-11.md)**. The sentence under
the first three: **several things in this city are placed without asking what they are in the way
of** — which is `CLAUDE.md`'s first rule failing at *placement* rather than at design.

**Where it stands: three done, two answered by measuring rather than by building, and the two that
needed a played run have now had one.** Playtest 13 answered both — the cool-off is the wrong
*quantity* rather than the wrong constant, and dying at high excitement on a quiet street is the
crowd milestone — and added one more to this milestone, the day-4 dog. What follows is the plan
with what each part turned out to be.

- [x] **Nothing is placed on the home block** — finding 1. It is `ClosurePlanner`'s exemption
      applied to the other thing in the game that occupies ground, and it is stated over the
      **street segment** rather than a radius, because a segment is the unit the player can see the
      shape of and it ends at the junction where the choice is made. Measured before the change,
      eight seeds over days 1, 3, 7 and 14: **0.47 events a day** stood on the street outside the
      front door — one morning in two — and it is 0.00 after, with events placed per day unchanged
      at 155.9. The share was exactly the share of the pavement that street is (0.30% of both),
      which is placement being uniform and is why it needed a rule rather than a weighting
- [x] **The diagonal zzz comes back down** — finding 9, and see the entry further down
- [x] **The dog stands its ground** — finding 3's first half, and see the entry further down. What
      it left open is the number, and that is the decision below
- [ ] **A closure has to change a route** — finding 2, *"road blocks next to parks are pointless"*.
      The route-redundancy invariant is used as a **floor** (the day stays winnable two ways) and
      never as a **filter**: a closure that does not lengthen the best route to any calm area by a
      real margin is legal, invisible and pointless. Measure what fraction of today's closures do
      nothing before choosing the margin

      **Measured, and the filter is not the answer — there is nothing to filter to.** Ten seeds,
      fourteen days, 350 closures, each measured against the set accepted before it:

      | what it changed | share |
      |---|---|
      | streets on the best route to the nearest calm area | **+0 for 100%** (1 closure of 350 added one) |
      | streets on the best route to *any* calm area | **+0 for 97%** |
      | tiles actually walked from the door to the nearest calm ground | **+0 for 99%** (the worst four added 1, 2, 6 and 6) |

      Then the question the filter would have to answer: **of every street in three whole cities,
      how many would lengthen the walk at all if they were the day's only closure? Eight of 768** —
      and three of those eight seal the city off entirely, which the invariant already refuses. A
      *run* of consecutive streets is no better: 11 of 534 four-street runs move the number.

      The cause is structural rather than a bug, and it is the city that moved. A Manhattan lattice
      has many equal-length staircases between any two points, so removing one street almost never
      lengthens anything — and the city now has **8.9 calm areas** with the nearest **38.8 tiles**
      from the door, so there is always another destination in another direction. M16 built closures
      for a 7x7 city with far fewer parks in it. **A closure cannot change a route while there are
      nine destinations and a full grid**, and no margin, filter or run length fixes that.

      **Deferred to M45, with the design taken.** The answer is not a filter and not a margin: it
      is that the question was wrong. A closure's job is **direction, not distance** — see M45
- [ ] **A busker in a courtyard denies the courtyard** — finding 5, *"I can still walk around (and
      over him) while the sleepiness meter goes up"*. Two halves and both are arithmetic. **Around:**
      what denies calm ground is out-emitting the 7.7/s decay the calm multiplier has already raised,
      which is what `EventScheduler._denial_radius()` exists to compute — this is the third row to be
      caught by that sum (the busker in playtest 08, the playground in playtest 10). The suspicion is
      that a courtyard, the smallest calm area, gets a spoiler grid of one. **Over:** anything mobile
      is exempt from *solid things are solid*, and `EventDef.paces` made the pacing man mobile. Both
      need measuring before either is moved

      **Measured, and both halves come back negative on `main`.** Eight seeds, three days, every
      calm area spoiled in turn, counting a tile as denied when what the day emits there beats the
      calm decay:

      | calm area | denied | things in it | of them solid |
      |---|---|---|---|
      | courtyard, 16 tiles | **100%** | 1.0 | 1.0 |
      | one block, 64 tiles | **100%** | 3.4 | 3.1 |
      | four-block zone, 484 tiles | **98%** | 9.9 | 9.7 |

      So the suspicion is wrong in the most useful way: **a courtyard does get a grid of one, and
      one is the right number** — a busker's denial radius is 100px and a 16-tile courtyard is 128px
      across, so one of him covers it. M35's crowd and M41's act-long memory closed the "around"
      half between them. And the "over" half is a case of *check which event a complaint is about*
      (the M34 lesson): the **busker has a body** (`PERSON_BODY`) and does not pace. The only row in
      the catalogue that paces is `homeless_yeller`, which is mobile **by decision** — playtest 09
      asked for it by name, and mobile things have no body since M19. What is left of this finding
      is therefore not arithmetic at all: it is whether a *paced* man in a park should be walkable
      through, which is the `dog_walker` bargain and is already in the known-shaky list
- [x] **The dog stands its ground, and lunges on proximity rather than on a clock** — finding 3,
      *"it should be still"*. It reverses because it reaches its stand-off in a third of a second and
      then has two more seconds of telegraph to spend while she walks into it. *Standing still* alone
      is the thing M35 rejected and was right to: she then reaches it **before** the clock lets it
      fire, and it kills her from a standing start. Firing the lunge when she comes inside the
      stand-off — or when the telegraph runs out, whichever is first — gives both: it never reverses,
      and the chase always starts at the stand-off, which is the whole content of the contract.
      **`PURSUIT_MIN_NOTICE` has to be re-decided with it**: a player who walks straight in then gets
      about 1.2s of visible dog against a 1.5s floor that was authored rather than derived. Siting it
      further out is capped by the screen — 360px tall, so past ~180px a dog telegraphing north or
      south of her is off the top of it

      **Built, and it does what was asked: the reversing is gone and every lunge starts at the
      stand-off.** Walked on a rig, four ways of meeting it, sited at 184px against a 104px
      stand-off:

      | she | notice | lunges at | reverses |
      |---|---|---|---|
      | walks straight in | **0.38s** | 100px | 0.0px |
      | stands still | 0.63s | 102px | 0.0px |
      | walks away | 2.42s (the clock, not her) | 103px | 0.0px |
      | runs away at once | never lunges | — | it gives up at 1.5s |

      **And the estimate above was three times too generous, which is the part that matters.** The
      notice is not 1.2s, it is **0.38s**, and the arithmetic says it cannot be much more: she is
      walking *into* it at 92px/s while it comes at 130, so the 80px between where the director
      sites it and where it stops close at 222px/s. Siting it at the screen's own cap
      (`SIGHT_AHEAD`, 200px) buys 0.43s. Nothing reaches the 1.5s floor from that geometry.

      The floor still **passes on load**, because `validate_pursuit` reads `telegraph_time` off the
      def and the def still says 2.4 — which is M35's lesson arriving for the third time: *a
      fairness contract stated in seconds is not stated at all*, and the encounter changed while
      every line about it stayed true.

      **Decided: buy back what the geometry can, and leave the floor alone.** A pursuer is sited at
      `Tuning.SIGHT_AHEAD` (200px) now rather than at the clamp that produced 184 — the cat's
      reaction window was never a chase's, and everything between the siting and the stand-off is
      the whole of the notice a pursuit has left to give. It buys **0.38s → 0.43s**, and it is all
      that is available: the visible world is 360px tall and a dog telegraphing off the top of the
      screen has no telegraph at all.

      **Still open, and written down rather than quietly closed:** `PURSUIT_MIN_NOTICE` is 1.5s and
      the walk pays 0.43s, so the constant is a statement about `telegraph_time` and not about the
      encounter. What makes that survivable rather than a lie is that the *contract* was never the
      floor — it is `pursuit_standoff()`, which every lunge now starts at, so she is owed
      `PURSUIT_REACTION` from the moment it can touch her whatever she did to get there. The next
      person to touch this should state the notice **over the walk** and assert it with a rig, and
      the two ways to widen it both cost something: a narrower stand-off spends the reaction window
      at the lunge, and there is no more screen
- [ ] **And the cool-off is played, not re-derived** — finding 6. `Tuning.PURSUIT_SHAKEN_OFF` landed
      in M39, after this report was taken: 0.8s of the gap opening, and the measured price of the
      answer went from ~35 points to **12**. If it still reads as slow it is one constant

      **Played, and it is not one constant — it is the wrong quantity.** *(Playtest 13, finding 6:
      "the dog doesn't stop fast enough on day 3 — we talked about this! when running the pursuit
      should stop quickly — it **only** should keep going if the player doesn't run.")* Two chases
      in the trace lasted **5.4s**, nearly twice `PURSUIT_TIME`, while she was running for most of
      them; the first turned a meter reading 9 into a meter reading 95 and ended the day.

      | day | chase lasted | she ran | it cost |
      |---|---:|---:|---|
      | 3, attempt 1 | **5.4s** | 3.2s | exc 9 → 95, lost the day |
      | 3, attempt 4 | **5.4s** | 2.1s | exc 16 → 66 |

      The cause is that `_outrun_for` needs **0.8 continuous seconds** of the gap opening and any
      frame that does not open it resets the timer to zero. A real player does not hold a key down
      for a clean 0.8s: she ran in four separate bursts — 1.2s, 0.5s, 1.4s, 0.4s — and every gap
      between them put the counter back. Worse, the first `(WALK_SPEED + RUN_SPEED) / ACCELERATION`
      of every burst is spent turning round, during which the gap is still **closing**, so a 1.2s
      burst can contain well under 0.8s of opening.

      **So the break-off condition becomes *she is running away from it*, read directly.** M39's
      rate framing was the right fix for a different complaint and its guarantee still holds —
      *only running can open the gap*, so walking cannot fake it — but it buys that guarantee by
      measuring the **consequence** of running rather than running itself, and the consequence is
      polluted by acceleration, by diagonals and by a player who lets go of shift. Reading the
      state gives the same guarantee with none of the noise, and makes the player's sentence true.

      Two things must not be lost with it, both already written down: the chase may not end before
      it has been a threat (`PURSUIT_MIN_NOTICE` is the floor), and **walking away must never work
      at any distance** — the M36 trap, where a trigger sitting at the break-off distance let a rig
      stroll away from a robber every time
- [ ] **The tutorial dog is not a tutorial after day 3** — playtest 13, finding 8, *"I had a
      tutorial pursuing dog on day 4 — that should not happen"*. `charging_dog` is `first_day 3`
      with `spawn_mode = AHEAD_OF_PLAYER` and no last day, so the scheduler goes on placing it
      (three on day 4 of the trace) and the director goes on siting it in front of her, in the
      identical presentation to the day-3 lesson: `ahead charging_dog comes at her from 200px in
      front of her`. `_ensure_the_run_is_taught()` is correctly gated to `RUN_TAUGHT_DAY`; the row
      underneath it is gated to nothing.

      **Decided: it recurs, but is not sited ahead of her.** `AHEAD_OF_PLAYER` is for *"the small
      number whose entire content is the moment it happens to you"*, and after day 3 that is
      exactly what a charging dog stops being — the lesson is over and the row becomes a hazard
      with a place. `alley_robbery` is the shape: `pursues_within`, a thing that is *somewhere*,
      that can be seen and priced and routed around, and that becomes a chase if she walks up to
      it. Two constraints: a `MAP`-placed pursuer needs a `pursues_within` or it can never trigger
      at all, and `validate_pursuit`'s third clause puts that trigger inside `PURSUIT_BREAK_OFF`;
      and **day 3 keeps the placement it has**, because the lesson depends on being unavoidable
- [ ] **Dying at high excitement on a quiet street** — finding 8, and read the trace before touching
      anything.

      **Playtest 13's trace is that read, and the answer is the first of the three suspects: this
      finding *is* the crowd milestone.** The losing line is
      `lost_crying after 29.4s … exc 100, in 24.6/s (crowd 24.6, events 0.0)`, with the nearest
      catalogue row 272px away and out of range — playtest 10's own shape, one milestone later. It
      is **M46**, and this entry closes into it rather than being answered here. The other two
      suspects stay open and are cheap to check while M46 is being measured: whether the pram's
      `EXCITEMENT_NEARLY_CRYING` cue is shown and not read, and whether one contact at 90 is a
      cliff — at 22–34 points a second a single bump above ~89 ends the day on an empty street, and
      the trace has fifteen bumps in four days.

      What the entry said before the read, kept because the reasoning still holds and is now
      M46's: the strongest suspect is the **recovery**, and it is a rule taken on purpose —
      `EXCITEMENT_DECAY_IDLE` is 0.0, so above the calm threshold the only way down is walking
      somewhere quieter at 3.5/s — on a quiet street the meter sits where it is and any small source
      is a net climb with no floor under it. Three things to measure first: what the `lost` line's own
      `crowd X, events Y` breakdown says (if it reads like playtest 10's, this finding *is* the crowd
      milestone); whether the pram's `EXCITEMENT_NEARLY_CRYING` cue is being shown and not read; and
      whether **one contact at 90 is a cliff** — a pedestrian contact is ~10.8 points, so above 89 a
      single bump on an empty street ends the day. The first of the three is what the trace
      answered
- [x] **The diagonal zzz comes back down** — finding 9. `baby_cue_lift()` caught the diagonals
      because both cues asked *which axis is she mostly facing*, and that answer puts a diagonal on
      the vertical side of the line. It is one question now — `Stroller._pram_shares_her_column()`
      — and it is asked as **geometry**: `pram_offset` carries `facing.x` at full `PRAM_DISTANCE`,
      so the pram is 24px to one side on a diagonal and 34 on a due east or west, and only a due
      north or south leaves it in her column. That is six of the eight facings both cues have
      nothing to do on, where the axis test said four.

      It is a distance rather than `absf(facing.x) > absf(facing.y)` for a second reason worth
      keeping: `_turn_toward` rotates by an angle and normalises, so on a diagonal the two
      components are equal only to within float noise, and a strict comparison between them would
      have let the cue flicker between two positions while she walked in a straight line. This cue
      has been adjusted in M32, M37, M39 and now M43, and each of the last three was a facing the
      previous fix had not been asked about — so `tests/test_danger.gd` holds **all eight** now

### The two decisions this milestone could not take on its own

Both were taken in the session, and the first of them turned into a milestone of its own.

**~~What a closure is for.~~ Taken, and it is M45.** The measurement said no filter, margin or run
length can make a single closed street change a route, and the answer to that is not a better
closure — it is that *lengthening the route was never the job*. See **M45**.

**~~What notice a lethal thing owes when you walk into it.~~ Taken: site it at the screen edge.**
`SIGHT_AHEAD` rather than the 184px clamp, which buys 0.38s → 0.43s and is everything the geometry
has. The floor was deliberately left where it is; see the entry above for what that leaves open,
and the standing instruction that comes with it — a notice has to be **stated over the walk** and
asserted by a rig, or it will go on passing while the encounter changes underneath it.
