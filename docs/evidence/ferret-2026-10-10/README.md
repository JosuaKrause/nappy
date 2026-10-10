# sandy-ferret — the pursuer on foot, 2026-10-10

**Claim.** (1) A torn poster's pursuit marble puts the screen-edge badge up at once and then sends
a policeman on foot from off screen, already chasing; (2) an investigating police car stays on its
road, stops near her, and a policeman gets out at its door, holds his ground through his notice and
then chases her.

**Source revision.** `f0831d44` on `feature/sandy-ferret-on-foot`, with the two local edits below,
which were made for the captures only and are not committed.

**Not a burst.** A scene recipe owns its playback, and `tools/shot.sh` refuses `--press
snapshot_burst` beside `--recipe`, so each sequence is a set of stills from repeated scripted runs
of one recipe at different `seconds-to-wait`: the same deterministic setup and walk each time, the
picture taken at that many seconds of simulation. They show the moments, not the smoothness of the
motion between them.

## 1. A torn poster's policeman

Recipe `tear-pursuit.json`: `scene-recipes/tear-slide.json` (day 8, four sheets on one wall) with a
0.9s push along the wall and then standing (`"walk": "0.9@45@5p"`).

**Local edit:** `PosterWalls.TEAR_PRE_BAG` set to `[true]` so the run's first tear draws the
pursuit marble; the committed bag keeps the first tear safe and one pursuit in ten after it.

```sh
for at in 1.0 1.8 2.4 3.0; do
  tools/shot.sh tear-$at.png $at --recipe docs/evidence/ferret-2026-10-10/tear-pursuit.json \
      --recipe-mode scripted --player-view --no-save --invincible
done
```

- `tear-1.0.png` — the sheet behind her is torn; the policeman's badge is up at the bottom of the
  view with nothing in the world yet.
- `tear-1.8.png` — he has been created out of sight below her: his doubled red caret is coming into
  view ahead of him.
- `tear-2.4.png` — he comes up from the road already lunging, the caret over him.
- `tear-3.0.png` — he reaches her; `--invincible` keeps the day running, so this is the catch that
  would end it.

The run log of these runs reads, in order: `poster tear 1 draws a pursuit marble`, `poster tear: a
policeman sent after her from (58,78), 279px off (a clear run at her)`, `policeman_giving_chase came
for her`.

## 2. The investigating car

Recipe `investigating-car.json`: the same city (seed 11, context seed 1917501), day 8, her start
moved to the corner of the block at `[1776, 2262]`, a `police_patrol` at `[1872, 2512]` with
`route_seed` 3, which drives north up the cross street toward her; she takes a step and stands.

**Local edit:** `SceneRecipeRuntime` installs the recipe's `police_patrol` as its fully heated copy
(`EventCatalogue.heated(def, Tuning.RESISTANCE_GOAL)`), since a recipe has no resistance progress to
set; in a played day the copy comes from `GameState.resistance_progress` past
`Tuning.HEAT_INVESTIGATES_LEVEL`.

```sh
for at in 3.6 4.0 4.4 5.2 6.0; do
  tools/shot.sh car-$at.png $at --recipe docs/evidence/ferret-2026-10-10/investigating-car.json \
      --recipe-mode scripted --player-view --no-save --invincible
done
```

- `car-3.6.png` — the patrol comes up the cross street in its lane.
- `car-4.0.png` — it has stopped on the road 150px from her (its notice reach along a clear line);
  a policeman stands at its door on her side, and the mark over her head says something is coming.
- `car-4.4.png` and `car-5.2.png` — he holds his ground at his stand-off through his notice, in his
  waiting posture, his doubled caret flashing; the car stands.
- `car-6.0.png` — his notice is over and he lunges at her.

The run log reads: `an investigating patrol stops at (58,75), 150px from her, and a policeman gets
out`, then `policeman_giving_chase came for her`.

**Limits.** Stills, not motion; both triggers forced as above; one city, one day (day 8, the
policeman). The guardsman from day 9 and every timing are held by `tests/test_pursuer_on_foot.gd`,
not by these pictures. Footprint: nine PNGs and two recipe files, about 1.0 MB.
