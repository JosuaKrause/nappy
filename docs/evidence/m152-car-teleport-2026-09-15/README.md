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

`PROBE m152 in-view jumps:` on the last line of each is the one number the bisection turns on.

**A recycle is a teleport by construction and is legal out of sight**, which is why the classes are
counted separately rather than summed: the `recycle` row is hundreds of moves per run and not one of
them is a defect, because every one happens outside the viewport.
