# M149 — Atlases by group: what the desktop measured

The desktop table's own walk, the same one M139's atlas was measured on:

```sh
tools/shot.sh out.png 20 --seed 3265820891 --day 1 --walk 3s17e
```

`draws`, `primitives` and `fps` are the mean of the run log's `frame` entries from two seconds
in — the first entry covers the boot frame and is left out. `before/` is the branch's base
commit, `after/` is the branch with every group packed; each folder holds the whole run folder
the rig printed, plus the 20-second still it wrote.

| | draws | primitives | fps |
|---|---|---|---|
| before | 566 | 4546 | 112 |
| every group packed | 560 | 4539 | 108 |

About six calls. The crowd was already one atlas (M139), the ground is a `TileMapLayer` that
batches a screen of tiles into one call whether or not its sources share a texture, and the
walk's own twenty seconds put only a few event families and a handful of props in front of the
camera at a time — so what is left to save on this rig is small, and the fps difference is
inside the noise of two windowed runs. **The reason for the milestone is the composite rather
than this number** *(Playtest 76: "it is good to have everything built into atlases so the
composite doesn't have to deal with multiple image sources")*, and the reading the player asked
for is the laptop's, not this one's.

## What the run log now says

Both run folders were written by a build that logs every picture. `after/`'s log carries a
`texture` line per transfer read from disk, one per atlas as it becomes ready — with its group,
its picture count, its pixel size, the milliseconds from the request and the worker's own share
— and one per atlas released. The ground's line reads:

```
ground packed: 58 sources over 57 pictures into 2030x100 in 0.3 ms
```

against the 178 ms the same boot spends warming its pictures, which is why the ground's pack
stays synchronous inside `GroundLayers.build_tile_set()` rather than moving to the worker.

## The still

`street-day12.png`, taken with:

```sh
tools/shot.sh street-day12.png 6 --seed 3265820891 --day 12 --spawn zone:0 --invincible
```

Day 12 rather than day 1 because litter and garbage sacks are placed off the day's degradation
and day 1 has almost none. In frame: loose litter and damage stencils across both sidewalks,
two garbage sacks and a pile, construction barriers, a park's grass and clumps in the
lower right, the mother and pram at the crossing, and a police car on the carriageway — every
family in the milestone drawing from its own packed group. `--invincible` holds the day so the
capture cannot land on a summary screen; the HUD says so.
