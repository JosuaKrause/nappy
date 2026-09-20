# M178 — she reappears where she is let out

Runtime evidence for one item of M178, "a gate lets her out alive, and where she comes out": the
frames around a region-door hold, recorded as a burst because *"a still cannot establish gait,
sliding or smooth turns"* and what is in question here is which position a frame draws her at.

## What was recorded

```sh
tools/shot.sh out.png 8 --seed 2609743060 --day 7 --spawn event:checkpoint_hut \
    --walk 9w --press snapshot_burst 1 --invincible --no-save
```

Day 7 of city seed 2609743060 — the seed of the run in
[PLAYTEST-116](../../playtests/PLAYTEST-116.md), and day 7 is
`Tuning.REGION_WALL_FIRST_DAY`, the first day a door stands at all. `--spawn
event:checkpoint_hut` puts her at the first hut on the map, which takes her in immediately; the
burst is pressed a second later, so its three seconds hold the second half of the hold, the
release, and her walking away.

`--invincible` is on because the capture is about *where a frame draws her* and nothing else. It
freezes the day clock, which is why every entry in `run.log` reads `0.0`, and it pins the meter at
zero — so nothing here is evidence about cost, and the HUD says `INVINCIBLE` on every frame.

- `burst-4152123-001/` — 36 PNGs and `burst.json`, which carries each frame's real elapsed time.
  Judge timing from those recorded times rather than from the 12fps target.
- `burst-4152123-001.mp4` — the same frames as a video, for viewing. The PNGs are what to inspect
  frame by frame.
- `run.log` — the run's own trace. `chat checkpoint_hut at (48,43)` opens the hold, `shot burst
  started ... at (47,43)` is this burst, and `checkpoint checkpoint_hut at (48,43), 2.0s, released
  on the east side` is the release inside it. One hold, one release, no second capture.

## What the frames show

Read the `tile` line in the debug readout at the top right — it is her own position, so the frames
say where she is without anybody measuring a sprite.

| frame | elapsed | tile | her |
|---|---|---|---|
| `frame-0013.png` | 1.001s | 47, 43 | not drawn — inside, camera settled on the hut |
| `frame-0015.png` | 1.168s | 47, 43 | not drawn — still inside, still at the entry tile |
| `frame-0016.png` | 1.259s | 50, 44 | drawn, already on the far side of the hut, walking |
| `frame-0018.png` | 1.420s | 49, 44 | drawn, camera easing back onto her |

The frame she is drawn again is a frame where she is already through: there is no frame in this
burst where she is both visible and at the tile she went in at.

## What a burst can and cannot settle

It shows what the screen actually did on one machine at one frame rate, which is the thing that
was reported and the thing no headless run can see. It cannot prove the negative — thirty-six
samples at roughly 12fps do not rule out a frame between two of them.

What pins the ordering is `tests/test_checkpoints.gd`, which drives the two clocks apart on
purpose: it runs drawn frames alone until the hold is over and asserts that none of them has her
visible at the entry point, then that the physics frame owning the release is the one that both
moves her and shows her. Checked against the old behaviour by reinstating it — two failures.
