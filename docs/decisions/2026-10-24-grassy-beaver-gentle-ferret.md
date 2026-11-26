# grassy-beaver — The loss shown: a lost day holds on what caused it · 2026-11-26

The item the-loss-shown of the entry grassy-beaver (a day one that teaches): the player asked for
showing what causes a loss, show not tell (curly-moose #819). Built from the design's section for
the item.

## What was built

- **The cause is read where it is known, in the frame the day ends.** `DayDirector.finish_day()`
  asks for the one thing behind the loss and hands its place on in the `DayEnd`
  (`mark_to_show_its_cause()`, `mark_caused_at()`). A car strike asks the crowd, which names the car
  from `Crowd._strike()` (`Crowd.car_that_struck_her()`, set before the hard fail goes out, since
  the day ends inside that same call). A row's instance is asked of the events
  (`EventManager.the_instance_behind()`): the instance whose reach struck her, otherwise the one of
  that name with the largest landed share of its own, the share `_landed_by_group()` sums, never
  the nearest. `LossCause.names_one_thing()` says which causes are one thing (a car, a row) and which
  are not (`crowd`, `traffic`, `self`).
- **`LossHold`** (`src/day/loss_hold.gd`): the world stops on the frame of the loss, a camera of its
  own eases from her view to the framing of her and the cause together (zoomed out to fit, never
  past half of her zoom, and always keeping her inside the margin), holds, and the summary comes up;
  a tap or a key skips it. `EASE_SECONDS` (0.7) and `HOLD_SECONDS` (1.5) are constants on the class,
  not `Tuning` numbers. `Main._show_the_day_over()` runs it between the end-of-day save and the
  outcome screen, so closing the game inside the beat takes no spent nerve back.

## Picks, each open to the player's overturn

1. **The framing is the only mark** (the design's pick, from its review's finding 9): nothing is
   drawn for the cause, and the frozen frame is neither given a cue nor stripped of one. The pull
   request's burst of each kind of loss is for the player to judge whether the framing alone reads;
   if it does not, a mark of its own goes to the board as a cues decision.
2. **The crowd, the traffic as a group and her own running** have no one thing to frame: the beat
   still runs, on her, unzoomed, so every hard fail and every crying day gets the same pause.
3. **Every walk, the escape's sections included**: `_finish_the_section()` raises its lost screen
   through the same function.
4. **A beat of 1.5 seconds after a 0.7 second ease**; a timeout loses with no beat (its cause is the
   clock, which the summary already says).

## Where the code differs from the design

- The design places the hold between `day_finished` and the summary in `_on_day_finished()`. The save
  and the calendar's move sit before the summary there on purpose (a hard run's spent nerve is
  written before the screen), so the beat is held in a function beside it, `_show_the_day_over()`,
  called where the summary was. The section's lost screen is raised from `_finish_the_section()`,
  one call site outside the design's fence on `main.gd`, changed to the same function.
- `EventManager` gained one method and `Crowd` one method and one remembered car, as the fences
  allow; the director's `finish_day()` hands the position on in `DayEnd` (the design said "handing
  the cause on").
- The camera goes back to hers when the beat ends, under the summary, with no ease back.
  Keeping the framing until the summary is dismissed would need a hook in `_on_summary_continued()`,
  outside the fence.

## Not verified here

The suites hold the framing geometry, the beat's timing, skip and hand-back of the view, the cause's
place (the instance that landed most, not the nearest) and the car named in the call that ends the
day. What the framing looks like, and so whether it alone singles the cause out, is a burst of a
real day and the player's eye.
