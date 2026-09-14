# M131, pigeons exist before they are seen — the flock is on the ground, then it goes up

One `tools/shot.sh` burst on `feature/m131-pigeons-on-the-ground`, seed 4242, day 1, taken from a
worktree based on `d5332fb5` (`origin/main`'s tip at capture time) with this milestone's changes
applied:

```
tools/shot.sh /private/tmp/m131-flock.png 8 --seed 4242 --day 1 --spawn event:pigeon_flock \
    --invincible --press snapshot_burst 0.8
```

Kept whole at `rig-202425-seed4242-v0.10.1-dirty/` — `run.log`, `maps/day01-attempt1.png` (the
day's own route map) and `asked/burst-3744147-001/` with its 36 numbered frames, `burst.json` and
the `tools/clip.sh`-made `burst-3744147-001.mp4` beside it. **A burst rather than a still because
the subject is motion**: eleven birds pecking on a sidewalk and then leaving it.

`--invincible` is right here — the subject is what the birds do, not what they cost — and it has
two consequences worth knowing before reading anything off these frames. The day clock never
moves, so every line in `run.log` is stamped `0.0` and the frame times have to come from
`burst.json`; and the meter never rises, so the HUD reads `incoming 0.00/s` throughout. What the
flock is actually emitting is in the log line below instead.

## What the run actually did

`run.log`: day 1, act 1, `pigeon_flock x5` in the day's plan — five **tile** placements, which is
the whole milestone. `--spawn event:pigeon_flock` finds one in that plan and stands her at
`DevRig.first_event_position()`'s own offset from it, at tile `(62,56)`:

```
   0.0  near     pigeon_flock (telegraph) at (60,55), 72px, exc 0, in 0.0/s (crowd 0.0, events 3.4), sleep 0
```

Two things in that one line. The flock is **at a place** — `(60,55)`, a sidewalk tile the day
chose — rather than at a lead in front of her, and at 72px it is emitting **3.4/s**, which is a
flock on the ground: `intensity` 42 damped to `Tuning.TELEGRAPH_INTENSITY_FRACTION` (0.15) by
`EventDef.quiet_until_noticed` and then shared out over eleven birds and their falloff. The
`events` term in the same line is what a café frontage costs from across a street.

The rig aims her 0.6 of the row's `outer_radius` away — 101px for this row — and then snaps that to
the nearest walkable tile centre, which here lands her at the 72px the log reports. Either number is
**inside** the flock's own 150px trigger, so the birds notice her on the first frame and the capture
is the telegraph and the burst rather than the silent wait before them. That is a property of the flag, written down in
`DevRig.first_event_position()`: no rig can photograph a waiting row's silence, for this row or for
`alley_robbery`.

## The frames

Times are `burst.json`'s own `elapsed_seconds`, measured from the first frame of the burst; the
flock's own age is the debug readout's `nearest` line at the right of each frame.

- **`asked/burst-3744147-001/frame-0002.png`** (0.09s, readout `pigeon_flock telegraph age=0`) —
  eleven birds standing on the sidewalk beside her, wings down, each with its own tight shadow on
  the paving. This is the frame the milestone is about: the flock is a patch of sidewalk she can
  see, not something that arrived in front of her.
- **`asked/burst-3744147-001/frame-0011.png`** (0.84s, still `telegraph`) — the same birds a
  little further along the pavement, still down. They shuffle at `BIRD_GROUND_SPEED` (7px/s) rather
  than standing frozen, which is what makes eleven of them read as alive while nothing has
  happened yet.
- **`asked/burst-3744147-001/frame-0014.png`** (1.10s, `pigeon_flock active age=1.97`) — up. The
  1.7s telegraph has run out and every bird is off the ground, wings out, its shadow smaller and
  fainter under it.
- **`asked/burst-3744147-001/frame-0036.png`** (3.00s, `active age=3.71`) — the last frame of the
  burst: the flock is high and wheeling out over the street, shadows small, each bird on its own
  heading.

`burst-3744147-001.mp4` is the same 36 frames as video, for watching the transition rather than
stepping it. Frame intervals run 60–110ms against the burst's own 12fps target, which is capture
overhead on a windowed debug build and says nothing about the animation.
