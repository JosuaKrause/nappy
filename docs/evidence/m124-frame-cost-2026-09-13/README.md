# M124 — where a frame goes, measured

The desktop half of *the game on a phone, measured and then made cheaper*, against the report of
2026-09-13: *"I played a few sessions on mobile. It is a bit laggy now. Are we using proper texture
atlases or is everything an individual loaded texture? Maybe we can optimize the game a bit more."*

Each subfolder is one measurement walk's own telemetry run folder, copied whole — `run.log` with a
`frame` entry every second, and the day's `maps/` pictures beside it.

## The walk

Every row below is the **same** seed, day and scripted route, so the runs differ only in the one
thing each was built to isolate:

```sh
tools/shot.sh out.png 20 --seed 3265820891 --day 1 --walk 3s17e
```

Three seconds south off the doorstep to clear the notch, then seventeen east: she crosses a
signalled crossing into traffic at 5.2s, meets a `leaf_blower` and `cafe_tables` at 10.5s with
their halos up, and stands against the leaf blower from 12.6s to the end. A walk and a steady
state in one window, and identical in all eleven runs — the walk is scripted and the day is
deterministic, so what the table compares is the drawing and nothing else.

`--invincible` is deliberately **absent**. Under it `Baby._update_excitement()` adds nothing to
the meter, so no source ever `landed()` any points, so `ExcitementHalo` selects nobody and **no
halo is ever drawn** — which would have measured the halo suspect by removing it from both sides.

Each row is the mean of that run's own `frame` entries from t=2s on; the first second is the city
build and is a different measurement. `worst` is the single longest frame in the whole window.

## The numbers

Desktop rig: Apple M2, Godot 4.7.2, `gl_compatibility`, 1280x720 windowed.

| run | fps | draws | objects | primitives | process ms | physics ms | worst ms |
|---|---|---|---|---|---|---|---|
| baseline | 115 | 709 | 3504 | 7348 | 12.85 | 1.91 | 16.3 |
| baseline, again | 117 | 708 | 3504 | 7351 | 12.19 | 1.84 | 15.8 |
| baseline, a third time | 116 | 706 | 3501 | 7338 | 12.30 | 1.85 | 15.1 |
| **(a)** resolver short-circuited (`--svg`) | 118 | 709 | 3505 | 7348 | 10.44 | 1.74 | 15.1 |
| **(b)** halo re-traced only while easing | 117 | 709 | 3504 | 7346 | 12.36 | 1.86 | 11.4 |
| **(c)** building shadows not drawn | 123 | 570 | **1584** | **3641** | 11.73 | 1.86 | 13.8 |
| **(d)** crowd `_draw` skipped | 123 | 672 | 3467 | 6978 | 11.66 | 1.78 | 9.9 |
| **(e)** event `_draw` skipped | **138** | 696 | 3488 | 7214 | 11.14 | 1.77 | 12.4 |
| **(e2)** events drawn, draw list built **once** | **139** | 708 | 3503 | 7345 | 10.82 | 1.89 | 12.0 |
| **(f)** (c) and (e2) together | **151** | **572** | **1585** | **3644** | 10.39 | 1.76 | 10.6 |
| resolver probe (instrumented, timings invalid) | 116 | 708 | 3503 | 7347 | 13.81 | 1.80 | 15.5 |

**Three baselines first, because a suspect is only readable against the noise.** Run to run the
counts vary by under 0.5% and the frame rate by under 2%, which is what makes a 6% row and a 19%
row mean something and an fps row of 118 against 115–117 mean nothing.

**Read `fps`, not `process ms`.** Godot's `TIME_PROCESS` monitor is bimodal across these runs —
consecutive seconds of one steady walk read 15.7, 15.8, 8.3, 15.2 — and it misses the largest
effect in the table outright: (e2) moved the frame rate by 19% and the process time by 1.4ms.
Whatever it is accounting, it is not where this frame goes.

## What each row was

Every one is a temporary local change, reverted before committing; none is in the branch.

- **(a)** `--svg`, a flag that already ships. `TextureResolver.resolve()`'s first line is
  `if _svg_requested or texture == null: return texture`, so the flag *is* the short-circuit — no
  path string, no dictionary lookup, per draw. It swaps the 126 PNG transfers back to their SVGs
  as well, which is why it is read together with the probe below rather than alone.
- **(b)** `EntityHalo._process()`'s `if not settled or is_showing(): queue_redraw()` cut back to
  `if not settled:` — the re-trace-every-frame behaviour removed, the fade kept.
- **(c)** `BuildingShadows._draw()` returning immediately.
- **(d)** `CrowdAgent._draw()` returning immediately — every walker and car invisible, all of them
  still simulated and still pushing her, so the route is unchanged.
- **(e)** `EventInstance._draw()` returning immediately.
- **(e2)** `EventInstance._draw()` untouched and every event still on screen, but the unconditional
  `queue_redraw()` at the end of its `_physics_process` fired **once** instead of every tick. The
  same pixels, drawn from a retained list that is never rebuilt.
- **(f)** (c) and (e2) at once, to size the headroom the two together are worth.
- **the resolver probe** counted `TextureResolver.resolve()` calls, distinct resolved textures and
  the wall time inside it, appended to the `frame` line. Its own `Time.get_ticks_usec()` pair on
  every call is why its timings are not comparable with the rest of the table.

## What the probes counted

**The resolver, per frame: 157 calls, 79 distinct textures, 0.108ms.** (18,192 calls, 79 distinct
and 12.43ms per second at 116fps — see `probe-resolver/run.log`.) That 0.108ms includes the
probe's own two clock reads per call, so the true figure is lower: **the per-draw string lookup is
about 1% of a frame** at this frame rate, and the fix for it cannot be worth more than that.

**The building shadows, per frame: 1,918 draw commands — 1,783 full tiles and 135 corner
triangles, from 151 building rects.** It matches the 1,920 renderable objects row (c) removes
exactly. They are one retained draw list covering the **whole city**, submitted in full every
frame: the visible world at zoom 2 is 640x360px, about 220 tiles, so roughly **99% of those
commands are off screen** and no per-item culling reaches them, because a `CanvasItem`'s draw list
is culled as one item by its own rect.

## What it says

1. **The single largest cost is events rebuilding their draw lists, not drawing them.** (e) and
   (e2) are the same number to within noise — removing the event drawing entirely and keeping every
   pixel of it while never rebuilding it both give +19%. `EventInstance._physics_process` ends with
   an unconditional `queue_redraw()`, so about thirty live events re-run a `_draw()` full of sprite
   lookups, shadow polygons and caret projections 120 times a second, nearly always to produce the
   identical picture. `CrowdAgent._redraw_if_the_picture_changed()` already solves exactly this for
   the crowd and says so in its own doc: *"at this population that is the difference between five
   hundred redraws a frame and a handful."* Events never got it.
2. **The second is the building shadows, and it is a submission cost rather than a rebuild one.**
   They are half of every renderable object and half of every primitive in the frame, for 139 draw
   calls and 6% of the frame rate, and they are recomputed never and re-submitted always.
3. **Texture switching is not what this frame is short of.** 79 distinct textures and 709 draw
   calls means the renderer is already batching about five items per call. The decisive evidence is
   (e2) against (c): (c) removed 139 draw calls and bought 6%, while (e2) removed **none at all**
   and bought 19%. An atlas moves the number that bought the smaller share.
4. **The resolver and the halo are both inside the run-to-run noise** and neither is worth a change.

## What a phone cannot be told from here

Every number above is CPU-side or submission-side, and the two costs a desktop measurement cannot
see are the two most likely to be a phone's: **fill rate** — this frame is 7,348 primitives of
mostly large, alpha-blended, overlapping quads over a full-screen ground, and a phone's fragment
throughput and memory bandwidth are a fraction of an M2's for the same coverage — and
**resolution**, since a phone renders the same scene at its own device pixel count rather than at
1280x720. The `frame` entry exists precisely so those can be read off a real device's `run.log`
rather than guessed at: the same table taken on the phone is the missing half, and whether the
phone's `draws` and `primitives` match these while its frame rate does not is the question that
decides it.
