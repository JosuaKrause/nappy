# The loose dog is loud while it passes her

2026-09-20. Runtime evidence for M176, the loose dog is past her before it is loud, and three
more rows by feel — the first item, the dog's own timing.

## What the capture is

```sh
tools/shot.sh /private/tmp/m176_still.png 13 --seed 2609743060 --spawn square --walk east \
    --force loose_dog 3 --no-save --day-length 90 --press snapshot_burst 8
```

The playtest's own seed, walking east off a square, with `--force loose_dog 3` owing a dog every
three seconds so a thirteen-second run meets several. **No `--invincible`**, so the meter is real
and the day can end: it does, at 17.4s, after four dogs. `burst-11030609-001/` is the burst the
rig pressed at eight seconds — 36 frames over three seconds, with `burst.json` carrying the
timestamps each frame was actually read back at. `burst-11030609-001.mp4` is `tools/clip.sh`'s
conversion of the same frames, kept beside them rather than instead of them. `run.log` is the
whole run's trace.

**`--force loose_dog 3` is not the density of a real day.** It is how a bounded capture gets more
than one meeting into thirteen seconds; what a day actually places is in the `plan` line at the
top of `run.log`, and how often a route meets one is not a question this capture answers.

## What it shows

`frame-0005.png` is the dog level with the pram. The debug readout reads
`nearest loose_dog active age=5.1/2.2 61px i=30.5` — **active**, not telegraphing, five seconds
into a life whose telegraph is 2.25s, emitting 30.5 of its 39 at 61px. `frame-0008.png` is three
frames later at 29px and `i=37.7`.

The run's own `near` entries say the same thing in order, and none of them carries `(telegraph)`:

```
   7.7  near     loose_dog at (135,6), 139px, exc  9, in  5.6/s (events  6.0)
   8.2  near     loose_dog at (133,6),  74px, exc 13, in 22.1/s (events 25.2)
   8.5  near     loose_dog at (132,6),  40px, exc 19, in 33.6/s (events 35.8)
   8.7  near     loose_dog at (131,6),  19px, exc 24, in 37.8/s (events 38.6)
```

Nine points of meter to twenty-four across one pass, on quiet sidewalk, against an intensity of
39. The run PLAYTEST-116 was written from is the other half of the comparison: every `near` entry
for this row in it reads `(telegraph)` down to 20px, at `events 5.7`.

## What it does not show

The meter, the clock and the day's end are real here, but the capture is one seed, one heading and
one forced interval. It is evidence that the row is loud at the moment it passes, not a
measurement of what a day costs. The numbers that are measurements are in
[`docs/COSTS.md`](../../COSTS.md), regenerated in the same commits as the rows that moved.
