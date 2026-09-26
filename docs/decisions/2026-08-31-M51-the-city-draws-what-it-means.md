## M51 — The city draws what it means · `feature/draws-what-it-means`

Playtest 15, in full in **[docs/playtests/PLAYTEST-15.md](../playtests/PLAYTEST-15.md)**. Seven findings, and they split
into three that are the city lying about its own rules, two about the frame around the game, one
art bug and one report the player is not certain of.

**Nothing here is a balance change**, which is worth saying up front: every one of them is a place
where what is drawn and what is true have come apart, and the fix is to make the drawing agree
rather than to move a number.

- [x] **A cul-de-sac stops the crowd too** — finding 1, *"cars and people go through
      cul-de-sacs"*. Dead ends are `absent_segments`, which every route search takes through
      `CityMap.blocked_segments()`; the crowd is the one thing that travels the lattice without
      asking. Be precise about what is being fixed: a car that drives *down* a dead end and turns
      round is right, a car that drives out of the end that was built over is not, and neither is
      one that never diverts because the street it is aiming at is gone from the graph but not
      from its own view of the map. `CrowdAgent._divert` and `CrowdLanes` are where to look, and
      M38's rule applies — *a placement is not a separation* — so a recycled car must not be
      **placed** on a street that is not there either

      **And the answer was none of the things above.** The crowd never needed `blocked_segments()`:
      a dead end is a street with its far end **built over**, so the tiles already say so, and
      `_blocked_ahead` already reads tiles. What it could not do was *see* the wall. It was a
      single probe fired seven tiles ahead — right for *is there something coming up*, and it looks
      straight **past** a two-tile plug into the open road behind it. An agent that entered the
      street from the junction beside the wall therefore never saw it at all. **M29's invariant
      exactly**, in the one scan it had not reached: *sampling a tile grid by stepping world points
      aliases, and it aliases where it matters.*

      Four things worth carrying:

      - **The rig had to stand in the right place before it could see anything.** The first probe
        built the crowd field at the doorstep and reported **zero** agents in a wall on three
        seeds. The crowd is a population of the box around the player, so a dead end the box never
        contains is a wall nothing was ever going to reach. Standing the field at a dead end gave
        850 / 2091 / 821 frames of 2400 with somebody inside one, and 8 at once. A clean
        measurement of the wrong place looks exactly like a clean build.
      - **Walking the tiles is *cheaper* than the probe, once it is cached by tile.** The answer
        depends on the agent's tile, its axis and its direction, over a map that is fixed for the
        day, and an agent covers a tile in about twenty frames — so seven lookups per tile beats
        one probe per frame. `test_crowd` went 48.7s → 42.4s and `test_balance` 37.9 → 27.2 while
        gaining a correctness fix. The intermediate version, which added the near check *beside*
        the probe rather than replacing both, cost +28%.
      - **A car that turns round changes lane.** `_direction = -_direction` on its own left it
        driving the wrong way down its own queue, and `space_out_the_traffic` then had to resolve
        a head-on overlap the only way it can — by moving a body. `_turn_round()` is the one place
        that now happens.
      - **And a test that had been true by luck for eleven milestones failed for a reason that had
        nothing to do with this.** *"No car is standing in a precinct"* asked `street_kind_at`
        about the **precinct's** axis, and a precinct span covers the junctions between its blocks
        — so a car crossing it on a north-south street is legal and was being counted. Sixteen do
        in the forty-five seconds that test runs; the assertion passed only because none of them
        was inside a junction on the frame it sampled, and a few frames of timing change broke it.
        It asks whether the car is on ground **no** axis lets it drive on now
- [x] **The main road has dotted lines, not a zebra** — finding 2, and the design half outranks
      the art half. *"The main road shouldn't have zebra crossings (since they have traffic
      lights) it should be two dotted lines demarking the pedestrian safe zone."* A zebra means
      *traffic gives way to you* and on the spine it does not — what stops the traffic is the
      light, which is `Tuning.validate_signals`' whole contract — so the paint has been
      contradicting the rule at every junction of the one street where getting it wrong ends the
      day. Four places have to agree, per `CLAUDE.md`'s street-hierarchy recipe: `GroundTiles`,
      `CityGenerator`'s tile choice, whatever `CrowdAgent`'s crossing scan reads (it walks
      **tiles** and looks for `CROSSING`, which is the M29 invariant — so a new tile type or a
      changed one has to keep that question answerable), and the traffic's give-way rule, which
      must **not** start giving way on the spine

      **Built, and three of those four places needed nothing.** The tile type is unchanged, which
      is the whole shape of the fix: M41 had already considered painting the crossing away and
      rejected it — *"a walker crossing a side street would then be standing on open carriageway,
      and the one thing a zebra is for is saying where a person on a road is meant to be"* — and
      the player is not asking for that either. They are asking for **different paint**. So
      `GroundTiles._crossing_variant` picks four new tiles when either corridor is the spine and
      every rule that reads `CROSSING` goes on meaning what it meant: the crossing scan, the
      give-way rule (which already exempted `MAIN`), and where an event may stand.

      The one thing that did have to move is the **trace**, which said *"at a zebra"* on a street
      that has none — a line that would send the next reader looking for the wrong bug, on the one
      street where the difference between a negotiation and a wait is the difference between a day
      and a day lost.

      Two dotted lines per crossing and two crossings per junction, so a spine crossroads has four
      dashed rows across it: the lines run the way she is crossing, one at each edge of the
      two-tile band, which is what `% SIDEWALK_WIDTH` is asking in that function. Photographed once
      and played by nobody
- [x] **The police car has a rear view** — finding 3, *"the police car only has a sideview even
      when driving vertically"*. An art gap in the crowd rather than in the catalogue

      **It is in the catalogue, not the crowd**, and it is three rows rather than one. The crowd's
      own cars have had an end-on view since M12 — `car_end_body.svg`, with the note that at that
      angle the front and the back of a car are the same shape — and every vehicle in the
      *catalogue* was one side-on sprite mirrored east and west. `police_patrol`, `fire_truck` and
      `military_convoy` are the three mobile ones, so all three got one: answering the complaint
      and leaving the other two would be this file's own warning about the border brief.

      Each keeps its **own** end-on picture rather than borrowing the crowd's generic car. That is
      M37's rule and it bites hardest here — the whole content of a vehicle row is *which* vehicle
      it is, and a police car that becomes a saloon the moment it turns north is the one silhouette
      the screen-edge badge exists to show, gone at the moment it starts coming towards her. The
      badge itself keeps the **side** view: an icon is read at 40px against a row of other icons,
      and a vehicle end-on is a box at any size
- [x] **Say GAME OVER on the game over screen, in big letters** — finding 5. *"In addition to
      everything else that is already there"*, so the ending text, the reason and the keys all
      stay; this adds a heading

      **It is not the same word for all three endings, and that is a decision rather than the
      request being trimmed.** The screen the complaint came off is the `BAD` one, where the nerves
      ran out, and `GAME OVER` is what that is; stamping it over a run somebody *won* would be
      telling them they lost. `THE END` is the same size, the same weight and the same job on the
      other two. Say so if that reads wrong — it is one line of a dictionary.

      **And a dev flag came with it, because there was no way to look at the thing being changed.**
      An ending is at the far end of fourteen days or five spent nerves, so `--ending
      bad|neutral|good` puts the last screen of a run on screen at boot. It is the same argument
      `--press` was built on: nothing in the suite or in a screenshot had ever reached that screen.
- [x] **Change the colour of the title on the title screen** — finding 6. `Palette.TITLE_TEXT`, a
      brighter version of the doorstep the screen is standing in front of. It was the same warm
      off-white as the line under it and the controls below that, so the screen was four labels in
      one colour and the name of the game was only the biggest of them. Deliberately **not** one of
      the danger colours, for the reason the signal lamps are not: a title in `MARK_COSTLY` is a
      game named after a warning
- [x] **A car on the bridge drives off the map instead of vanishing** — finding 7. This is M35's
      *"nothing vanishes while you are looking at it"* arriving at the crowd, which has never had
      it: `Crowd` recycles a car when it leaves the corridor box and the box is smaller than the
      map, so the three holes in the boundary — the bridge, the tunnel, the road out — are exactly
      where a recycle is visible. The rule to state is the events' one: past `Tuning.OUT_OF_SIGHT`
      before it is taken

      **Built, and the interesting half is who is *not* allowed to.** Outside the map is water,
      forest and mountainside — painted ground with no road on it — so letting every agent overrun
      the boundary would drive cars into the sea at every corridor. `City._paint_outside_the_map`
      lays carriageway out there at the spine's own width and nowhere else, and that is exactly the
      condition: a **car**, on the **main road**, going **north or south**. Everybody else keeps
      the tile of slack they had. `CrowdField.along_bounds` is clamped to the map, so the second
      thing that had to move is the box test — asking it about a car on the deck of the bridge
      recycles the car on the deck of the bridge
- [~] **Did the day counter reset mid-run?** — finding 4, and it is recorded with the player's own
      doubt: *"maybe I died fully without noticing."* Read it **with** finding 5 rather than
      instead of it — if a run can end and restart without the player noticing it has, that is the
      game-over screen's complaint arriving from the other side, and fixing the screen may be the
      whole of it. What to check first is whether the ending path can reach the title screen and
      begin a new run without the ending screen having been readable

      **Checked, and there is no path that resets the counter inside a run.** `GameState.day` moves
      in exactly two places: `finish_day` increments it on a win, and `start_run` sets it to 1.
      `start_run` is only reached through `_restart_run`, which **reloads the scene** — so a day
      counter that reads 1 again is a new run and nothing else. The player's own alternative is the
      only explanation the code allows.

      **Left half-open rather than closed, because that is not the same as saying nothing
      happened.** What it says is that the run ended, and *"I can swear the counter reset"* is then
      a report that the ending was unreadable — three screens deep, in the fiction's own voice,
      dismissed with the same key as everything else. Finding 5 is the fix and this is the evidence
      for it. Reopen it if the counter is ever seen to move with nerves still on the HUD
