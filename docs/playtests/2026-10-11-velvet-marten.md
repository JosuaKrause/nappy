# Playtest velvet-marten — Two phone frame records, and six notes from playing days 9 and 14

2026-10-11.
Said in one session as seven notes the assistant captured into the inbox on GitHub Issues, #696, #697,
#698, #699, #700, #701 and #703, while the player recorded two frame records on the phone for M159 (a slow
frame names the frame that was slow) and the assistant reported on them. Each note is recorded as it
holds: first what its words answered, then the words themselves, whole, and each later word after
what it answers. The questions and context are the assistant's; only the quoted lines are the
player's.

**The two records** are the released v0.27.1 page on the player's Android phone, opened with
`?debug=1&framerecord=1&seed=67&day=9` and then `&day=14`, at the assistant's suggestion (day 9 is
the first walled day, day 14 the densest). Both are kept,
unchanged, under [velvet-marten-phone-records-2026-10-11](../evidence/velvet-marten-phone-records-2026-10-11/README.md).

## #696

1. **What the note answered** (the assistant):

   Said while sending a phone frame record (v0.27.1, `?debug=1&framerecord=1&seed=67&day=9`) for M159, a slow frame names the frame that was slow. The agent had asked for recordings of day 9 (walled) and day 14 (densest) on seed 67. The lag spike matches the record's longest frame: process frame 7736, 205.9 s into day 9, 775 ms, 748 ms of it in the event updates.

2. **The note.**

   > the last attempt had a big lag spike. also, I noticed people still pile up in the pedestrian zone instaed of turning around at barriers. will do the other day next

## #697

1. **What the note answered** (the assistant):

   Said while recording phone frame records on v0.27.1 (seed 67, day 9) for M159, a slow frame names the frame that was slow. The gatehouse is the checkpoint door that lets her out while she stands still (downy-lark, #672).

2. **The note.**

   > another bug I noticed. with the gatehouses if I don't lift my finger during the move I don't expect the movement to get reset. so, only reset if I lift my finger. basically keep updating navigation

3. **The assistant asked:**

   Asked: the note covers a held finger. Should a key held on the keyboard through a gatehouse's release also keep her walking, or stay ignored until released or changed, as downy-lark ("leaving a gatehouse, she stands still") built it for every control mode? The agent proposed matching the keyboard to the finger.

4. **The player's words, answering it:**

   > Keyboard holding is the same as finger holding. If I don't lift it I expect it to remain active

## #698

1. **What the note answered** (the assistant):

   Said while recording phone frame records on v0.27.1 (seed 67, days 9 and 14) for M159, a slow frame names the frame that was slow.

2. **The note.**

   > Also I noticed the waiting charging dog needs a proper resting frame when in wait. It looks like it's flying

## #699

1. **What the note answered** (the assistant):

   Said right after #698 (the charging dog needs a resting frame while it waits; it looks like it's flying), while recording phone frame records on v0.27.1 for M159, a slow frame names the frame that was slow.

2. **The note.**

   > Also I'm general entities that charge towards the player when the player gets too close need three stages: neutral (with neutral visuals), warning (when the player gets close; needs to be visually distinct), and then the actual charging. Some already do this but not all

## #700

1. **What the note answered** (the assistant):

   Answering the M159 (a slow frame names the frame that was slow) investigation of two phone frame records (v0.27.1, seed 67, days 9 and 14). Two investigators reported. On drawing, the per-frame renderer cost grows with screen pixels; their ranked candidates were:
   (1) cap the device pixel ratio on mobile web (e.g. 1.5 instead of about 2.6, testable with a `?dpr=` page parameter; softer text), or turn hi-DPI off entirely;
   (2) on web, render the root viewport straight to the screen (`RenderingServer.viewport_set_render_direct_to_screen`, an engine setting), skipping one full-screen copy;
   (3) patch the pinned web template's `explicitSwapControl` (an engine patch);
   (4) draw entity shadows as a picture on an atlas page instead of `draw_colored_polygon`, which cannot be batched (about 40 draw calls);
   (5) stop the debug readout re-setting about 30 Label lines every frame (refresh a few times a second);
   (6) skip redraws that change nothing, including off-screen crowd agents, the home arrow, the edge badges and the meter bar.
   On game logic: (1) the 748 ms day-9 lag spike, which is poster-crew siting re-checking one tile 24 times for each of about 12 copies, fixed by checking each candidate once, with identical rng; (2) the crowd agents' per-frame update; (3) the checkpoint huts grouped by line; (4) cue early-outs; (5) skip the off-screen caret projection for events.
   The agent asked three decisions: whether to cap the pixel density and at what value (recommended: build `?dpr=` first and compare by eye); whether to carry an engine patch (recommended: hold off); and whether to add the window size and DPR to the frame record (recommended: yes, together with fixing analyse.py's crash on records without day 1).

2. **The note.**

   > We should draw shadows in pictures (move it into it's own atlas at build time). We will want better shadows anyway soon. The ellipse ones don't work well. Skipping redraws for of screen elements. Also we don't really change things with animation if it's of screen. If we have a bounding box that extends a little bit into of screen then it won't be noticable. We need to more resolution of the debug readout, yes. I wouldn't go to hack the engine just yet. We can try the direct to screen first (if it's an in engine setting), then the internal multiplier

3. **The assistant asked:**

   Read back: "We need to more resolution of the debug readout, yes" could mean (A) add the window size and device pixel ratio to the frame record (and show them on the readout), or (B) refresh the debug readout less often instead of re-setting about 30 Label lines every frame. Options: "Both (Recommended)", "A: record the resolution", "B: refresh less often".

4. **The player's words, answering it:**

   > Both (Recommended)

5. **The assistant asked:**

   Asked how to start. Options: "Start 2 + file all (Recommended)": spawn the two fixes already covered by M159 now (the day-9 lag spike, by checking each siting candidate once instead of 24 times with identical results; and the crowd speedups plus grouping checkpoint huts by line, from its 'make the physics tick cheaper' item), and file inbox notes #696-#700 in one filing PR while they run. "Start 2 + file #700 only". "Only start the 2 fixes".

6. **The player's words, answering it:**

   > Start 2 + file all (Recommended)

## #701

1. **What the note answered** (the assistant):

   Said after the agent reported the cause of the 748 ms day-9 lag spike in the player's phone frame record (v0.27.1, seed 67): once a second, `EventDirector.site_what_is_on_her_way` asks `WalkSiting.ahead_of` for each of about 12 unplaced `poster_crew` copies; each gets one candidate tile, and `EventScheduler._best_of` re-runs the whole rule chain on that same tile `Tuning.EVENT_PLACEMENT_TRIES` (24) times against all 357 plans before refusing it. It is reproduced on the desktop at 274 ms per tick. The proposed fix evaluates each candidate once per `_best_of` call, with identical rng draws. The soft lock is the day-12 softlock (azure-koala, finding 9), now under bouncy-swan, "the phone's lag spikes are found and fixed" (filed from #670 in #693).

2. **The note**, filed with the band `now`.

   > the lag spike explanation might also be the explanation for the soft lock -- let's audit the placement code for guaranteed and bounded completion

## #703

1. **What the note answered** (the assistant):

   Said while sending the second phone frame record (v0.27.1, `?debug=1&framerecord=1&seed=67&day=14`, file nappy-frames-seed67-2026-10-11T17-40-04.json) for M159, a slow frame names the frame that was slow. The agent had asked for recordings of day 9 (walled) and day 14 (densest) on seed 67.

2. **The note.**

   > No super lag spikes but a lot of stutter

## Filed as

- **#696**: a re-report, added to [M219](../todo/2026-09-26-M219/README.md), on a pedestrian street a
  blocked walker turns round, raised from `later` to `now` as a note from playing.
- **#697**: [feathery-lemur](../todo/2026-10-11-feathery-lemur/README.md), a held input carries her on
  through a gatehouse's release.
- **#698** and **#699**: [teal-trout](../todo/2026-10-11-teal-trout/README.md), every charger is
  neutral, then warns, then charges; the waiting dog's resting frame is its first item.
- **#700**: four items added to [M159](../todo/2026-09-19-M159/README.md), a slow frame names the frame
  that was slow: shadows baked into their own atlas, nothing off screen redrawn or animated, the
  frame drawn straight to the screen and then the pixel multiplier, and the readout's resolution and
  refresh. The engine patch is recorded there as not now. A fifth item, the cues and the events
  doing less, is the filer's proposal from the investigators' candidates, marked so in its file.
- **#703**: the day-14 record's context in its evidence README and in M159's README.
- **#701**: an item added to [bouncy-swan](../todo/2026-10-11-bouncy-swan/README.md), the phone's lag
  spikes are found and fixed: event placement completes, always and within a bound.

The day-9 record answers bouncy-swan's review item, "Save a frame record of a lag spike on the phone":
it was saved straight after a big lag spike, which its longest frame names as `events`. That item
leaves the review.
