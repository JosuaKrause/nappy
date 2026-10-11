# sandy-ferret — the pursuer on foot, 2026-10-10

**Claim.** (1) A torn poster's pursuit marble puts the screen-edge badge up at once and then sends
a policeman on foot (a guardsman from day 9) from off screen, already chasing; (2) an investigating
police car stops on its route — outside the junction box — and a policeman (a guardsman from day 9)
gets out at its door, holds his ground through his notice, chases her, stops her at a cost, walks
back and gets in, and the car drives on; (3) the hunting night raid's van stands and lets two
guardsmen out, who chase her.

**Source revisions and the forcing edits.** Two edits, made for the captures only and never in
the branch, force the triggers; they are [forcing.patch](forcing.patch): `PosterWalls.TEAR_PRE_BAG`
set to `[true]` so the run's first tear draws the pursuit marble (the committed bag keeps the first
tear safe and one pursuit in ten after it), and `SceneRecipeRuntime` installing every recipe event
that answers to heat as its fully heated copy (`EventCatalogue.heated(def, Tuning.RESISTANCE_GOAL)`,
since a recipe has no resistance progress to set; in a played day the copy comes from
`GameState.resistance_progress`) and standing a hunting van where the recipe says rather than
through the day's placement (the raid's van is a wall row, kept off every route). The day-8 tear
stills (`tear-*.png`) were taken at `f0831d440772f936099ff1299ce314294de364f1`, with the tear half
of the patch; everything else at `3142600265f97e0295da6c63a9c02b94416140fe`, with all of it. Both
are on the PR's branch. From the repository root of any clone, with this folder's files copied to a
scratch directory first (`forcing.patch` and the recipes are not at those revisions), set up a
disposable checkout and write the stills into a fresh output directory; `GODOT` names the engine
as `tools/shot.sh` reads it:

```sh
EVIDENCE=$(mktemp -d) && cp docs/evidence/ferret-2026-10-10/{forcing.patch,*.json} "$EVIDENCE"
git fetch origin refs/pull/663/head
REV=3142600265f97e0295da6c63a9c02b94416140fe   # f0831d440772f936099ff1299ce314294de364f1 for tear-*.png
RERUN=$(mktemp -d)/ferret && git worktree add --detach "$RERUN" "$REV"
cd "$RERUN" && git apply "$EVIDENCE/forcing.patch"
OUT=$(mktemp -d)   # the loops below write here
export GODOT=${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}
```

**Not a burst.** A scene recipe owns its playback, and `tools/shot.sh` refuses `--press
snapshot_burst` beside `--recipe`, so each sequence is a set of stills from repeated scripted runs
of one recipe at different `seconds-to-wait`. **Two runs of one recipe do not share a frame
timing**, so a sequence shows its moments in order but the second figures are not comparable across
runs: the same moment can land half a second apart.

## 1. A torn poster's policeman, and the guardsman on day 9

Recipe `tear-pursuit.json`: `scene-recipes/tear-slide.json` (day 8, four sheets on one wall) with a
0.9s push along the wall and then standing (`"walk": "0.9@45@5p"`). `tear-pursuit-day9.json` is the
same on day 9.

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

- `tear-1.0.png` — the sheet behind her is torn; the policeman's badge is up at the bottom of the
  view with nothing in the world yet.
- `tear-1.8.png` — he has been created out of sight below her: his doubled red caret is coming into
  view ahead of him.
- `tear-2.4.png` — he comes up from the road already lunging, the caret over him.
- `tear-3.0.png` — he reaches her; `--invincible` keeps the day running, so this is the catch that
  would end it.
- `tear9-1.0.png`, `tear9-2.4.png`, `tear9-3.0.png` — day 9: the badge at the bottom of the view,
  then the checkpoint guard's figure coming up from the road lunging, then on her.

## 2. The investigating car and its man

Recipe `car-stop.json`: seed 11, context seed 1917501, day 8, her start moved to the corner of the
block at `[1776, 2262]`, a `police_patrol` at `[1872, 2512]` with `route_seed` 3, which drives north
up the cross street toward her; she takes a step and stands. `investigating-car-day9.json` is the
same on day 9.

```sh
for at in 5.6 6.4 7.6 9.0 10.0 10.5; do
  tools/shot.sh "$OUT/car-stop-$at.png" $at --recipe "$EVIDENCE/car-stop.json" \
      --recipe-mode scripted --player-view --no-save --invincible
done
for at in 8.8 9.3; do   # without --invincible: the cost
  tools/shot.sh "$OUT/cost-$at.png" $at --recipe "$EVIDENCE/car-stop.json" \
      --recipe-mode scripted --player-view --no-save
done
for at in 7.6 9.0; do
  tools/shot.sh "$OUT/car9-$at.png" $at --recipe "$EVIDENCE/investigating-car-day9.json" \
      --recipe-mode scripted --player-view --no-save --invincible
done
```

- `car-stop-5.6.png` — the car has driven on through the junction: it saw her with its body in the
  box, so it stops only once clear of it, north of the junction.
- `car-stop-6.4.png` — stopped in its lane past the box; a policeman stands at its door.
- `car-stop-7.6.png` — he has reached her and stopped her: standing beside her, not striking.
- `car-stop-9.0.png` — he runs back to the car the way he came.
- `car-stop-10.0.png` — another run, a moment earlier in the same sequence: he is turning back
  from her, the car still standing.
- `car-stop-10.5.png` — he is back in and the car has driven on north along its route, out of the
  view; it never turned round.
- `cost-8.8.png`, `cost-9.3.png` — **the cost, without `--invincible`**: the meter at 62 as he
  lunges in (his field and the car's have been charging her as she stood), 95 the moment after he
  reaches her. She was already high, so the stop carries her to the cap; this run is lost crying a
  moment later, to him — "if the excitement meter is already high it can be lethal" (inbox #669).
- `car9-7.6.png`, `car9-9.0.png` — day 9: the car stopped past the box with the guardsman at its
  door, then the guardsman standing beside her through his stop.

The run log reads: `an investigating patrol stops at (58,69), 118px from her, and a policeman gets
out`, then `policeman_giving_chase came for her`; without `--invincible`, the `lost` line names
`policeman-giving-chase`.

## 3. The hunting raid's van

Recipe `raid-van.json`: the same city on day 10, her at the same corner, `night_raid` at
`[1680, 2416]` on the far sidewalk at the kerb, 150px from her.

```sh
for at in 0.6 1.6 2.4 3.2; do
  tools/shot.sh "$OUT/van-$at.png" $at --recipe "$EVIDENCE/raid-van.json" \
      --recipe-mode scripted --player-view --no-save --invincible
done
```

- `van-0.6.png` — the van stands at the kerb; two guardsmen have got out at its door on her side,
  in the road, holding their ground through their notice.
- `van-1.6.png` — still holding, the van unmoved.
- `van-2.4.png` — both lunge at her, the doubled carets up.
- `van-3.2.png` — one reaches her; `--invincible` keeps the day running, so this is the catch that
  ends it.

The run log reads: `night_raid, standing, at (52,75), 150px from her, and 2 guardsmen get out`, then
two `guardsman_giving_chase came for her` lines. The unmarked van (`abduction`) hunts on foot the
same way and is held by `tests/test_pursuer_on_foot.gd`, not pictured.

**Limits.** Stills, not motion; every trigger forced as above; one city. Every timing, the
junction box over real routes, both vans, and the stop's cost when she stands or walks away are
held by `tests/test_pursuer_on_foot.gd`, not by these pictures. Footprint: twenty-one PNGs, five
recipe files and the patch, about 2.4 MB.
