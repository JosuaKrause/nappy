# barrier-stays: the guard's barrier stays where it was built, 2026-10-11

**Claim.** A roadblock's guard who has noticed her sets off from the barrier; the barrier and the
other guard stay where they were while he chases; and once she has outrun him and he has walked
away, the barrier is still standing, solid, with the post he left empty. The pictures are taken with
the barrier as its own y-sorted node, so what is drawn over or under it does not change with where
he walks.

**Forcing edit.** `forcing.patch` is for the captures only and is never on the branch. It makes
`SceneRecipeRuntime` install a recipe event that answers to heat as its fully heated copy (a recipe
has no resistance progress to set), and place the roadblock row directly at the tile the recipe names
rather than through the day's placement, since no tile near her start is on the roadblock's ordinary
ground. Applied to the branch's `src/dev/scene_recipe_runtime.gd` at the revision this README is
committed with.

**Not a burst.** A scene recipe owns its playback and `tools/shot.sh` refuses `--press snapshot_burst`
beside `--recipe`, so these are stills from repeated runs of one recipe at different seconds; two runs
do not share a frame timing, so each picture is described by what it shows.

**The clock reads 3:00 in every picture.** `--invincible` holds the day's clock still ("the clock never
moves"), so it says nothing about elapsed time; the second in each file name is the second asked of
the recipe's own playback. The recipe is day 13, seed 11: she stands still for 0.5s, runs east for
1.5s (running is what shakes a chaser off), then stands still.

```sh
git apply docs/evidence/barrier-stays-2026-10-11/forcing.patch
for t in 0.3 0.7 1.2 2.0 3.5 25.0; do
  tools/shot.sh guard-$t.png $t --recipe docs/evidence/barrier-stays-2026-10-11/roadblock-guard-leaves.json \
      --recipe-mode scripted --player-view --no-save --invincible
done
```

- `guard-0.3.png`: before he sets off. The barrier is an end-on column across the street, and a
  guard stands on the south sidewalk on each side of it, one to the west and one to the east. She
  is on the sidewalk to the north.
- `guard-0.7.png`: the east guard has stepped out to the north end of the barrier with his red caret
  up, heading for her. The west guard has not moved, and the barrier is where it was.
- `guard-1.2.png`: he is on the north sidewalk, walking toward her, well away from the barrier; she
  has started running east. The barrier stands in the same place on the street with the west guard
  beside it.
- `guard-2.0.png`: she has outrun him. He has no caret and walks away west along the north
  sidewalk. The barrier stands with the west guard beside it.
- `guard-3.5.png`: he has walked farther west. The barrier and the west guard are unchanged.
- `guard-25.0.png`: the chaser is not in the frame. The barrier stands where it was built with the
  west guard beside it, and the east post he left is empty.

The camera follows her, so the barrier slides across the frame as she runs; what the pictures show
is that it does not move on the street. The still pictures cannot show the stride bob the jump
symptom was; `tests/test_barrier_stays.gd` holds that, frame by frame.
