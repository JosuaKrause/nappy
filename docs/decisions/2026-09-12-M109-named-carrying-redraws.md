## M109 — Named carrying redraws — 2026-09-12

PLAYTEST-65 rejected the carrying mother without naming a particular defective facing. Source
review identified an upright bundle, blended forearms and excessive baby visibility from the
rear. The request covered all five authored views, both gait frames and their west mirrors.
The player's follow-up requested the current build in a PR and names for every version.

The carrying versions have these discussion names:

| Version | Name | Distinguishing result |
| --- | --- | --- |
| A | Upright bundle | The prior runtime carrying set, retained with the original comic-rig evidence. |
| B | Round silhouette | A clearer cradle, but a large head, broad coat and short legs. |
| C | Alternating stride | Opposed A/B leg positions, still with the round proportions. |
| D | Matched proportions | A localized edit of the pushing atlas: adult body and gait retained, arms and baby changed. |

D supplied the ten runtime carrying textures before E's leg correction. Generating a whole new person repeatedly
changed her proportions despite explicit instructions and identity references. Editing the
existing pushing atlas narrowed the change to the cradle and kept the same short hair, small
head, red parka, long jeans and practical shoes. The baby is held across the torso, with
hands and supporting forearms separated from the blanket; direct rear views hide the baby
behind her body. Native and enlarged comparisons include all eight runtime directions and
both gait frames next to the pushing mother. The raw outputs, exact prompts and named
comparisons are retained in `docs/evidence/comic-carrying-redraw-2026-09-12/`; B and C are
comparison evidence, not style references. A remains in `docs/evidence/comic-rig-2026-09-12/`.

The previous graphics PR was merged independently while this work ran. The next branch
incorporated main `83a60d1`, with local tip `fead323` and common ancestor `62d1c34`.
Incoming main had no tree changes beyond that ancestor, so the merge was conflict-free and
preserved the already reviewed café facing, idle frames, tree-bed layering and gameplay.
No numbered records collided. This batch is proposed separately and remains open for review.

The player then reported that most A/B gait pairs looked like the same picture. D's native
and enlarged sheets established identity and support but did not establish sufficient stride
contrast. The existing named versions remain unchanged; E, clear strides, supplies the correction
recorded above. Version names and gait-frame letters identify different axes.

The player requested D's full walking rollout in all eight directions. The frozen D textures
are assembled in `docs/evidence/comic-carrying-redraw-2026-09-12/rollout/`: a repeating GIF,
individual animation frames and a four-phase static sheet. These use the exact registered
pixels, runtime west mirrors and 190ms frame intervals at walking speed, enlarged by nearest
neighbor. They expose D's existing two-frame motion; they are source animation previews,
not gameplay captures or evidence that the gait finding is fixed.

The integrated checkout passed import/boot, 783 focused checks across visuals, stroller,
presentation mode and orientation, and 665 visual checks with `--svg`. The tests check loading,
anchors and selection; they do not establish visibly distinct steps. D's seed-4242 capture used
`--start-escape floor:2 --walk 1e1w1e1w --press snapshot_burst 1 --invincible`, finishing at six
seconds. Its complete 36-frame burst records 2.983 seconds; the frames show travel and opposing
profile views. The whole run, frames, timing sidecar, MP4 and final still are preserved under
`docs/evidence/archive/session-captures/2026-09-12/rig-165450-seed4242-v0.8.2-807-g7f3dcb5-dirty/`.
The dirty changes were documentation only. This records D and does not verify E or every facing.
