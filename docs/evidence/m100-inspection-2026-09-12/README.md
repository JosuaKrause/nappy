# M100, the inspection as played — the whole hold, twice

[PLAYTEST-57](../../playtests/PLAYTEST-57.md) reported four faults in one two-second hold: *"the
camera makes a huge jump from somewhere to the checkpoint. the checkpoint house disappears. the
camera doesn't move at all after the 2s. also, if I don't move I get sent back afterwards. all this
is incorrect."* This is the same hold after all four, on the same seed and day the report was
played on.

## The run

```
tools/shot.sh /private/tmp/nappy-hold2.png 9 --seed 2199579682 --day 7 \
    --spawn event:checkpoint_hut --walk east --invincible \
    --press snapshot_burst 0.2 --press snapshot_burst 4
```

Kept whole at `rig-035107-seed2199579682-v0.8.2-691-g12c5265-dirty/` — `run.log`, the dusk map, and
two `asked/burst-*` sequences with their numbered frames, `burst.json` and the `tools/clip.sh`-made
MP4 beside each.

`--spawn event:checkpoint_hut` puts her beside the first region door of the day rather than at the
home doorstep, which is a thousand pixels and eleven seconds of walking away: the door in the
pictures is the street crossing at tiles (62,15), (62,17) and (62,19) — a hut on each pavement and
the boom on the carriageway between them. `--walk east` keeps her walking into it, so the run
contains two complete crossings rather than one. `--invincible` is what lets the run last long
enough to hold both without the meter ending the day; the HUD says `INVINCIBLE` and the log's day
header says so too, so nothing here is a claim about what a day costs.

## What the frames show

`burst-3093602-001` covers 0.02s to 2.95s of its own clock, starting 0.2s into the run — the first
crossing whole. Times below are `burst.json`'s recorded `elapsed_seconds`, not a target rate.

- **`frame-0001.png`, 0.019s.** She is already inside: the guard's hut on the north pavement, the
  boom, the hut on the south pavement and both their guards are all drawn, and she is not. The
  camera is moving onto the door rather than sitting anywhere near the world origin, which is where
  the switch used to leave it.
- **`frame-0012.png`, 0.923s.** Mid-hold, the camera settled on the boom. Both huts, both guards
  and the boom are drawn exactly where they were. **The boom's arm lies across the carriageway**,
  its two posts just outside each kerb, with the lanes barred underneath it — the thing the report
  asked for: *"the gate for the cars is too high up. it needs to be further down."*
- **`frame-0024.png`, 1.918s.** She is out, on the far side of the crossing, and the camera has
  come back onto her. The door is still standing behind her.
- **`frame-0030.png`, 2.429s.** Walking east has taken her back into the door and the second hold
  has begun — the toll working in both directions, which is what it is for.

`burst-6823086-002` covers the end of that second hold and its release, from 4.0s of the run.

## What `run.log` shows

Four lines for two crossings: `chat checkpoint_gate at (62,17)` and `checkpoint ... released on the
west side`, then the same pair released on the east side. **One hold and one
`Tuning.CHAT_EXCITEMENT` charge per crossing**, where a door's three bodies used to take her in one
after another and release her in turn.

## What it does not show

The boom detains her here rather than a hut, because `--spawn event:checkpoint_hut` sets her down
on the carriageway between the two huts and the gate is the nearest body to it. A gate draws no
guard of its own — the guards are at the huts — so in these frames nobody is visibly the one taking
her in. That reads as a gap in the fiction rather than in the mechanic, and it is not something
this capture answers.
