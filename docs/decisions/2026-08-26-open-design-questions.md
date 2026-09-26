## Open design questions

These need a human playing the game, not more code.

- [x] **`_ensure_one_usable_park`'s early return defeated the rule written underneath it — and the
      fix was to stop repairing and start refusing.** *(Found in M50 while chasing a density floor
      that had nothing to do with hard blockers; answered by the player on 2026-08-31.)*

      The function collected, per calm area, the events whose fields reach it, and **returned as
      soon as any one area came out clean** — so playtest 14's stronger rule, *"every calm area she
      has not used this act stays clean, not just one of them"*, only ran on the days the older one
      had already failed. Measured over 64 planned days: the early return fires on 25–75% of them,
      and on a raw day **6.4 to 7.6 of the seven-to-nine unvisited areas are spoiled**. So the real
      promise was *one of the nine is clean and you cannot tell which*.

      Four ways to price that were measured and put to the player, and every one of them was the
      wrong question: *"why are 7-9 unvisited calm areas spoiled? Just don't place events there!"*
      The whole framing was a repair — plan the day, then delete what landed badly — where the rule
      belongs at **placement**. `EventScheduler._calm_to_leave_alone` is the fix and it is four
      lines: the calm ground of every area she has not settled in this act is refused to
      `_place_one`, and the events that would have gone there go somewhere else.

      It is better on both axes at once, which is why the options were worth throwing away. Every
      unvisited area is clean on **64 days of 64**, and the density went **up** rather than down,
      because the budget is no longer spent on events that were about to be deleted: day 1 goes
      118.4 → **124.6** placed and day 14 204.9 → **223.4**. `_ensure_one_usable_park` stays as the
      last line for the one case placement cannot answer — she has settled in every area there is,
      so nothing was protected — and `tests/test_events.gd` holds the new rule over a whole run.

      The shape to carry, because this project already has the rule and did not apply it here:
      **check before accepting rather than repairing afterwards.** `CLAUDE.md` says it about
      closures, and the argument is identical — a repair spends the budget twice, makes the day's
      density depend on how many placements happened to land badly, and leaves the guarantee
      running only when something else has already failed.

- [~] **Is the nerve economy right?** **Half answered by playtest 08: three was too few**, and the
      evidence is a run that ended on day 3 with two nerves spent on the same charging dog. It is
      five since M35. M32 had already changed the shape of the question rather than answering it — a
      lost day no longer advances the calendar, so a nerve is an *attempt* rather than a day thrown
      away — and what is still open is the other side of it: with five attempts and a retry costing
      only time, is a lost day a punishment at all? The run log's `nerve` entries say where they
      went, and also say which day is being played again. Note that five was **asked for, not
      derived**, and the thing that made three too few was a defect (the day-3 dog) rather than a
      difficulty: if act I now reads as fair, five may be generous.
- [~] **Is the balance right?** *(M14 pitched it against the day rather than against itself;
      M18 then re-pitched it against a **minute of play**: day 330s → 180s,
      `SLEEPINESS_GAIN_WALKING` 0.24 → 0.42, calm 3.5x → 10x, idle drain 0.6 → 1.0. A whole
      day of street walking reaches 76 of 100 and a calm stretch takes 24s.)* The open
      question is now the opposite one: with the meter this generous once calm ground is
      reached, is anything standing between the player and a won day? **Playtest 03 answered
      that with a trace: no.** Day 1 was won in 103.9s of 180 with zero `near` entries — the
      player crossed the city and came back without encountering a single event.
      **M19 put things there and the question is now whether it put too many.** A day-1 map
      carries 13 non-ambient events instead of 4, walking into somebody costs ~15.6 points, and
      the carriageway ends the day. A scripted walking probe says a quiet pavement is close to
      break-even on excitement and the arterial is not survivable to walk the length of — which
      is the intent, but "the arterial is for crossing" is a claim about a player, not about a
      probe. Needs a run and a trace, not more arithmetic.
- [ ] **Is 14 days the right run length?** Act I is only 3 days, which may be too little
      time to learn a city before it starts changing.
- [x] **How visible should the resistance be to a player ignoring it?** *Resolved by playtest
      02, decision 14: as visible as it is now — a chalk mark and one HUD line, no marker, no
      quest log.* The resistance is the difficulty dial (decision 10), and **wanting the dial
      and finding the dial are the same behaviour**: a player who wants to be challenged
      explores, and exploring is what finds a chalk mark on an alley wall. Carried open since
      M8; closed by leaving it alone. What *does* change is the key — see M26. The run log's
      `contact` entries record whether a player ever went near one, because "nobody ever finds
      it" would falsify the reasoning.
- [x] **Should running ever be *required* (a forced chase), or always purely a player
      choice?** *Answered by playtest 02, finding 9: yes, for some entities.* The measurement
      that came with it is the surprising part — running is currently the wrong move against
      **every** event in the catalogue, because `EXCITEMENT_FROM_RUNNING` plus the collapsed
      decay (3.5/s → 0.5/s) outweighs the shorter exposure every time. The run button is a
      trap. Making running necessary is therefore a mechanic to build (M25), not a number to
      change.
- [~] Should there be a diegetic-only mode — a baby's face instead of two bars? **Half answered
      by playtest 06, finding 5, and built in M32**: not instead of the bars and not a face, but
      *at the pram* — four states with an instruction each. What is still open is whether the
      bars could now be turned off entirely, which is a question for somebody playing with them
      hidden rather than for more code.
- [x] Does a lost day advancing the calendar feel right, or should it repeat the day?
      **Answered by playtest 06, finding 4, and built in M32: it repeats the day.** *"We
      shouldn't advance the day, that's for sure."* So a nerve buys a **retry of the same day** — the same city,
      the same closures, the same event plan, because all of those are deterministic from the
      seed and the day number — and the calendar only moves when a day is won. Nerves stop being
      a second currency and become three failed attempts spread over the run. Carried open since
      M6; closed by being asked out loud. See [PLAYTEST-06.md](../playtests/PLAYTEST-06.md) for what it does
      to the one-shots, the block arcs and the endings
