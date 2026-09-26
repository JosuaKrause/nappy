## M46 — The crowd is not the game · `feature/the-crowd-is-not-the-game`

**Done.** Playtest 13's finding 1 — *"just walking around now increases excitement — this is
bad"* — which is playtest 07's finding 17 and playtest 10's *"the thing nobody reported"*, found
for the third time and said out loud for the first. See
**[docs/playtests/PLAYTEST-13.md](../playtests/PLAYTEST-13.md)**.

**What it came to, in one paragraph.** Almost every item was answered by measuring rather than by
arguing, and four of them came back the opposite of what the item predicted. The crowd was not too
loud: an ordinary footway is **net recovery to walk**, and what is expensive is **standing**, which
is `EXCITEMENT_DECAY_IDLE` being 0 and stays that way for two measured reasons. The careful line was
not gone, it was **four pixels wide** — widened to twenty by moving the pavement's lanes apart, not
by shrinking the body — and that closed the separate problem that contacts and noise had been
pricing the same choice in opposite directions. The main road was quiet because a weighting could
not cross a split something upstream had already made, and it is a soft block now at about a third
of the meter to cross. And the green wave, which the docs had said served both directions since M41,
**serves one and arithmetically cannot serve two**. The population was honest, the box was not, and
the cost table did not move at all.

**The one sentence: the crowd is supplying almost all of the difficulty, and every authored system
in the game is being judged through it.** A day was lost in 29.4s reading `crowd 24.6, events
0.0`, with the nearest catalogue row out of range; the freeze threshold is reached within ten
seconds of the doorstep on **all five** attempts that got that far; and standing still for three
seconds on an ordinary pavement is worth eight points.

**What this must not become.** The noise floor is emergent, never a constant — that is an
invariant and it stays. *"The crowd is expensive to be careless in and free to be careful in"* is
the ratio the whole design rests on, and the finding is that **the careful line has stopped
existing**, not that the crowd is loud. M33 already measured the line away (eleven contacts down a
lane centre against one on the midline became thirteen against fifteen) and answered with a
behaviour — people step aside. Fifteen contacts in four days says the behaviour is not carrying it.

- [x] **Measure before touching anything, and measure the four things separately.** Playtest 04's
      recipe, re-run on `main`: contacts in forty seconds walked down a lane centre *against*
      forty seconds holding the midline, the mean crowd contribution at a standing point on
      ordinary / precinct / main-road pavement over a real minute, and the share of a losing day's
      excitement that came from the crowd. The ratio is the finding, not either number

      **Measured, and one of the four came back the opposite of what was feared.** Five seeds,
      act I, focused on the point being measured:

      | | value | against a 3.5/s walking decay |
      |---|---:|---|
      | ordinary corridors, standing | mean **5.82**, median 5.62 | **44 of 55 beat the decay** |
      | main road, standing | mean 11.90 | all five |
      | precinct, standing | 5.75 | net +0.50 after its 1.5x ground |
      | contacts, 40s down a lane centre | **73** | |
      | contacts, 40s on the midline | **5** | |

      So a typical ordinary street is **+2.1/s while walking and +5.8/s while standing** — 100
      points in 48 seconds of pavement with nothing authored anywhere near her, which is finding 1
      exactly. But **the careful line is not gone**: 73 against 5 is a ratio of **14.6:1**, better
      than the 11:1 M19 built the crowd on. `CLAUDE.md` has said since M33 that the ratio was
      measured away (13 against 15) and it is wrong — M41's crowd changes brought it back and
      nobody re-measured. **The finding is that the careful line is invisible, not that it is
      absent**: nothing tells a player that walking sixteen pixels to one side costs fourteen times
      less
- [x] **And the one test pinning the floor was measuring an empty street.** Found while measuring
      the above, and it is M44's lesson in the place it does the most damage.
      `_test_a_busy_street_never_lets_the_meter_fall` called `start_day(1, rng)` with **no focus**,
      which parks the crowd field on the map centre, and then measured at `quietest_pavement` —
      whichever north-south corridor the city made quietest, **1968px from that centre on seed
      4242**. Measured: **zero agents within 400px.** So *"a back street is somewhere she can
      recover"* was 0.00 against a decay of 3.50, and *"the arterial is a different place"* was
      7.58 against 0.00. **Three of that test's four checks were passing against a road with
      nobody on it**, and the fourth — the ceiling — was passing only because focusing the field
      is what pushes the arterial from 7.58 to 11.55, which is already over it.

      The crowd is a population of the box around the player, so **a floor is only a floor where
      she is standing**. `_floor_on()` focuses it
- [x] **The main road is the quietest thing in the city, and it is two defects** — finding 7's
      first half, done. `CrowdLanes.busyness` still weighted the middle corridor of *each* axis at
      `ARTERIAL_BUSYNESS` while `CityMap.main_road` is one vertical corridor, so the phantom
      east-west arterial held **14.6 cars against the spine's 11.2**. And underneath it,
      `_choose_lane` picked the axis 50/50 **before** the corridor, so no weight could ever put
      more than half the traffic on one north-south street.

      Both fixed: the spine holds **15.4 cars** and crossing it costs **~35 of the 100 meter**,
      worst of eight crossings — which is finding 7's *second* half arriving for free, because a
      third of the meter to cross is precisely the **soft block** that was asked for.

      Three things came with it. `CROWD_CARS_PER_ACT` went **40 → 34** (act II 30 → 26), because
      the concentrated spine put junction contention over the rate `test_crowd` allows: the car
      number is a capacity number now, and the honest answer to *"the main road is too quiet"* was
      fewer cars for the second time. The arterial ceiling is **stated over the crossing** rather
      than over the standing floor — a proxy that came apart the moment the spine got its traffic,
      and M35's *state it over the walk* arriving in the crowd's half of the game. And a car handed
      a corridor whose visible stretch is all precinct re-rolled its position eight times, found
      bollards every time, and was placed among them anyway: **a retry is not a guarantee, one
      scale out**, so `CrowdAgent.setup` re-picks the street rather than only the spot on it
- [x] **`EXCITEMENT_DECAY_IDLE` is 0.0 and there is no floor under her on ordinary ground.** M33
      set it there for a good reason — *what settles a baby is being pushed* — and the consequence
      nobody priced is that a stationary pram on a pavement is a pure climb at whatever the crowd
      is doing. Decide whether "standing still settles nothing" should mean "standing still is
      worse than walking", which is what it currently means.

      **Decided: it stays 0.0, and the question was pointing at the wrong number.** Two measured
      reasons, and the second is the one that was nearly missed.

      **It is not the lever for the case that matters.** The place the game *makes* her stand
      still is the kerb of the main road, waiting for the side street's green — and main-road
      ground is `EXCITEMENT_DECAY_MAIN_ROAD_MULTIPLIER`, 0.6. So even handing idle the whole
      walking rate would give back 2.1/s of a 5.9/s bill. The number that decides what a wait
      costs is the crowd's, not the decay's.

      **And removing the zero re-opens what it was built to close, by a route that is easy to
      miss.** Sleepiness is **frozen, not drained**, above `EXCITEMENT_CALM_THRESHOLD` — see
      `Baby._update_sleepiness` — and that is exactly the state somebody would stop in. So above
      the threshold standing still already costs nothing on the other meter, and any non-zero
      idle decay makes waiting it out strictly better than walking on every ground quieter than
      the decay: every back street and every park. `SLEEPINESS_DRAIN_IDLE` looks like the guard
      and is not, because it is switched off precisely when the exploit would be used.

      *Standing still is worse than walking* is the right sentence for a game whose only verb is
      *where do I walk*. What it must not be is the game's answer to something the game made her
      do, which is the next item
- [x] **Waiting for the main road's light costs a third of the meter, and up to all of it.**
      Found by measuring the item above rather than arguing it. Twenty arrivals spread across the
      cycle, at a signalled junction on the spine, five seeds:

      | | value |
      |---|---:|
      | cycle | 17.1s = 8.1 main green + 2.0 amber + **5.0 side green** + 2.0 amber |
      | mean wait for the crossing arm | **5.7s** |
      | worst wait | **12.0s** |
      | mean cost of the wait | **33.4** of a 100 meter |
      | worst cost of the wait | **133.0** |

      So obeying the light is worth a third of the day's tolerance on average and can end the day
      by itself, and this is *before* the crossing, which the item above measured at up to 35
      more. That is not a soft block, it is a toll gate with a queue, and she has no choice about
      any of it: `Tuning.validate_signals` guarantees she can only cross on the side green.

      **And the diagnosis it was written with is wrong, which the measuring found and the
      arguing did not.** The suspect was *what she is standing next to*: a queue held at the stop
      line is worth what the same cars are worth streaming past, because `contribution_at` never
      looks at how fast a car is going. But **she waits while the main road has green**. The
      traffic beside her is moving by construction, and the queue is on the side street she is
      not standing on.

      **What is actually expensive is standing, and it is not specially expensive here.** The
      spine's junction kerb reads **5.9/s** during a wait — an ordinary pavement reads 4.5–5.1.
      So this is the item above's other half arriving with a bill: `EXCITEMENT_DECAY_IDLE` is 0,
      any six-second stop anywhere costs a quarter of the meter, and the spine is the one place
      the game *makes* her take one.

      Three candidates, all measured, all rejected, because two of them buy the wait with the
      thing finding 7 just fixed and the third buys it with the road itself:

      | | wait | worst | arterial floor | jaywalk | spine stopped |
      |---|---:|---:|---:|---:|---:|
      | today | 33.9 | 133.0 | 11.98 | 26.1 | 41% |
      | a stopped car idles at 0.35 | 32.9 | 122.6 | **8.55** | **11.0** | 41% |
      | `CAR_OUTER_RADIUS` 104 → 64 | 23.2 | — | **7.62** | **11.0** | 41% |
      | side green 5.0 → 8.0 | **15.3** | **56.3** | 11.98 | 26.1 | **63%** |

      - **The idling fraction does nothing for the wait** — 33.9 to 32.9 — for the reason above,
        and its real effect is to halve the arterial floor and the cost of jaywalking. That is
        M41's *"a car waiting at a light beside you is louder for longer than one going past"*
        answered at last, and it turns out to be an answer to a different question.
      - **A narrower car field does not make a careful line**, which is the surprise. The profile
        across an ordinary footway stays flat at every radius tried — 3.31 / 3.74 / 3.39 at 64 —
        because **the flatness is the pedestrians**, who are 3.3 of the 4.5 and whose spacing is
        arithmetic no radius can change. All it buys is the same halving of the spine.
      - **A longer side green works and the road pays for it.** It halves the wait and the worst
        case, and it takes the spine from two fifths stopped to two thirds.

      So the mean is left alone on purpose: **33 points to cross the spine is the soft block
      finding 7 asked for**, and every lever that lowers it lowers the crossing with it. What is
      wrong is the *worst* case — 133 for one unlucky arrival, which she cannot see coming — and
      the thing underneath it is the next item
- [x] **The main road is two fifths stopped, and that is where its noise comes from.** Measured
      while pricing the wait, over three seeds and thirty seconds of act I: the cars on the spine
      average **49 px/s of a 158 cruise, with 41% of them stationary**. `CLAUDE.md` says to
      measure exactly this alongside the floor *"or a road that reads as busy in a screenshot is
      a car park in motion"*, and nobody had.

      **The diagnosis this item was written with is wrong, and measuring it found a five-milestone
      error in the design record.** It is worth reading as an example of how confident a wrong
      cause can sound: the drift argument below is arithmetically correct and explains nothing.

      **The speed spread is real and is not the mechanism.** `CAR_SPEED` is 130–185 against a wave
      tuned for 157.5, so a slow car does drift 0.6s per junction. But it needs **13 junctions** to
      drift out of an 8.07s green band and a car lives **3.8 junctions** on the spine before it
      recycles — and measured over three seeds, the **fast** half stopped more often than the slow
      half (4.25 against 3.00, 4.29 against 3.00, 2.44 against 2.38). Both proposed shapes — a car
      holding the progression speed, a narrower range on the spine — treat the drift, so both were
      dropped.

      **What is actually wrong is that the wave only ever served one direction.** M41's note said
      both did, "because the cycle is an even multiple of the junction-to-junction travelling
      time", and that is the condition upside down. With offsets `j·travel`, a car passing
      junctions `j0 + d·h` at `t0 + h·travel` sees phase `t0 + j0·travel + h·travel·(1 + d)`: going
      *with* the wave the `h` term vanishes and the phase never moves, going *against* it the phase
      advances `2·travel` per junction, which is constant only if the cycle **divides** `2·travel`
      — true at `blocks = 1` and nowhere else. Measured on the signals alone with no traffic in
      them, twenty departures spread across a cycle:

      | | arrivals meeting a green |
      |---|---:|
      | with the wave | **93%** |
      | against it | **51%** |

      and 51% is the main green's share of the cycle, which is to say chance. `tests/test_crowd.gd`
      had asserted `cycle / travel` is an even multiple since M41 — **true, and not the property
      the sentence beside it claimed**, so it pinned nothing. It walks a car down the platoon now.

      **It cannot be fixed, and that is a fact about the geometry rather than a setting.** A
      two-way wave needs `cycle = 2·travel` = 5.7s; the side green plus its two ambers is 9.0s
      before the main road gets a second, and widening `travel` instead means a spine cruise under
      100px/s, barely above a walk. No offset does better on average either: `θ = travel` buys one
      direction a perfect run and leaves the other at chance (72% overall), while the
      symmetric-looking `θ = cycle/2` puts **both** directions on a three-phase sweep at 47% each.
      The asymmetry is the good answer, not a compromise.

      **So the light is the floor and density is what sits on top of it.** Dropping
      `CROWD_CARS_PER_ACT[0]` to 12 for one probe — a third of the traffic — took the spine to 79
      px/s and 33% stopped, so density is worth about ten points and more than half the stops, and
      the irreducible remainder is the main arm being red 53% of the cycle. The cars stay: the same
      probe took the arterial floor 9.95 → 7.40 and the crossing 29.7 → 19.0, which is finding 7
      undone to answer finding 1.

      **What did move it is a snapshot being read as a fact.** `Crowd._can_clear_the_box` compared
      a static `gap_ahead` against the room a car needs beyond a junction, so a car queued behind a
      leader that was *already accelerating away* refused to enter, stopped, and made the jam the
      rule exists to prevent. Crediting the leader's speed for one `CAR_HEADWAY_TIME` — the horizon
      the car-following rule already trusts it for — is the whole change:

      | | before | after |
      |---|---:|---:|
      | mean speed on the spine | 44.6 px/s | **53.6** |
      | stationary at any instant | 43% | **39%** |
      | stops per car per life | 3.28 | **2.05** |
      | junctions crossed per life | 3.9 | **4.1** |
      | arterial floor | 9.95–13.17 | 9.17–11.09 |
      | worst crossing of the spine | 29.7 | **30.2** |

      So the road moves half again as fast for a third fewer stops, and the two numbers the
      previous items fought for — the floor and the ~33 points to cross — do not move. The noise
      floor did not have to be bought back with `CROWD_CARS_PER_ACT`, which the item expected it
      would.

      **The half that had to be walked back is the instructive one.** Crediting the leader's speed
      *unconditionally* put **238 overlapping crossing-axis pairs in 3,600 frames** against a
      tolerance of 180 — `tests/test_crowd.gd` caught it on the first run — because it let a car
      follow its leader straight *into* the box. The credit is only sound once the leader is past
      the far side, where its speed answers "will the last 66px have opened up by the time I get
      there", a question about road this car is not yet on. **Ask what the number you are
      crediting is a fact about**: a leader inside the box is the obstacle, not evidence about the
      road beyond it
- [x] **A contact is 22–34 points a second and there were fifteen of them in four days.** Either
      the cost or the frequency is wrong and the trace cannot say which. `BUMP_RADIUS` is 14 and
      the M33 note says the careful line was two pixels wide when M19 measured it — so widening
      the *street* rather than narrowing the *body* may be the honest answer, and that is a
      question for `CrowdLanes.SIDEWALK_OFFSETS` and `_make_way`

      **Neither is wrong, and the question was asking about the wrong axis: what is wrong is the
      *place*.** Measured over three seeds, forty-second walks, with the whole frame run — the
      crowd stepped **and** the player half of `Crowd._physics_process`, so `_make_way` is in it:

      | | value |
      |---|---:|
      | one contact | **10.8 points** — 18.0/s fading linearly over 1.2s |
      | contacts, 40s down an **ordinary** footway | 2.7, whichever line is taken |
      | contacts, 40s down an **arterial** lane centre | **15.3** |
      | the same, on the arterial midline | **0.0** |

      **The cost is right.** 10.8 is a tenth of the meter, and `tests/test_crowd.gd` already pins
      the shape it has to keep — one is survivable, four freeze the meter, ten lose the day. The
      *22–34 points a second* in the trace is the instantaneous rate with the field underneath it,
      not what a contact costs.

      **The frequency is right too, and an ordinary street turned out not to be the problem at
      all.** Every line across an ordinary footway is **net recovery** while walking: the crowd
      charges 55–87 points over forty seconds and the walking decay pays back 140, so the net runs
      −53 to −85 at every offset from the frontage to the kerb. That is worth holding against the
      standing numbers three items up — 5.82/s on the same ground — because the gap between them is
      the whole of `EXCITEMENT_DECAY_IDLE` being 0 and of `_make_way` only running for somebody who
      is moving. **Walking an ordinary pavement is free; standing on one is not.**

      **So the contact question is an arterial question, and there the careful line was four pixels
      wide.** A contact fires inside `BUMP_RADIUS` of a lane centre, the lanes sat a tile apart, and
      `TILE_SIZE − 2 × BUMP_RADIUS` is 32 − 28 = **4**. That is not a line a player can aim at, it
      is one she is occasionally on — with **165 points of a hundred** riding on it, which is the
      M46 headline (*the careful line is invisible*) arriving with a number and a cause.

      **Fixed by widening the street, which is what the item guessed and is the honest direction.**
      `CrowdLanes.SIDEWALK_LANE_SPREAD` pushes the two lanes of a footway 8px apart toward its own
      edges, so the clear line goes **4px → 20px** while the lanes stay 8px inside the pavement.
      Nothing about a contact changed: `BUMP_RADIUS` is what makes one mean *walking into
      somebody*, and narrowing it would have bought the same line by making a contact require a
      near-perfect overlap.

      | | before | after |
      |---|---:|---:|
      | clear line between two lanes | 4px | **20px** |
      | arterial lane centre, 40s | 13.7 contacts | 15.3 |
      | arterial midline, 40s | 0.0 | **0.0** |
      | field over 40s at an ordinary midline | 74 | **56** |

      Two things came with it. The careless line stayed careless, which it had to — the crowd is
      only a decision if walking down the middle of it still costs. And the field got **quieter in
      the middle of the pavement** as well, because the walkers are further from it, so for the
      first time the two halves of the crowd want the *same* line: the item below found them
      wanting opposite ones, and that is what this closes. `tests/test_crowd.gd` holds the band
      against `PLAYER_BODY_RADIUS` — it has to be aimable, not merely non-empty — and holds the
      spread under half a tile, because `CrowdAgent._pavement_band` measures the footway from the
      **tile** centres and nothing else in the suite would notice somebody walking in a shopfront.

      Open, and it is the half a geometry change cannot reach: **nothing yet says the channel is
      there.** It is now wide enough to find by walking down the middle of a pavement, which is
      what most people do — but that is a claim about a player and no rig can settle it
- [x] **`CROWD_PEDESTRIANS_PER_ACT[0]` is 200 and it is a population of the field, not the city.**
      It has not been re-measured since the field's box last moved. Measure what is actually
      within a screen of her, not what the constant says.

      **Taken out of order, and on purpose: the two decisions above cannot be made until it is
      known whether the population is the lever.** It is not, and that is the finding.

      Measured over five seeds, act I, thirty seconds standing on each of eight corridors:

      | | value |
      |---|---:|
      | walkers in the box, every sample | **200.0** of 200 |
      | cars in the box, every sample | **34.0** of 34 |
      | walkers on a 1280×720 screen | **67.6** |
      | cars on a 1280×720 screen | **10.2** |
      | walkers within 200px of her | 9.4 |

      So **the constant is honest**: the box is 1600×1600 and never spills, the screen is 36% of
      it, and 34% of the population is on it. Nothing is hiding. And it must not come down —
      the same population is what put 15.4 cars on the spine and made crossing it cost a third
      of the meter two items ago, so cutting it undoes finding 7 to answer finding 1.

      **What the measurement actually found is where the floor comes from, and it is geometry
      rather than population.** The floor across a footway, same five seeds, in lane units —
      0 is against the frontage, 1 is the kerb:

      | | frontage 0.0 | midline 0.5 | kerb 1.0 |
      |---|---:|---:|---:|
      | mean over 20 ordinary standing points | **4.30** | **4.96** | **4.76** |

      **It is flat, and the midline — the careful line — is the loudest of the three.** Both
      halves fall out of arithmetic that nobody has re-checked since the corridor was last
      resized:

      - **A car's field is 208px across and a corridor is 192px.** Every tile of both footways
        is inside `CAR_OUTER_RADIUS` of a carriageway lane — the frontage lane is 64px from the
        nearer one. There is no line on an ordinary street that is out of the traffic's earshot,
        which is why the profile barely tilts.
      - **A walker's field is 110px across and a footway is 64px.** Lanes are 32px apart and
        `PEDESTRIAN_INNER_RADIUS` is 22, so the midline is 16px from two lane centres and inside
        the **full-intensity core** of both. `Tuning.PEDESTRIAN_INTENSITY`'s own comment says
        *"walking wide of them does not [cost] — the pavement is two tiles, so how close to pass
        is a real choice"*, and there is nowhere on a footway to be wide.

      This is the M46 headline finding — *the careful line is invisible* — arriving with a
      cause, and the cause is not that nothing tells her about it. **The careful line exists for
      contacts and does not exist for the field**, and the two want opposite lines: the midline
      is the only line with no head-on contact on it (`BUMP_RADIUS` 14 against a 16px half-lane)
      and it is the worst line for the ambient noise. A player who finds one has found the other
      one's punishment.

      **Closed by the contact item above, and by one change rather than two.**
      `CrowdLanes.SIDEWALK_LANE_SPREAD` moves the two lanes of a footway 48px apart, which widens
      the contact-free line from 4px to 20px **and** puts the midline 24px from each walker —
      outside `PEDESTRIAN_INNER_RADIUS` rather than inside it. The ordinary midline's field falls
      74 → 56 per forty seconds. The two halves of the crowd want the same line now
- [x] **The crowd bunches against the boundary wall, where the comment says it thins.** Found
      while measuring the above. `CrowdField.corridor_range` clamps to the city and says so:
      *"that is also why the crowd thins out honestly in the corner of the map instead of
      bunching against the wall — there are simply fewer streets to put anybody on"*. The
      population does not clamp with it, so fewer streets and the same two hundred people is
      **more people per street**, which is the opposite of what the comment claims.

      Measured, five seeds, walkers on screen against how much of the box is inside the city:

      | corridor | box in city | walkers on screen | mean floor |
      |---|---:|---:|---:|
      | 0 (against the west wall) | 53% | 67.0 | **7.50** |
      | 1 | 81% | **78.3** | 7.90 |
      | 3, 6, 8 (ordinary, mid-map) | 100% | 66–70 | 3.91–5.89 |
      | 5 (the spine) | 100% | 69.9 | 11.58 |
      | 11 (against the east wall) | 59% | 55.3 | 6.80 |

      **The count on screen is flat while the city on screen is halved**, so the density per
      street at the wall is about double and the outer corridors read as **1.6× an ordinary
      middle one** — loud enough that on two of five seeds a corridor beside the wall beat the
      main road.

      **Fixed on the box rather than on the population, which is what made it nine lines.** The
      first design was the obvious one — fewer agents live where there is less street — and it
      is the wrong one twice over: it needs a live count that varies, and a live count that
      varies has to sleep somebody, which is *"nothing vanishes while you are looking at it"*
      asking for a whole waking-and-sleeping protocol that only ever runs off-screen. Instead
      `CrowdField` **grows the box near the wall** until the amount of *city* in it is what a box
      mid-map holds: `contains`, `along_bounds` and `corridor_range` all read `radius`, so every
      one of them follows, and no agent is created, destroyed or hidden. Growing is always the
      safe direction — the only floor under `CROWD_FIELD_RADIUS` is that nothing may be seen to
      appear.

      Solved by iterating rather than in closed form, and that was a decision: the exact answer
      is a quadratic whose terms depend on which of the four sides are against a wall **and**
      which of them clip while it grows, which is four cases to get wrong. Scaling by the square
      root of the shortfall lands within a pixel in three passes.

      | | before | after |
      |---|---:|---:|
      | radius against the west wall | 800 | **1108** |
      | walkers per screen of city, at the wall | **105** | **64** |
      | the same, three blocks in | 58 | 58 |
      | mean floor, outer corridors (5 seeds) | 7.50 / 6.80 | **3.12 / 4.52** |

      So the wall now reads as an ordinary street rather than as a busy one, and the two
      corridors against it come in slightly *under* an ordinary middle corridor — an error in the
      safe direction, and the honest reason is that keeping the box's **area** constant does not
      keep its split between north-south and east-west street length constant. Held by
      `tests/test_crowd.gd`, "the crowd does not bunch against the wall", as two checks rather
      than one: the geometry, which is the mechanism and is free, and the density, which is what
      the player feels and is the half that could pass while the other fails
- [x] **Re-measure the whole cost table afterwards** — `docs/EVENTS.md`, "What an event actually
      costs" — because if the crowd's share moves, every authored row's share moves with it, and
      the table is the fastest way to see what a balance change did to the catalogue

      **Regenerated from `EventDef.walk_through_cost()` and compared row for row: identical, all
      thirty-one of them.** That is the result rather than the absence of one — it says M46 was a
      milestone about the *street* and not about the catalogue, and it is worth doing precisely
      because nothing would have told us otherwise. Nothing in the milestone touched an intensity,
      a radius, `Tuning.falloff` or a decay.

      What moved is the ground the rows stand on, and `docs/EVENTS.md` carries it above the table
      now: an ordinary footway is **net recovery** to walk (55–87 points of crowd over forty
      seconds against a decay paying back 140), the middle of a pavement went 74 → 56, and
      crossing the main road costs ~30 with ~33 more for the wait — between a `dog_walker` and a
      `loose_dog`, and neither is in the table because neither is an event
