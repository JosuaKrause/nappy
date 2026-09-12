# M100, the inspection as played — the whole hold

[PLAYTEST-57](../../playtests/PLAYTEST-57.md) reported four faults in one two-second hold: *"the
camera makes a huge jump from somewhere to the checkpoint. the checkpoint house disappears. the
camera doesn't move at all after the 2s. also, if I don't move I get sent back afterwards. all this
is incorrect."* This is the same hold after all four, on the same seed and day the report was
played on.

## The run

```
tools/shot.sh /private/tmp/nappy-hold4.png 11 --seed 2199579682 --day 7 \
    --spawn event:checkpoint_hut --walk 2.5e4w4e --invincible \
    --press snapshot_burst 0.2 --press snapshot_burst 5
```

Kept whole at `rig-042329-seed2199579682-v0.8.2-692-g0a86035-dirty/` — `run.log`, the dusk map, and
two `asked/burst-*` sequences with their numbered frames, `burst.json` and the `tools/clip.sh`-made
MP4 beside each.

`--spawn event:checkpoint_hut` puts her beside the first region door of the day rather than at the
home doorstep, which is a thousand pixels and eleven seconds of walking away: the door in the
pictures is the street crossing at tiles (62,15), (62,17) and (62,19) — a hut on each pavement and
the boom on the carriageway between them, and it is the boom she walks into. `--invincible` is what
lets the run last long enough without the meter ending the day; the HUD says `INVINCIBLE` and the
log's day header says so too, so nothing here is a claim about what a day costs.

## What the frames show

`burst-4010896-001` covers 0.03s to 2.92s of its own clock, starting 0.2s into the run — the
crossing whole. Times below are `burst.json`'s recorded `elapsed_seconds`, not a target rate.

- **`frame-0001.png`, 0.028s.** She is already inside: the hut on the north pavement, the boom, the
  hut on the south pavement and both their guards are all drawn, and she is not. The camera is
  moving onto the door rather than sitting anywhere near the world origin, which is where the
  switch used to leave it.
- **`frame-0012.png`, 0.933s.** Mid-hold, the camera settled on the boom. Both huts, both guards
  and the boom are drawn exactly where they were. **The boom's arm lies across the carriageway**,
  its two posts just outside each kerb, with the lanes barred underneath it — the thing the report
  asked for: *"the gate for the cars is too high up. it needs to be further down."*
- **`frame-0026.png`, 2.093s.** The hold is over. She is out on the west side of the boom with the
  pram beside her, the camera has come back onto her, and the whole door is still standing. She is
  a body's width from the boom — well inside the trigger she has just been let out of — and
  nothing takes her back in. That is `ReleaseLatch` doing its job: the release no longer buys its
  safety with distance.

`burst-8726654-002` covers 5.0s to 8.0s of the run, by which time she has walked back out of the
door's reach; it is the ordinary street, and it is kept because the run folder is kept whole.

## What `run.log` shows

**One `chat` line and one `checkpoint` line in eleven seconds** — `chat checkpoint_gate at (62,17)`
at 0.0s and `released on the west side` at 2.0s — with her standing at the door and then walking
past it for the rest of the run. One hold and one `Tuning.CHAT_EXCITEMENT` charge for one crossing,
where a door's three bodies used to take her in one after another and release her in turn, and
where standing on the released side used to be taken in again the next frame.

The frames establish the camera, the drawing and where she comes out. **That she is not taken back
in is established by the log**, not by any single frame: the absence of a second `chat` line is the
thing to read.

## What it does not show

The boom detains her here rather than a hut, because `--spawn event:checkpoint_hut` sets her down
on the carriageway between the two huts and the gate is the nearest body to it. A gate draws no
guard of its own — the guards are at the huts — so in these frames nobody is visibly the one taking
her in. That reads as a gap in the fiction rather than in the mechanic, and it is not something
this capture answers.

Nor does it show the toll charged a second time. Walking out of the door's reach re-arms it and
walking back in costs the same hold again; `tests/test_checkpoints.gd` drives that, and this run
walks away rather than back.
