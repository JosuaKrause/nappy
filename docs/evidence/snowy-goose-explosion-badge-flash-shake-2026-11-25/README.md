# snowy-goose: the explosion badge, the flash and the shake, in the escape city

Dated runtime evidence of one build (never an approved visual reference). It supersedes the earlier
capture in this folder, which was taken with the explosion set off at 520 px.

**Claim.** An escape explosion is announced by the screen-edge badge drawn with the mushroom cloud
of `art/events/explosion.svg` and its distance (about 42 m, the 889 px it is set off at), goes off
a second later out of her sight, lights the city (not the HUD) and shakes the view a little, though
the bang is far out of her noise's reach; the crater is laid at the bang, out of her view.
**Limits.** One seed and one route; the run carries `--frame-trace`, which draws the debug readout
(the text at the top right) over every frame and which the rig needs to hold `--after`; the shake is
read from pixel shifts, not seen in a still; the explosion itself is out of sight, so what a frame
shows of it is the badge, the light and the shake; the brightness and shake size are the builder's
first choices, open to the player.

**Source revision.** `1d2f33094` (branch `feature-snowy-goose-explosions`), seed 4242.

**Command.**

```sh
tools/run.sh --seed 4242 --start-escape city --route tunnel --invincible --no-save \
  --frame-trace --after 30 --press snapshot_burst 11.4 --press snapshot_burst 22.7
```

The first burst (36 frames over 3 s) is the one kept. The second burst, and four earlier runs
whose bursts began too soon or too late to hold a bang, are not retained.

## What the frames show (each opened and looked at)

- `burst-frame-0001.png`: the badge at the right edge, the mushroom cloud in an amber ring with an
  arrow pointing off screen and "42 m" under it, and the crater of an earlier explosion at the
  bottom left; the street is unlit.
- `burst-frame-0003.png`: the bang's flash at its peak, about 0.17 s into the burst: the street,
  sidewalks and walls are lighter and warmer (mean luminance 91 against 66; a block of the left half
  129 red against 89), while the HUD keeps its own brightness; the badge reads "40 m", the explosion
  is out of sight.
- `burst-frame-0004.png` and `burst-frame-0006.png`: the flash dying away (79, then 67), the badge
  still up while the view is shaken.
- `burst.mp4` is the burst as a clip (the flash and the shake are motion a still cannot show);
  `burst.json` is its frame timing.

## Measurements (`measurements.txt`)

Per-frame mean luminance (it peaks at 91 over a base of 66, back to base within about 0.5 s) and the
world's frame-to-frame shift in px (dx, dy) of a block of the view: the first five entries show
the shake, up to 3 px across and 2 px down about her steady scroll, starting with the flash; from
the sixth on the shift is her walking (8 px a frame down the screen). The nearest explosion was
about 889 px away, further than the 520 px its noise reaches, so the shake is the new reach
(`EventCatalogue.FINALE_EXPLOSION_FELT_WITHIN`), not the noise. `runlog-excerpt.txt` gives the run
log's lines for the badge and the burst.

**Retained and why:** the four frames and the clip support the claim; the table is the numbers
behind the flash and the shake; the log lines give the order (badge up, burst, badge gone as the
bang goes off).
