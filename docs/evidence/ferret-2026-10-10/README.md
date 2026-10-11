# sandy-ferret — the pursuer on foot, 2026-10-10

**Claim.**
1. A torn poster's pursuit marble puts the screen-edge badge up at once. Then it sends a policeman
   on foot (a guardsman from day 9) from off screen, already chasing.
2. An investigating police car stops on its route, outside the junction box, and a policeman (a
   guardsman from day 9) gets out at its door. He holds his ground through his notice, chases her
   and stops her. Then he walks back and gets in, and the car drives on along its route the way it
   was going. From an empty meter, standing still, the whole encounter costs her a lot and the day
   goes on.
3. The hunting night raid's van and the hunting unmarked van stand where they are and each let two
   guardsmen out, who chase her.

**Source revisions and the forcing edits.** Two edits force the triggers. They were made for the
captures only and are never on the branch; they are [forcing.patch](forcing.patch):
- `PosterWalls.TEAR_PRE_BAG` is set to `[true]`, so the run's first tear draws the pursuit marble.
  The committed bag keeps the first tear safe and one pursuit in ten after it.
- `SceneRecipeRuntime` installs every recipe event that answers to heat as its fully heated copy
  (`EventCatalogue.heated(def, Tuning.RESISTANCE_GOAL)`), since a recipe has no resistance progress
  to set; in a played day the copy comes from `GameState.resistance_progress`. It also stands a
  hunting van where the recipe says rather than through the day's placement, since both vans are
  wall rows, kept off every route.

Which revision each picture was taken at:

| Stills | Revision | Patch applied |
| --- | --- | --- |
| `tear-*.png` | `f0831d440772f936099ff1299ce314294de364f1` | the tear half |
| `tear9-*.png`, `car9-*.png`, `van-*.png` | `3142600265f97e0295da6c63a9c02b94416140fe` | all of it |
| `car-stop-*.png`, `car-on-*.png`, `cost-*.png`, `abduction-van-*.png` | `f55c2bb84e3816c9fc6716859914766407d60d62` | all of it |

At `3142600265…` the investigating car's own field was still on while it stood for its man, so
`car9-*.png` show it haloed; nothing else in them differs from the later revision.

All three revisions are on the PR's branch. To rerun, start from the repository root of any clone
and copy this folder's files to a scratch directory first, since `forcing.patch` and the recipes
are not at those revisions. Then set up a disposable checkout and write the stills into a fresh
output directory. `GODOT` names the engine, as `tools/shot.sh` reads it:

```sh
EVIDENCE=$(mktemp -d) && cp docs/evidence/ferret-2026-10-10/{forcing.patch,*.json} "$EVIDENCE"
git fetch origin refs/pull/663/head
REV=f55c2bb84e3816c9fc6716859914766407d60d62   # or the revision the table names
RERUN=$(mktemp -d)/ferret && git worktree add --detach "$RERUN" "$REV"
cd "$RERUN" && git apply "$EVIDENCE/forcing.patch"
OUT=$(mktemp -d)   # the loops below write here
export GODOT=${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}
```

**Not a burst.** A scene recipe owns its playback, and `tools/shot.sh` refuses `--press
snapshot_burst` beside `--recipe`. So each sequence is a set of stills from repeated scripted runs
of one recipe at different `seconds-to-wait`. **Two runs of one recipe do not share a frame
timing**: the same moment can land half a second apart in two runs. So each picture below is
described by what it shows, in the order the encounter happens, with the second it was asked for
alongside.

## 1. A torn poster's policeman, and the guardsman on day 9

Recipe `tear-pursuit.json` is `scene-recipes/tear-slide.json` (day 8, four sheets on one wall),
with a 0.9s push along the wall and then standing (`"walk": "0.9@45@5p"`).
`tear-pursuit-day9.json` is the same on day 9.

```sh
for at in 1.0 1.8 2.4 3.0; do
  tools/shot.sh "$OUT/tear-$at.png" $at --recipe "$EVIDENCE/tear-pursuit.json" \
      --recipe-mode scripted --player-view --no-save --invincible
done
for at in 1.0 2.4 3.0; do
  tools/shot.sh "$OUT/tear9-$at.png" $at --recipe "$EVIDENCE/tear-pursuit-day9.json" \
      --recipe-mode scripted --player-view --no-save --invincible
done
```

- `tear-1.0.png`: the sheet behind her is torn. The policeman's badge is up at the bottom of the
  view, with nothing in the world yet.
- `tear-1.8.png`: he has been created out of sight below her, and his doubled red caret is coming
  into view ahead of him.
- `tear-2.4.png`: he comes up from the road already lunging, with the caret over him.
- `tear-3.0.png`: he reaches her. `--invincible` keeps the day running, so this is the catch that
  would end it.
- `tear9-1.0.png`, `tear9-2.4.png`, `tear9-3.0.png`: the same on day 9 — the badge at the bottom
  of the view, then the checkpoint guard's figure coming up from the road lunging, then on her.

## 2. The investigating car and its man

Recipe `car-stop.json`: seed 11 and context seed 1917501, on day 8. Her start is moved to the
corner of the block at `[1776, 2262]`. A `police_patrol` stands at `[1872, 2512]` with
`route_seed` 3, and drives north up the cross street toward her. She takes a step and stands.
`car-drive-on.json` is the same at camera zoom 1.0, and `investigating-car-day9.json` is the same
on day 9.

```sh
for at in 5.6 6.4 7.6 9.0 10.0 10.6; do
  tools/shot.sh "$OUT/car-stop-$at.png" $at --recipe "$EVIDENCE/car-stop.json" \
      --recipe-mode scripted --player-view --no-save --invincible
done
for at in 10.8 11.2 11.8; do
  tools/shot.sh "$OUT/car-on-$at.png" $at --recipe "$EVIDENCE/car-drive-on.json" \
      --recipe-mode scripted --player-view --no-save --invincible
done
for at in 8.8 9.4 10.4 13.0; do   # without --invincible: the cost
  tools/shot.sh "$OUT/cost-$at.png" $at --recipe "$EVIDENCE/car-stop.json" \
      --recipe-mode scripted --player-view --no-save
done
for at in 7.6 9.0; do
  tools/shot.sh "$OUT/car9-$at.png" $at --recipe "$EVIDENCE/investigating-car-day9.json" \
      --recipe-mode scripted --player-view --no-save --invincible
done
```

- `car-stop-5.6.png`: the car is crossing the junction. It saw her with its body in the box, so it
  does not stop there.
- `car-stop-6.4.png`: it has stopped in its lane past the box, north of the junction.
- `car-stop-7.6.png`: a policeman stands at its door, holding his ground through his notice.
- `car-stop-9.0.png`: he has reached her and stopped her. He stands beside her and does not strike.
- `car-stop-10.0.png`: he walks back to the car the way he came.
- `car-stop-10.6.png`: he is at the car's door, getting in.
- `car-on-a.png` (asked for 10.8s), `car-on-b.png` (11.2s), `car-on-c.png` (11.8s), from three runs
  at the wider zoom, in the order the car moves. First he is back in and the car still stands where
  it stopped, its tail just past the box. Then it has pulled north along its route. Then it is
  further north, leaving the view. It faces north in every frame and never turns round.
- `cost-8.8.png`, `cost-9.4.png`, `cost-10.4.png`, `cost-13.0.png`: **the cost, without
  `--invincible`, from an empty meter at the day's start, standing still.** The meter is about 42 as
  he lunges in and about 74 the moment after he reaches her. It is about 83 as he walks back, and
  about 87 once he is in and the car has gone. The day goes on: the run log has no `lost` line, and
  its chase line reads `policeman_giving_chase reached her and stopped her … | exc 84`.
  At this revision the car's field came back once he was in, so the last two include it passing
  her. At the branch's tip the car stays quiet until it has left her field, so the encounter lands
  less. `tests/test_pursuer_on_foot.gd` measures the whole encounter at the branch's tip, over a
  hand-made lane and real routes on three seeds.
- `car9-7.6.png`, `car9-9.0.png`: the same on day 9. The car is stopped past the box with the
  guardsman at its door, then the guardsman stands beside her through his stop.

The run log reads `an investigating patrol stops at (58,69), 118px from her, and a policeman gets
out`, then `policeman_giving_chase came for her`.

## 3. The hunting vans

Recipe `raid-van.json` uses the same city on day 10, with her at the same corner and `night_raid`
at `[1680, 2416]` on the far sidewalk at the kerb, 150px from her. `abduction-van.json` is the same
with `abduction`.

```sh
for at in 0.6 1.6 2.4 3.2; do
  tools/shot.sh "$OUT/van-$at.png" $at --recipe "$EVIDENCE/raid-van.json" \
      --recipe-mode scripted --player-view --no-save --invincible
done
for at in 0.6 2.4 3.2; do
  tools/shot.sh "$OUT/abduction-van-$at.png" $at --recipe "$EVIDENCE/abduction-van.json" \
      --recipe-mode scripted --player-view --no-save --invincible
done
```

- `van-0.6.png`: the raid's van stands at the kerb. Two guardsmen have got out at its door on her
  side, in the road, and hold their ground through their notice.
- `van-1.6.png`: still holding, with the van unmoved.
- `van-2.4.png`: both lunge at her, with the doubled carets up.
- `van-3.2.png`: one reaches her. `--invincible` keeps the day running, so this is the catch that
  ends it.
- `abduction-van-0.6.png`, `abduction-van-2.4.png`, `abduction-van-3.2.png`: the unmarked van, the
  same way. It stands at the kerb with two guardsmen out at its door, then they lunge, then one is
  on her.

The run log reads `night_raid, standing, at (52,75), 150px from her, and 2 guardsmen get out`,
then two `guardsman_giving_chase came for her` lines.

**Limits.**
- Stills, not motion. Every trigger is forced as above, and everything is in one city.
- These cases are held by `tests/test_pursuer_on_foot.gd`, not by these pictures:
  - every timing;
  - the junction box over real routes;
  - both vans;
  - the whole encounter's cost from an empty meter;
  - the man waiting out a district door's hold.
- Footprint: 29 PNGs, 7 recipe files and the patch, about 3.3 MB.
