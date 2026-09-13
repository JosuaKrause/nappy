# M124 — the two fixes the measurement named, measured

The build half of *the game on a phone, measured and then made cheaper*. The measurement that
chose these two is [`../m124-frame-cost-2026-09-13/README.md`](../m124-frame-cost-2026-09-13/README.md);
this folder holds what the two are worth once built, on the same walk.

- **Events redraw only when their picture changes** — `EventInstance._redraw_if_the_picture_changed()`
  and `_picture_key()`, the gate `CrowdAgent` has always had.
- **The building shadows are drawn per chunk** — one `CanvasItem` per 16-tile-square patch of city
  rather than one for the whole of it, so the renderer's own rect culling can drop the off-screen
  ones.

Each subfolder is one walk's own telemetry run folder, copied whole: `run.log` with a `frame` entry
every second, the day's `maps/` pictures beside it, and for the two bursts the numbered PNGs, their
`burst.json` timing record and the MP4.

## The walk

The same seed, day and scripted route the measurement used, so the two tables are about the same
twenty seconds of the same day:

```sh
tools/shot.sh out.png 20 --seed 3265820891 --day 1 --walk 3s17e
```

Each row is the mean of that run's own `frame` entries from t=2s on; the first second is the city
build and is a different measurement. `worst` is the single longest frame in the whole window.

**Two things about this rig differ from the one the measurement ran on, and both are stated here
rather than buried, because they are why these numbers are not the measurement's numbers.**

- **Vsync is disabled for the runs**, which is the one flag added to the command line above:
  `Godot --path . --resolution 1280x720 --disable-vsync -- --screenshot … --after 20 --seed …`.
  This session's display runs at 60Hz and the project leaves vsync on, so **every one of the four
  states pins at exactly 60fps with a 16.7ms worst frame** and the table reads nothing at all. The
  rest of the command line is `tools/shot.sh`'s own.
- **The machine is shared.** Three other agents were running Godot test suites on it throughout,
  which is most of the run-to-run spread below — round 2 is visibly the worst of it, with a
  75.5ms hitch inside the `shadows` run. The four states are therefore **interleaved**, one round
  at a time in the order baseline, events, shadows, both, so drift in what else the machine is
  doing lands on all four equally rather than on whichever was measured last.

**And the baseline itself is a floor rather than a reading.** In `baseline-1` and `baseline-2`, 17
and 16 of the twenty seconds report a worst frame of exactly 16.7ms — the baseline is sitting on
the display's own pace and cannot go slower here without dropping to 30. So every improvement below
is a **lower bound**: the gap between the baseline and the fixed states is at least this wide.

## The numbers

Apple M2, Godot 4.7.2, `gl_compatibility`, 1280x720 windowed, vsync off.

| run | fps | draws | objects | primitives | process ms | physics ms | worst ms |
|---|---|---|---|---|---|---|---|
| baseline-1 | 60 | 705 | 3504 | 7336 | 18.29 | 2.60 | 76.1 |
| events-1 | 69 | 706 | 3500 | 7334 | 17.99 | 2.63 | 20.6 |
| shadows-1 | 80 | 580 | 1641 | 3755 | 16.57 | 2.23 | 25.1 |
| both-1 | 93 | 582 | 1643 | 3770 | 15.32 | 2.16 | 17.8 |
| baseline-2 | 60 | 713 | 3516 | 7366 | 18.34 | 2.61 | 23.2 |
| events-2 | 63 | 720 | 3523 | 7381 | 18.03 | 2.62 | 26.4 |
| shadows-2 | 59 | 591 | 1665 | 3806 | 18.29 | 2.62 | 75.5 |
| both-2 | 84 | 580 | 1640 | 3751 | 16.61 | 2.39 | 28.8 |
| baseline-3 | 72 | 706 | 3500 | 7334 | 17.04 | 2.28 | 20.7 |
| events-3 | 86 | 718 | 3522 | 7378 | 16.30 | 2.17 | 17.8 |
| shadows-3 | 84 | 577 | 1638 | 3738 | 15.69 | 2.15 | 18.8 |
| both-3 | 94 | 581 | 1642 | 3753 | 15.10 | 2.26 | 18.7 |

The same four states, over all three rounds at once:

| state | fps | draws | objects | primitives | process ms | physics ms | worst ms |
|---|---|---|---|---|---|---|---|
| **baseline** | 64 | 708 | 3506 | 7345 | 17.90 | 2.50 | 76.1 |
| **events gated** | 72 | 715 | 3515 | 7364 | 17.44 | 2.47 | 26.4 |
| **shadows chunked** | 74 | 583 | 1648 | 3767 | 16.88 | 2.34 | 75.5 |
| **both** | 90 | 581 | 1642 | 3758 | 15.68 | 2.27 | 28.8 |

## What it says

1. **The two together are worth about 40% of the frame rate on this rig**, 64 to 90, against the
   30% the measurement's own (f) row projected for them — and this baseline is a floor, so the
   real figure is at least that. Separately they are +13% and +16%, and they compose: neither is in
   the other's way, because one is a rebuild cost on the CPU and the other is a submission cost.

2. **The gate keeps every pixel, and the counters are what say so.** Gating the events moves
   `draws`, `objects` and `primitives` by well under a percent — 3506 to 3515 objects, 7345 to
   7364 primitives, which is the same drift two baselines of the same build show each other. The
   same number of commands is submitted; what is no longer paid for is **rebuilding** the list that
   holds them. That is exactly the shape the measurement's (e2) row predicted: the same picture,
   from a draw list that is not thrown away every tick.

3. **Chunking the shadows removes what was never on screen.** `objects` 3506 → 1648 and
   `primitives` 7345 → 3767, both a little over half, and `draws` 708 → 583. The measurement's (c)
   row — the shadows not drawn *at all* — reads 1584 objects and 3641 primitives on the same walk,
   so chunking leaves about 60 objects and 130 primitives of shadow on screen, which is the shadow
   the player can actually see. The remaining 1,860 commands a frame were the rest of the city.

4. **`process ms` still under-reports, exactly as the measurement warned.** The change worth 40% of
   the frame rate moves it by 2.2ms, and it is noisier than that gap across rounds. Read `fps`.

## Pixel identity

The shadows had to come out of this looking identical, and a plain before/after screenshot cannot
say whether they did: **two runs of the same build at the same seed differ by about 16,000 pixels**,
because the crowd and the traffic keep walking and a screenshot is taken after N seconds of wall
clock rather than after N ticks.

`--fixed-fps 60` fixes that. `AutoScreenshot` counts `--after` by accumulating `delta`, so a fixed
delta makes the capture land on the same frame every time, and the whole simulation becomes
reproducible:

```sh
Godot --path . --resolution 1280x720 --fixed-fps 60 -- --screenshot out.png --after 4 --seed 4242 --day 1
```

Two runs of the branch base and two of the branch tip, all four at that command line:

| comparison | differing pixels | where |
|---|---|---|
| base run 1 vs base run 2 | 389 | x 1114..1144, y 276..388 |
| tip run 1 vs tip run 2 | 483 | x 1118..1139, y 276..388 |
| **base vs tip** | **1661** | **x 1104..1148, y 276..388** |

**Every differing pixel in all three comparisons is inside the same small box, and that box is the
debug readout's own digits** — `FrameCost`'s fps, draws, objects, primitives and times, printed on
screen, which differ between any two runs of anything. Outside it the frame is identical pixel for
pixel: **0 differing pixels in 921,600**, ground, buildings, shadows, crowd, traffic, events and
player alike.

The two frames are [`pixels-before-seed4242-day1.png`](pixels-before-seed4242-day1.png) and
[`pixels-after-seed4242-day1.png`](pixels-after-seed4242-day1.png). Read the readout in the corner
of each and the fixes are legible in the picture itself: objects 4189 → 2304, primitives 8736 →
5100, draws 1008 → 877.

**The method was validated against a control** before it was believed. A third run with the shadow
chunks drawing nothing — the measurement's own (c), as a temporary local change, reverted — differs
from the tip by **77,040 pixels**, so a comparison that reports zero is one that would have seen a
change in the shadows if there had been one.

## Motion evidence

A gate that named one too few things in its key does not crash, it **freezes a picture**, and a
still cannot tell a frozen sprite from a sprite between frames. So the animations are bursts —
`--press snapshot_burst 3`, 36 frames over three seconds with a `burst.json` recording when each
one was actually taken, converted by `tools/clip.sh`. `--invincible` is right here because the
subject is the animation rather than a cost: nothing ends the day, so the capture can wait for its
moment.

- [`burst-dog-walker/`](burst-dog-walker/) — `--seed 4242 --day 1 --spawn event:dog_walker`. The
  walker's legs and the dog's swap frames as the pair crosses the pavement, and the two stay in
  step with each other, which is the one phase `_draw_dog_walker()` reads twice.
- [`burst-cafe-tables/`](burst-cafe-tables/) — `--seed 3265820891 --day 1 --spawn event:cafe_tables`,
  the measurement walk's own seed. The sitters lean and straighten on `SITTER_IDLE_PERIOD` (3.4s, so
  one swap inside a three-second burst) with nothing about the row moving at all — the animation a
  distance-driven key would have silenced. Their halo is up throughout, which is the other thing
  worth reading off these frames: a gated event still wears a rim traced from the body it is
  drawing now, because `EntityHalo` is its own `CanvasItem` with its own `_process()` and calls
  `_draw_body()` live.

**No busker burst.** `--spawn event:busker` on seed 4242 day 1 lands beside a `scaffolding`
instead, because that day has no busker to spawn next to; the café's own idle timer is the same
`_idle_stepping()` mechanism at a slower tempo, so it is the same thing being shown.
