# snowy-goose: the explosion badge, the flash and the shake, in the escape city

Dated runtime evidence of one build (never an approved visual reference).

**Claim.** An escape explosion is announced by the screen-edge badge drawn with the mushroom cloud
of `art/events/explosion.svg` (with its distance in meters), goes off a second later out of her
sight, lights the city (not the HUD) and shakes the view a little; the crater it leaves is laid at
the bang, out of her view. **Limits.** One seed and one route; the run carries `--frame-trace`,
which draws the debug readout (the text at the top right) over every frame, and which only
the rig needed to hold `--after`; the shake is read from pixel shifts, not seen in a still; the
brightness and shake size are the builder's first choices, open to the player.

**Source revision.** `cf5d14ce6d6a90b52a123b79b3792970a443ed49` (branch `feature-snowy-goose-explosions`), seed 4242.

**Command.**

```sh
tools/run.sh --seed 4242 --start-escape city --route tunnel --invincible --no-save \
  --frame-trace --after 70 --press snapshot_burst 33.7 --press snapshot_burst 43.7 \
  --press snapshot_burst 59.7
```

Three bursts of 36 frames over 3 s, one per explosion; burst 2 is the one kept in frames.
(An earlier run with the bursts 2.7 s sooner ended as the badge came up and showed no badge frame;
it is not retained.)

## What the stills show (each opened and looked at)

- `burst2-frame-02.png`: before the badge, nothing at the screen edge, her walking on a sidewalk
  towards a street, a column of dark cars at the left.
- `burst2-frame-10.png`: the badge on the right edge, the mushroom cloud in an amber ring with an
  arrow pointing off screen and "24 m" under it; the street is unlit, no crater in view.
- `burst2-frame-16.png`: the last frame before the bang, the badge still reads 24 m, the street unlit.
- `burst2-frame-17.png`: the bang's flash at its peak: the street, sidewalk and walls are
  lighter and warmer (mean luminance 89 against 64), while the HUD (the sleepiness and excitement
  bars, the clock, the pause button) keeps its own brightness; the badge still stands, "20 m".
- `burst2-frame-18.png` and `burst2-frame-19.png`: the flash fading (78, 72), the badge still up (about 20 m), while the view
  wobbles: the shift table in `measurements.txt` shows up to 4 px vertical jitter here.
- `burst2-frame-28.png`: the crater the bang left, a hole in the road at the right edge of the
  view, standing there as she walks towards it.
- `burst2.mp4` is the burst as a clip (the flash and the shake are motion a still cannot show);
  `burst2.json` is its frame timing.

## Measurements (`measurements.txt`)

Per-frame mean luminance of all three bursts: the three explosions peak at 86, 89 and 88 over a
base of about 64; the fainter random distant flashes peak at 70 to 79. Burst 2's frame-to-frame
world shift, and the `run.log` lines for the badges, the explosions and the bursts.

**Retained and why:** the stills and the clip support the claim; the shift and luminance tables
are the numbers behind the flash and the shake; the log lines give the order (badge, then
explosion, then badge gone). The other two bursts' frames and the full log stay in scratch space:
they repeat burst 2.
