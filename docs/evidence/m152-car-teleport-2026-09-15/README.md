# M152 — cars teleport at their turns

Runs of `tests/probes/m152_car_jumps.gd`, which walks a rig day on three seeds over days 1 and 13
and records every frame in which a car moves further than twice the fastest car's own frame step —
classified by what the car was doing, and by whether either end of the move was inside the play
viewport (`Tuning.VIEW_HALF_EXTENT`, 320 × 180 px of world) around the crowd field's centre, which
is where the camera is.

Every file here is the whole output of

```sh
tools/test.sh probes/m152_car_jumps.gd
```

run from a worktree checked out at the commit the file is named for.

| file | tree |
|---|---|
| `probe-accfa867.txt` | the base: the commit PR #196 was merged onto, before any of 2026-09-15's merges |
| `probe-454d4d5c.txt` | after PR #200, M146, a pocketed agent stands then leaves unseen |
| `probe-47c864f9.txt` | after PR #203, M129, the four rules |
| `probe-d5d784f2.txt` | after PR #204, M149, atlases by group — the `main` the playtest was run on |
| `probe-after-the-fix.txt` | this branch, with a turn's landing no longer merging to the back of its lane |

`PROBE m152 in-view jumps:` on the last line of each is the one number the bisection turns on. The
`turn-landed` row is the defect itself: every entry in it is a landing flung backwards, and the
`retreat:` lines under each rig day say how far and what the exit lane looked like at the time.

**A recycle is a teleport by construction and is legal out of sight**, which is why the classes are
counted separately rather than summed: the `recycle` row is hundreds of moves per run and not one of
them is a defect, because every one happens outside the viewport.

## The bursts

Three PNG bursts, thirty-six frames over three seconds each, with the `burst.json` timing record and
the MP4 `tools/clip.sh` makes from it, and the whole run log beside them.

| folder | command |
|---|---|
| `before-d5d784f2/` | `tools/shot.sh out.png 10 --seed 91117 --day 13 --spawn closure:0 --press snapshot_burst 3 --invincible`, run from a worktree at `d5d784f2` |
| `after-the-fix/` | the same command on this branch |
| `after-the-fix-busy-junction/` | `tools/shot.sh out.png 10 --seed 4242 --day 1 --spawn closure:0 --press snapshot_burst 3 --invincible` on this branch |

`--spawn closure:0` stands the camera at the junction outside a closed street's barrier, which is
where a car has to turn and is the same kind of place the probe's own watch points are.

**What the bursts can and cannot say.** A landing whose booked spot has been closed up on is roughly
one turn in seventy, so three seconds of one junction is not where it is caught — that is the
probe's job and the probe's numbers are the measurement. What the bursts are for is the other half:
that traffic at a barrier reads right frame by frame. The day 13 pair is the same junction on both
builds, with the cars that have run out of road queued at the barrier and traffic crossing behind
them; the day 1 burst is the busiest closure junction the game has, where cars are arriving,
crossing and turning continuously.
