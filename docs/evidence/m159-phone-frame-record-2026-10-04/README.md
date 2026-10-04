# The player's phone frame record, seed 478156010, v0.24.0

One frame record taken by the player on their phone with the released page, and what it says
about where the phone's frame time goes. It is evidence for M159 ("A slow frame names the frame
that was slow"), whose open item is to attribute the remaining slow intervals before the next
optimization ([attribute-the-remaining-slow-intervals-before.md](../../todo/2026-09-19-M159/attribute-the-remaining-slow-intervals-before.md)).
What the record format means, bucket by bucket, is in [TELEMETRY.md](../../TELEMETRY.md),
"Per-system frame records".

**Throughout, "shows" means the numbers in this file say it directly and "suggests" means it is
the most likely reading of them but something outside the file would have to confirm it.**

## Source

- **The file**: `nappy-frames-seed478156010-2026-10-04T12-27-57.json`, the page's own download
  from its `save frames` button, kept unchanged under the name the page gave it (SHA-256
  `9e33d048c7681f309ace98aa7e2e2ed6ea4bbebc18d30ae4726aa8438445758b`, 207,736 bytes).
- **The build**: the released v0.24.0 page (the file's `build` reads `v0.24.0 (0901ca4)`), with
  the frame record on (`?debug=1&framerecord=1`). The file records ground mode 2 (the scenery
  queue's 2ms-a-frame mode) and run seed 478156010. The URL itself is not in the file. It is not
  the route the review item asks for (seed 67, up through the car accident and back), and mode 1
  was not recorded, so there is nothing to compare the two modes with.
- **The device, by its user agent**: `Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36
  (KHTML, like Gecko) Chrome/154.0.0.0 Mobile Safari/537.36`, so Chrome 154 on an Android phone.
  This is Chrome's reduced user agent: `Android 10; K` is a fixed placeholder, so the string gives
  neither the phone's model nor its real Android version. The WebGL adapter reads only
  `WebKit WebGL`. Earlier phone reports were on a Pixel 8 Pro ([PLAYTEST-140](../../playtests/PLAYTEST-140.md));
  this file does not say whether this was the same phone.
- **What identifies anyone**: the user agent string above, and nothing else. The rest is the
  game's own data (seed, positions in the city, timings) and the local time the file was saved.
- **Two downloads came from this run.** The earlier one (saved 33 seconds before) holds the same
  first 1,510 rows exactly, with the same environment apart from the save time, so it is a strict
  prefix of this one and is not kept. That comparison was made when the two files arrived; with the
  earlier file not kept, it cannot be rechecked from the repository.

`analyse.py` beside this file prints the numbers behind every table and figure here; it uses
only the standard library and writes nothing:

```sh
uv run python docs/evidence/m159-phone-frame-record-2026-10-04/analyse.py
```

## What the file cannot say

- **The clock steps in 100µs.** The page's clock is the browser's reduced-precision one
  (`timer_resolution_usec` 100), and every bucket value in every row is a whole number of
  100µs steps. One crowd agent's update, a few microseconds, reads as 0 or 100µs. Sums over a
  frame's 283 or so intervals and means over many frames are usable. A per-frame difference of a
  few tenths of a millisecond is not.
- **There is no GPU time.** `draw` is the CPU side of drawing. If a WebGL call has to wait for
  the GPU or for Chrome's GPU process, that wait is inside `draw` too, and nothing in the file
  separates it from the CPU work.
- **The record costs something itself.** One timing pair took 5.7µs on this phone (0.57µs on the
  Apple M2 that measured the record's cost). At 283 timed calls a frame (median), the pairs alone
  are 1.6ms a frame, 4% of the median frame. On the desktop, the record's whole cost, on against
  off, was 1.5 to 4 times that product ([m159-frame-record-2026-10-04](../m159-frame-record-2026-10-04/README.md)),
  which suggests 2.4 to 6.4ms of each phone frame is the record's own. About half of each agent's
  and each event's pair is charged inside `crowd` and `events`, so those two are inflated a
  little.
- **"Slow" says nothing in this file.** A browser reports no refresh rate, so the page assumes
  60Hz and calls a frame slow past 25ms. Every one of the 1,612 frames is over that line, so the
  slow flag and the summary's slow-frame splits cover the whole record and pick nothing out. The
  frames the record did not keep while the game was paused ran at 15.6ms each on average. A 60Hz
  screen cannot draw that fast, so the screen probably refreshes faster than 60Hz (suggests).
- **One run, one phone, about 74 seconds of play, no comparison.** It shows where this run's time
  went. It is not a controlled before/after measurement, and it cannot say what would change if
  a system were made cheaper.
- **The crowd never changed size.** `crowd_agents` reads 234 in every frame, so the file cannot
  relate the crowd's cost to how many agents there are.

## What the record shows

### 1. What it saw

The ring holds 18,000 frames and overwrote none. It kept all 1,612 frames of play: day 1's
first frames through its end, 1,510 frames over 67.8 seconds, then 102 frames over 6.0
seconds of day 2. **The recorder keeps every frame of play, not only slow ones; every frame
here is slow because no frame of play took 25ms or less.** Out of the 2,843 process frames from the first
kept frame to the last, 57% were kept. The rest are not play:

| after process frame | frames not kept | lasting, ms | ms each | |
|---|---:|---:|---:|---|
| 1549 | 876 | 17,806.9 | 20.3 | between the two days, when no day was being played |
| 2450 | 1 | 88.5 | 88.5 | one frame in day 2; why it was not kept is not in the file |
| 2494 | 354 | 5,527.2 | 15.6 | in day 2, while the game was paused or otherwise not in play |

During day 2 she stays at the doorstep (position 2560, 2704) the whole time.

### 2. Frame time

| ms | p5 | p25 | p50 | p75 | p95 | p99 | max | mean |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| frame | 31.8 | 35.4 | 40.8 | 53.4 | 72.2 | 78.0 | 150.9 | 45.8 |
| callbacks (frame less `wait`) | 30.6 | 33.9 | 39.0 | 51.1 | 69.2 | 74.6 | 122.7 | 43.8 |
| `wait` | 0.9 | 1.4 | 1.7 | 2.3 | 3.9 | 6.3 | 28.2 | 2.0 |

Day 1 averages 22.3 frames a second and day 2 17.1. The distribution has two humps: most
frames sit at 32 to 44ms (53% of frames) and a second group at 64 to 76ms (13%). Where the
frames of the second hump come from is in section 3: day 1 drifts slower over its 65 seconds,
from a median of about 34ms to about 72ms, and only day 2 flips back and forth between about
38ms and about 68ms. That the humps are two states of the phone rather than two kinds of frame
is a reading (suggests), not something the histogram shows.

### 3. Over the run: the same streets got slower

For the first 40 seconds of day 1 the median frame, five seconds at a time, is 34 to 43ms.
Then everything slows, steadily rather than in one step: 50 to 59ms from 40 to 65 seconds,
72ms at the end of the day. Day 2 behaves differently: while she stands still, it flips between
runs of frames of about 38ms and runs of about 68ms (medians of its one-step and two-step
frames, 38.4 and 67.5ms). The five-second table is in `analyse.py`'s section 3.

**It is not the place.** She walks north and comes back down the same street. On the same
stretches, with the same number of draw calls, render objects and live events, the way back
costs 1.4 to 2.1 times as much:

| her y | pass | frames | frame p50 | steps | draw p50 | crowd p50 | cues p50 | process_rest p50 | draw calls | objects | live events |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 1800-2200 | out | 178 | 37.8 | 1.28 | 15.1 | 8.4 | 4.4 | 2.2 | 308 | 1846 | 45 |
| 1800-2200 | back | 84 | 54.9 | 1.69 | 21.1 | 13.7 | 5.6 | 2.7 | 321 | 1799 | 44 |
| 2200-2600 | out | 127 | 33.8 | 1.03 | 13.3 | 8.0 | 3.7 | 2.1 | 301 | 1675 | 44 |
| 2200-2600 | back | 85 | 47.9 | 1.59 | 17.2 | 12.7 | 5.2 | 2.7 | 284 | 1698 | 40 |
| 2600-2800 | out | 213 | 34.5 | 1.05 | 13.7 | 8.0 | 4.0 | 2.1 | 343 | 1919 | 39 |
| 2600-2800 | back | 52 | 72.0 | 2.15 | 28.7 | 18.5 | 5.9 | 3.3 | 326 | 1832 | 37 |

("out" is the first 25 seconds of day 1, "back" after 45 seconds; "steps" is the mean number
of physics steps a frame.) **Even the systems that run once a frame whatever the step count
slow down**: `cues` rises by 27 to 48% and `process_rest` by 23 to 57%. So the phone itself
runs this game's work more slowly on the way back. That suggests the device or the browser
changed speed, from heat or power management or Chrome's own processes competing for the
CPU. Nothing in the file tells those apart.

### 4. Which system the time goes to

| bucket | mean ms, all | share | mean ms, worst 10% (162) | share | mean ms, worst 1% (16) | share |
|---|---:|---:|---:|---:|---:|---:|
| draw | 18.1 | 39% | 30.2 | 41% | 35.2 | 41% |
| crowd | 11.4 | 25% | 19.4 | 26% | 22.8 | 27% |
| cues | 4.4 | 10% | 5.4 | 7% | 5.0 | 6% |
| events | 3.9 | 8% | 6.0 | 8% | 6.2 | 7% |
| process_rest | 2.5 | 6% | 3.5 | 5% | 3.4 | 4% |
| influence | 1.5 | 3% | 2.5 | 3% | 2.6 | 3% |
| physics_rest | 1.5 | 3% | 2.6 | 4% | 3.8 | 4% |
| scenery | 0.4 | 1% | 0.8 | 1% | 1.2 | 1% |
| wait | 2.0 | 4% | 3.3 | 4% | 5.3 | 6% |

**`draw` is the largest cost in 1,606 of the 1,612 frames, and `crowd` in the other six.** One
of the six, process frame 744, is a tie at 13.0ms each; the record's own summary counts it as
`crowd`'s, and `analyse.py` lists it apart rather than breaking the tie. The
shares hardly move between the median and the worst 1%, so the worst frames are ordinary
frames, only longer: no single system spikes in them. `crowd` is the crowd's pathing:
`Crowd._physics_process()`, once a physics step, plus every `CrowdAgent._process()`, every
agent every frame. `cues` is `ExcitementHalo._process()` (which source charges her and the
carets' predictions) and `DangerEdge._process()` (the off-screen badges). `events` is
`EventManager._physics_process()` plus every `EventInstance._process()`.

Of the ten longest frames, the two longest are the start of day 2. The first is 150.9ms with no
physics step, 74.8ms of `draw`, 36.8ms of `crowd` and 550 timed calls against the usual 283.
The second is 89.9ms with 8 physics steps, which is the engine's per-frame limit, catching up.
Day 1's first kept frame is 85.0ms, 19.2ms of it in `physics_rest`. The other seven are 80 to
83ms frames from the slow stretches, with two or three steps each.

### 5. Physics steps (catch-up)

Physics ticks 30 times a second (`physics_ticks_per_second=30` in `project.godot`), and a frame
runs as many steps as the time since the last one calls for. Frames by step count: 0 steps 5,
1 step 1,035, 2 steps 543, 3 steps 28, 8 steps 1. **35% of frames run two or more steps.** The
step count follows the previous frame: frames with 2 steps come after a frame of 57.6ms
(median), frames with 1 step after one of 36.8ms.

In day 1's first 40 seconds, the median one-step frame is 35.7ms and the median two-step frame
44.4ms (1,029 frames, 857 and 161 of them). **That 8.7ms overstates what the step costs.** A
two-step frame follows a longer frame, and a frame that follows a longer one costs more in every
bucket (section 6). Compared within 5ms bands of the previous frame's length (35 to 50ms, 110
two-step frames), the second step adds:

| bucket | added by one more step, ms |
|---|---:|
| crowd | 1.7 |
| events | 0.7 |
| influence | 0.7 |
| physics_rest | 0.7 |
| draw | 0.5 |
| everything else | under 0.2 each |
| **the frame** | **4.3** |

So one physics step costs about 3.8ms across the systems that run once a step. The crowd's
physics step (`Crowd._physics_process()`) is about 1.7ms of that, and the rest of a one-step
frame's 8.4ms of `crowd` (median), about 6.7ms, is the agents' own per-frame update.

Physics does the same work every second however fast frames are drawn: 30 steps of about 3.8ms
is about 11% of each second of the main thread. A catch-up step adds no work. It moves a step's
work into whichever frame is due one. When frames run slower than 30 a second, that is a
two-step frame every few frames, about 4ms longer than its neighbours. That is a small regular
unevenness on top of frames that are already 35 to 70ms long. The file cannot tell whether that
is what [PLAYTEST-140](../../playtests/PLAYTEST-140.md) describes on a Pixel 8 Pro ("it's pretty
regular nothing stands out in particular"); the swings in speed over the run (section 3)
are several times larger.

### 6. What draw tracks

Every kept frame was drawn (`drawn` is 1 in every row). Across all frames, `draw` hardly follows
the scene: its correlation with `draw_calls` is 0.11, with `render_objects` 0.18 and with
`primitives` 0.15. It follows the run's speed: 0.86 with the previous frame's length and 0.85
with the previous frame's `draw`. Within one stretch and one step count (day 1's first 40
seconds, one step, previous frame kept: 856 frames, 228 to 463 draw calls), least-squares fits
of `draw` give:

| model | per draw call | draw at zero calls (intercept) | draw per ms of previous frame | R² |
|---|---:|---:|---:|---:|
| draw calls alone | 14.1µs | 9.9ms | - | 0.12 |
| draw calls + previous frame's length | 6.9µs | 2.2ms | 0.27ms | 0.35 |
| the same + render objects + primitives | 5.0µs | 0.5ms | 0.26ms | 0.36 |

**The models disagree on how much of `draw` the counters leave unexplained, so the file does not
settle it.** Fitted on draw calls alone, a draw call costs 14.1µs and the line meets zero calls at
9.9ms. But `draw` also follows the phone's drifting speed, which that fit credits to the draw
calls and to the intercept. Holding the previous frame's length fixed halves the per-call cost
to 6.9µs and drops the intercept to 2.2ms, and adding objects and primitives takes it to 5.0µs
and 0.5ms. Every intercept is also an extrapolation from at least 228 calls down to none. On
these fits, 100 fewer draw calls would buy somewhere between about 0.5 and 1.4ms of a
one-step frame's 14ms of `draw`, the lower end once the speed is held fixed. **What the models
agree on** is that `draw` is the largest share of the frame (section 4), that the phone's speed
moves it more than any counter does, and that none of the counters explains most of its
frame-to-frame variation (R² at most 0.36). What the rest is (the `_draw()` callbacks of
whatever was redrawn that frame, the deferred calls, the renderer's fixed cost per frame, a wait
for the GPU) the file cannot separate.

**`draw` grows with the length of the frame before it, not with the step count.** In day 1's
first 40 seconds, a one-step frame's `draw` is 13.2ms (median) after a 30 to 35ms frame and
17.8ms after a 45 to 50ms one. After an equally long frame, a two-step frame's `draw` is
within a millisecond of a one-step frame's (14.8 against 14.1ms after 35 to 40ms, 16.4 against
16.1 after 40 to 45). `crowd` grows the same way (8.0 to 10.0ms), while `cues` barely moves
(4.0 to 4.3ms). There are two readings, and the file cannot choose between them. Either the
phone was slower for a while, so both frames are long, or part of the work is paid for elapsed
time, for example pictures that change at a fixed rate in time and are redrawn when they do,
so a long frame leaves more of them to redraw in the next. The second would feed itself: a
long frame makes the next one longer.

**`draw` also jumps on its own.** In day 2, standing at the doorstep, `draw` rises by 7ms or
more from one frame to the next six times. None of those comes with more physics steps. At
process frame 2458, nothing else moves at all: `draw` goes from 17.4 to 29.7ms with `crowd`,
`cues` and `process_rest` within 0.3ms of the frame before. At 2436 the step count even falls,
2 to 1, while `draw` rises by 8ms. The physics steps follow a long frame, so their rise comes
after `draw`'s. That suggests the swings start in drawing or below it (the GPU, the browser),
and catch-up steps then carry the long frames on.

### 7. Crowd, events and cues against what is alive

`crowd_agents` is 234 throughout, so the file cannot show how the crowd's cost scales with the
number of agents. Divided evenly, the 6.7ms per-frame part is about 29µs an agent a frame, of
which up to 5.7µs is the record's own pair.

Against live events (36 to 49), in the same stretch (day 1's first 40 seconds, one step, 856
frames), the fitted slopes per live event are 63µs for `events` (correlation 0.34), 44µs for
`cues` (0.24), 55µs for `crowd` (0.13) and 16µs for `influence` (0.14), 178µs for the four
together, so thirteen more live events would cost about 2.3ms. **The file cannot separate those
slopes from the phone's drift**: in that stretch the live events rise (from 38 to between 42
and 47 on average, five seconds at a time) while the phone slows (median frame from 34 to
43ms). Holding the previous frame's length fixed, as for `draw`, lowers them to 59, 37, 27
and 9µs, 133µs together. The correlations are weak, so these are slopes the record is
consistent with, not costs it establishes.

### 8. Scenery, and the player's mode-2 hypothesis

The player's hypothesis, from [quiet-yak](../../playtests/2026-10-03-quiet-yak.md): "my hypothesis
is that mode 2 allows more expensive things to take up time as it limits itself to a very short
time budget". The scenery queue updated in 473 frames and ran a job in 158 of them (97 ground,
58 building, 37 prop, 30 shadow, 15 decal, 16 guard preparations). It went past its 2ms budget
in 48 frames, by at most 2.4ms. `scenery` is 0.4ms a frame on average, 1% of the frame. Of that,
the deferred share (the tile map work and first draws it leaves to the engine's flush) is 70.7ms
of 674.7ms over the whole run. **A frame with a job is 2.1ms longer (median) than its job-free
neighbours three frames either side, and its `scenery` time is 2.1ms longer too (both medians).**
The frame grows by the job and no more, so there is no sign of another system taking more time
in those frames. In this mode-2 record the scenery queue is not what makes frames slow. Without a mode-1 record from the
phone, the comparison the hypothesis asks for cannot be made.

### 9. What `wait` says about the browser's pacing

`wait` is the time between the end of drawing and the next frame. Its median is 1.7ms and its
p99 6.3ms, 4% of all time. No frame's callbacks fit inside one 60Hz budget, so the summary's
`outside_callbacks` (a slow frame held up outside the game's own work) is 0. **The browser asks
for the next frame almost as soon as the last one is drawn.** The main thread is busy with the
game's own work for about 96% of every frame. The browser or the compositor holding the next
frame back would land in `wait` (as [TELEMETRY.md](../../TELEMETRY.md)'s `wait` row says, it
"all look[s] like idle time here"), and `wait` is small, so that is ruled out. A GPU stall is
not: one that blocks inside a WebGL call lands in `draw`, where the record cannot tell it from
the CPU's own drawing (section 6). So the browser's pacing is not what holds this phone back;
whether the GPU is stays open.

## What the numbers point at, ranked

The ranking weighs share of the frame, how clearly the file ties the cost to a cause, and
whether the next step can be measured off the phone. **None of these is established by this
file alone.** Each needs a desktop or headless measurement first, as the attribution item asks,
and a before/after with identical behaviour once something is built. The phone stays an eye test
([sunny-chipmunk](../../playtests/2026-10-03-sunny-chipmunk.md): "phone profiling would be a
nice to have but honestly a quick eye test is good enough").

1. **What is inside `draw`.** It is 39% of the frame and the largest cost in all but six
   frames, with the same share in the worst ones. How much of it the counters leave unexplained
   depends on the model: fitted on draw calls alone, about 10ms at zero calls; with the previous
   frame's length held fixed, about 2ms; with objects and primitives too, about 0.5ms (section 6).
   Either way the counters explain little of how it varies, it grows with the length of the frame
   before it, and its jumps come before the catch-up steps. *To confirm before building anything:*
   split `draw` into the `_draw()` callbacks and deferred calls on one side and the renderer's own
   work on the other, and count the redraws per frame. A native desktop profile on this seed and
   route can count the `_draw()` callbacks per frame and time them, and show whether their number
   grows with the time between frames; a headless run cannot, since it draws nothing.
   *Proposed, not asked for:* a mark at the renderer's `frame_pre_draw` signal in the record
   would make the same split in the next phone file. A desktop Chrome run of the same release
   with CPU throttling (4x to 6x) would show whether the drawing time scales with the CPU, as
   script work would, or stays put, as a GPU wait would; Chrome's own documentation says
   throttling does not truly simulate a phone. What to build depends on the answer: fewer or
   cheaper redraws, fewer canvas items, or less GPU work. On this record's fits, cutting draw
   calls alone would buy between about 0.5 and 1.4ms per 100.
2. **The crowd agents' per-frame update.** About 6.7ms a frame: every one of the 234 agents runs
   `CrowdAgent._process()` every frame, and it is the second-largest single cost after `draw`.
   It grows with the previous frame's length too (8.0 to 10.0ms of `crowd` across the bands in
   section 6). *To confirm:* a headless probe timing `CrowdAgent._process()` across the field at
   day-1 density with the record off, split by on-screen and off-screen agents and by call
   (`_look_ahead()`, `_consider_turning()`, `_keep_out_of_a_body()`, the redraw check). Any
   change has to leave every agent's position identical frame for frame, which a headless
   parity run can check.
3. **The danger cues, 4.4ms a frame (10%).** One system, run once a frame, so it costs per frame
   rather than per step, and it may grow by about 40µs per live event (a weak slope, section 7). *To confirm:* a desktop profile
   splitting `ExcitementHalo._process()` (picking who charges her, the carets' predictions) from
   `DangerEdge._process()` (the off-screen badges).
4. **The physics step, about 3.8ms each.** About 11% of every second, and a frame that has to
   take two steps is about 4ms longer. No single part is large: the crowd's step
   (`Crowd._physics_process()`, about 1.7ms), the baby's influence sweep (`Baby._physics_process()`,
   about 0.7ms, already made cheaper once in M159's crowd-sweep work), the rest of physics (0.7ms)
   and the events' step (0.7ms). *To confirm:* headless per-step timing of the crowd's step on
   this seed, and which call inside it dominates. The tick rate itself is a gameplay setting and
   is not a candidate.
5. **Event updates, 3.9ms (8%).** About 0.7ms of it is the events' physics step and the rest is
   every live event's `EventInstance._process()`. Its slope of about 60µs per live event is the
   steepest in the file, but weak (correlation 0.34) and not separable from the phone's drift
   (section 7). *To confirm:* which event kinds cost most at day-1 density, and how the cost
   scales with the number of live events at a fixed speed.
6. **The day's first frames.** Day 2 starts with a 150.9ms frame (550 timed calls, about twice
   the usual, which suggests something ran twice in it), then an 89.9ms frame with 8 catch-up
   steps. Day 1's first kept frame is 85ms. This happens once a day, not as a steady stutter, so
   it ranks last.

**Not candidates on this record:** the scenery queue (1% of the frame, and a job frame is longer
by its own job and no more), the browser's pacing (`wait` 4%, nothing held outside the callbacks;
this rules out the browser or the compositor holding frames back, not the GPU, whose stalls would
sit inside `draw`), and draw calls as the main lever (between about 0.5 and 1.4ms per 100).

**What the record also suggests, outside the game's code:** the phone slows down as the run
goes on, and every system slows with it. Cheaper work makes both the fast and the slow stretches
shorter in proportion, but no change in the game removes the slowdown itself. Whether it grows
with play time, as heat would, would take a longer phone record, which is optional.

## Retained

The record (the primary evidence: one player's run on their own phone, which no rerun recreates),
`analyse.py` (prints the numbers behind everything above from it), and this README. The earlier download is a
strict prefix of the record and is not kept.
