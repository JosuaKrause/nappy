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
  (`EventManager.the_instance_behind()`): on a hard fail, the instance that struck her, which
  `check_hard_fails()` remembers beside the name it logs (`_striker`, reset with `_struck_by` when a
  day begins), and nothing once that instance is gone; on a crying day, the live instance of that
  name with the largest landed share of its own, the share `_landed_by_group()` sums, never the
  nearest. `LossCause.names_one_thing()` says which causes are one thing (a car, a row) and which
  are not (`crowd`, `traffic`, `self`).
- **`LossHold`** (`src/day/loss_hold.gd`): the world stops on the frame of the loss, a camera of its
  own eases from her view to the framing of her and the cause together (zoomed out to fit, never
  past half of her zoom, and always keeping her inside the margin), holds, and the summary comes up;
  a tap or a key skips it. `EASE_SECONDS` (0.7) and `HOLD_SECONDS` (1.5) are constants on the class,
  not `Tuning` numbers. `Main._show_the_day_over()` runs it between the end-of-day save and the
  outcome screen, so closing the game inside the beat takes no spent nerve back.

## Picks, each open to the player's overturn

1. **The framing is the only mark** (the design's pick, from its review's finding 9): nothing is
   drawn for the cause, and the frozen frame is neither given a cue nor stripped of one. The bursts
   in `docs/evidence/grassy-beaver-loss-shown-2026-11-26/` (a car strike, a cyclist's hard fail, a
   crying loss to the cafe tables) are for the player to judge whether the framing alone reads; if
   it does not, a mark of its own goes to the board as a cues decision. In all three the cause
   stands on her or right beside her, so the camera barely moves and the framing is almost her own
   view: there, the framing alone hardly marks the cause, since other things stand as close in the
   same frame.
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
- **The camera goes back to hers when the beat ends, under the summary, with no ease back**, open
  to the player's overturn. Every continue after a lost day leaves the frozen frame: the day is
  tried again from its morning at her doorstep, a section from its own start, or the run goes to its
  checkpoint, so the camera is set on her anew in every case. An ease back to where she fell would
  ease toward a view the continue throws away. The cut happens under the summary's dim
  (`Color(0.04, 0.04, 0.06, 0.86)` in `scenes/ui/day_summary.tscn`), so it is faintly visible on the
  frame the summary appears; the review item asks the player whether it reads as a jump. Keeping
  the framing until the summary is dismissed is the other way, with a hand-back in
  `_on_summary_continued()`.

## Found in review, and fixed

- **Focus loss inside the beat.** `_pause_on_focus_lost()` opened the pause screen over the beat.
  The world stayed paused, since the pause screen puts back the paused state it found, but the beat
  ran on behind it, on `Main`'s always-processing clock, and as `Main`'s newest child it took the
  first press meant for the pause, so the player could come back to a summary without having seen
  the cause. `Main` now keeps the running hold (`_loss_hold`), and focus loss opens no pause while
  `LossHold.is_running()`, as it opens none over the summary.
- **The striker remembered.** The first version found the striking instance again in
  `the_instance_behind()` by asking `is_lethal_at()` a second time, which could frame another
  instance of the row once the striker no longer passed it. `check_hard_fails()` now keeps it.
- **The suites skip the beat.** Every suite that loses a day and then presses continue met the
  beat first, which takes any press as its skip, so its presses fell one behind. On the run-log
  baseline that dropped the crying loss and the dusk loss onto a summary already up, which is why
  the log read the yeller's hard fail on line 21 and was 57 lines against 77; it is not a game
  defect, and the baseline is not re-recorded. A shared helper, `Boot.skip_the_loss_beat()` in
  `tests/booted_main.gd`, pushes a press and its release through the viewport while a hold runs,
  as a player would, and every such suite calls it after each loss.

## What is verified, and what is not

The suites hold the framing geometry, the beat's timing, skip and hand-back of the view, the cause's
place (the striker while it stands, else the instance that landed most, not the nearest), the car
named in the call that ends the day, and in `test_main` the order: a lost day shows the beat with
no summary, focus loss opens no pause, and the summary comes up when the beat runs out, while a
timeout or a win raises it at once.

The three bursts show the beat running on a real day for each kind of loss and the camera barely
moving when the cause stands beside her. They cannot show the beat at full speed (the rig ran at 9
to 14 fps on the cyclist's run), a cause farther off, where the framing zooms out, or whether the
framing alone singles the cause out to a player; that is the player's eye. A burst cannot span the
loss, since `Telemetry.end_day()` cancels a running burst when the day ends, so each starts just
after it, inside the ease.
