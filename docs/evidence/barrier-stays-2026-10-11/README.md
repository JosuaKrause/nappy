# barrier-stays: the guard's barrier stays where it was built, 2026-10-11

**Claim.** A roadblock's guard who has noticed her sets off from the barrier; the barrier band and its
other guard do not move, bob or go with him; and after he has caught her and walked back, the barrier
is still standing, solid, with the post he left empty.

**Forcing edit.** `forcing.patch` is for the captures only and is never on the branch. It makes
`SceneRecipeRuntime` install a recipe event that answers to heat as its fully heated copy (a recipe
has no resistance progress to set), and place the roadblock row directly at the tile the recipe names
rather than through the day's placement, since no tile near her start is on the roadblock's ordinary
ground. Applied to the branch's `src/dev/scene_recipe_runtime.gd` at the revision this README is
committed with.

**Not a burst.** A scene recipe owns its playback and `tools/shot.sh` refuses `--press snapshot_burst`
beside `--recipe`, so these are stills of repeated runs of one recipe at different seconds; two runs
do not share a frame timing, so each is described by what it shows. She stands still (day 13, seed
11, `--invincible`), the guard set off at once.

```sh
git apply docs/evidence/barrier-stays-2026-10-11/forcing.patch
for t in 0.3 0.6 0.9 1.2 2.0 4.0 22.0; do
  tools/shot.sh guard-$t.png $t --recipe docs/evidence/barrier-stays-2026-10-11/roadblock-guard-leaves.json \
      --recipe-mode scripted --player-view --no-save --invincible
done
```

- `guard-0.3.png` to `guard-1.2.png`: the guard walks north off the barrier toward her while the
  band and the other guard stay at the same screen position in every picture.
- `guard-2.0.png`, `guard-4.0.png`: he has reached her, caret over his head; the barrier is where it was.
- `guard-22.0.png`: he has walked back to the barrier and is gone; the band stands, the other guard
  is at his post, and the post the chaser left is empty.
