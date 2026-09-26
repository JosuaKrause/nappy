## M124 — Where a frame goes, measured · the desktop half, 2026-09-13

*(2026-09-13, [PLAYTEST-67](../playtests/PLAYTEST-67.md): "I played a few sessions on mobile. It is a
bit laggy now. Are we using proper texture atlases or is everything an individual loaded texture?
Maybe we can optimize the game a bit more.")* The queue entry's own condition was *measure before
touching anything, and nothing is atlased on a guess*. This is the measurement; the two fixes it
names and the phone half are what the entry in `TODO.md` now holds.

**The instrument.** `FrameCost` (`src/telemetry/frame_cost.gd`) reads six costs off Godot's
`Performance` monitors — frame rate, draw calls, renderable objects, primitives, and the
milliseconds in `_process` and `_physics_process`. The debug readout (`4`, on by default in a
debug build) shows them, and `TelemetryObserver` writes them to `run.log` once a second as a
`frame` entry, so a session played on a device with no readout can be read back afterwards.
One class rather than two format strings, because the comparison the milestone exists to make is
a phone's log against a desktop's screen, and it only means anything while both are assembled
from the same readings; `tests/test_performance.gd` holds that agreement, and only that, since
the render counters are zero under `--headless`. Two silent choices, both open to overturn: the
interval is timed off `delta` rather than the day clock, because `--invincible` stands the day
clock still and an interval measured against it would write one line and never advance; and the
line carries the **worst** frame of its second rather than a mean, because *"a bit laggy"* is a
hitch and a mean is the statistic a hitch hides in.

**The walk.** Every row is the same seed, day and scripted route, so the runs differ only in the
one thing each isolates: `tools/shot.sh out.png 20 --seed 3265820891 --day 1 --walk 3s17e` —
three seconds south off the doorstep, seventeen east across a signalled crossing into traffic,
past a `leaf_blower` and `cafe_tables` with their halos up, ending against the leaf blower.
`--invincible` was deliberately left off: under it the meter never lands a point, so the halo
selects nobody and would have been measured by removing it from both sides. Each row is the mean
of the run's `frame` entries from t=2s; `worst` is the single longest frame. Apple M2, Godot
4.7.2, `gl_compatibility`, 1280x720 windowed. The run folders are in
`docs/evidence/m124-frame-cost-2026-09-13/`, whose README says what each row's temporary change
was; none of those changes is in the tree.

| run | fps | draws | objects | primitives | process ms | physics ms | worst ms |
|---|---|---|---|---|---|---|---|
| baseline | 115 | 709 | 3504 | 7348 | 12.85 | 1.91 | 16.3 |
| baseline, again | 117 | 708 | 3504 | 7351 | 12.19 | 1.84 | 15.8 |
| baseline, a third time | 116 | 706 | 3501 | 7338 | 12.30 | 1.85 | 15.1 |
| (a) resolver short-circuited (`--svg`) | 118 | 709 | 3505 | 7348 | 10.44 | 1.74 | 15.1 |
| (b) halo re-traced only while easing | 117 | 709 | 3504 | 7346 | 12.36 | 1.86 | 11.4 |
| (c) building shadows not drawn | 123 | 570 | **1584** | **3641** | 11.73 | 1.86 | 13.8 |
| (d) crowd `_draw` skipped | 123 | 672 | 3467 | 6978 | 11.66 | 1.78 | 9.9 |
| (e) event `_draw` skipped | **138** | 696 | 3488 | 7214 | 11.14 | 1.77 | 12.4 |
| (e2) events drawn, draw list built **once** | **139** | 708 | 3503 | 7345 | 10.82 | 1.89 | 12.0 |
| (f) (c) and (e2) together | **151** | **572** | **1585** | **3644** | 10.39 | 1.76 | 10.6 |
| resolver probe (instrumented; timings invalid) | 116 | 708 | 3503 | 7347 | 13.81 | 1.80 | 15.5 |

Three baselines because a suspect is only readable against the noise: run to run the counts move
under 0.5% and the frame rate under 2%. Two instrumented counts beside the table: the resolver is
157 calls, 79 distinct textures and 0.108ms per frame including the probe's own clock reads, and
the building shadows are 1,918 draw commands — 1,783 full tiles and 135 corner triangles from 151
building rects — where the queue entry had guessed "a few hundred".

**What it says.**

1. **The largest cost is events rebuilding their draw lists, not drawing them.**
   `EventInstance._physics_process` ends with an unconditional `queue_redraw()`, so about thirty
   live events re-run a `_draw()` of sprite lookups, shadow polygons and caret projections 120
   times a second, nearly always to the identical picture. (e2) is the proof: every pixel kept,
   the redraw fired once instead of every tick, identical draws, objects and primitives, and the
   same +19% as deleting the drawing outright. `CrowdAgent._redraw_if_the_picture_changed()`
   already solves exactly this for the crowd — *"the difference between five hundred redraws a
   frame and a handful"* — and events never got it.
2. **The second is the building shadows, and it is a submission cost rather than a rebuild one.**
   Half of every renderable object and half of every primitive in the frame, for 139 draw calls
   and 6% of the frame rate: one retained list covering the whole city, re-submitted every frame,
   culled as one item by its own rect, when the visible world at zoom 2 is about 220 tiles — so
   roughly 99% of those commands are off screen.
3. **Texture switching is not what this frame is short of**, which is the player's question
   answered. Everything is an individually loaded texture — 582 SVGs and 126 PNG transfers under
   `assets/`, preloaded per class, each drawn with its own `draw_texture_rect` through a
   `TextureResolver.resolve()` keyed on the path string — and nothing is atlased. But a frame
   draws 79 distinct textures across 709 draw calls, so the renderer already batches about five
   items per call, and the decisive pair is (c) against (e2): removing 139 draw calls bought 6%,
   removing none at all bought 19%. An atlas moves the number that bought the smaller share.
4. **The resolver and the halo are inside the run-to-run noise, and neither is changed.** The
   brief allowed a resolver fix if it were clearly the cost, and about 1% of a frame is not worth
   a change to a shipped presentation path. Both are struck from the suspects.
5. **Read `fps`, not `process ms`.** `TIME_PROCESS` is bimodal across consecutive seconds of one
   steady walk (15.7, 15.8, 8.3, 15.2) and misses the largest effect in the table: the change
   that moved the frame rate 19% moved it 1.4ms.

**What a phone cannot be told from here.** Every number above is CPU-side or submission-side, and
the two costs a desktop cannot see are the two most likely to be a phone's: fill rate — 7,348
primitives of mostly large, alpha-blended, overlapping quads over a full-screen ground — and
resolution, since the phone renders the same scene at its own device pixel count. If the phone's
`draws` and `primitives` match these and only its frame rate does not, the cost is fill rate and
no amount of batching touches it. That half is the queue's.
