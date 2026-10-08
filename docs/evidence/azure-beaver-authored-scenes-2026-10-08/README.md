# Authored street scenes

The ten pairs of start and later stills show the explicitly loaded task and station
stretches, their pedestrians, day wear and task targets. They use clean source
`deb809f1f5ec342521139868eb336908192f99d8`, Godot 4.7.2, run seed 11, and the
recipe hashes and exact capture ticks in the adjacent manifests. These stills establish
layout and visible contents; they do not establish smooth motion or absence of pop-in.
The automated crowd check plays all ten stretches and observes every recycle separately.
The adjacent `*-outcome.json` files retain the passing observations, completion and empty
void/jump reports from each headless playback. Capture logs contain no engine errors.
Every pair was visually inspected; images retain whole frames, including HUD and void.

Capture command, from that checkout:

```sh
recipes=()
for file in scene-recipes/task-*.json scene-recipes/station-door-corner.json; do
    recipes+=(--recipe "$file")
done
tools/scene-recipes.sh "${recipes[@]}" --output /tmp/scene-preview --screenshots
```

Fetch the durable PR ref before checking out a recorded source revision:

```sh
git fetch origin refs/pull/592/head
```

`day7-caught.json` retains the contrary result while completing this change: the earlier
10.4-second day 7 playback completed its task at tick 292, then stopped at tick 293 because
the sent guard caught her under the merged warning rules. Its exact recipe hash and observed
states are retained. That run used the loader checkpoint's runtime sources (`5756ed8a`);
test files were being edited and the source tree was not a clean capture checkout. No source
hashes were recorded at that moment. The final recipe ends at tick 292 (9.74 seconds at the
game's 30 physics ticks per second), with both task completion and the seen-cat assertion
checked there. The ordinary warning, chase and loss behavior is unchanged. This is a scene
endpoint, not evidence that standing beside the van is safe.

These preview stills predate the integrated trailer camera and task-arrow behavior; their
claim remains the authored layout and visible contents recorded above.

`covered-movie-*` records a failed motion capture at clean source
`f1ac0061e43800360715c6458433aad6f7eec760`, using:

```sh
tools/record.sh --out azure-beaver-day7.mp4 --recipe scene-recipes/task-07-package.json --recipe-mode scripted
```

The simulation completed every assertion without engine errors, but visual inspection found
frozen movie frames: one PNG hash repeats 456 times and another 124 times. The selected
decoded frames at approximately 0.5 and 8.5 seconds show the resulting jump. Settings and
raw frame hashes preserve provenance; the whole movie remains local. This is a capture
failure, not crowd-motion evidence. It is retained beside the successful repeat as the
counterexample that the recording correction has to change.

`motion-day7-*` records that successful repeat at clean source
`4e8ec04e3dfaff91347ae576d9efb0e9f8f0baa5`, while the native game window was covered by
another opaque application, using:

```sh
tools/record.sh --out azure-beaver-day7-motion-after-580-direct.mp4 --recipe scene-recipes/task-07-package.json --recipe-mode scripted
```

Godot rendered all 584 frames at 60 FPS for a 9.73-second movie. Every adjacent frame has a
different whole-frame SHA-256 hash, so the longest identical run is one frame (0.017 seconds),
and visual inspection of the selected 0.5-, 4.5- and 8.5-second frames shows the player, camera
and crowd in different positions as the mark becomes the van task and the van is reached. The
manifest completes all twelve observations without a violation: the visible moving activity
changes from three walkers and no car initially to five walkers and one car finally, and the
route event first appears at physics tick 181. Settings, all frame hashes, the resolved manifest
and the engine log preserve provenance; the whole movie remains local at
`build/records/azure-beaver-day7-motion-after-580-direct.mp4`. This proves continuous motion for
this one covered-window day 7 playback; it does not claim a moving review of every authored scene.

`fire-truck-crying.json` and its one-line run-log excerpt retain a separate failure at clean
source `f1ac0061e43800360715c6458433aad6f7eec760`.
`tools/scene-recipes.sh --output /tmp/all-saved-scenes` stops on the
unchanged full-city fire-truck recipe: its waiting route reaches excitement 100 and loses
to crying at tick 261, before the required truck arrival observations. This result does
not affect the ten passing stretch playbacks.

`fire-truck-repaired.json` records the corrected full-city scene at clean source
`9dd9f1bfc4debf38539ead27801fbb84d4319db7`, run with:

```sh
tools/scene-recipes.sh --recipe scene-recipes/fire-truck.json --output /tmp/fire-truck-final
```

The route keeps its 2.8 seconds west toward the fire, then walks north for 2.5 seconds and
returns south for 1.7 seconds. She stops about 84 pixels north of the old waiting position,
after retreating farther during the loud approach. Ordinary danger remains active. The scene
completes at tick 414, with the initial fire checks unchanged, the engine both visible and
moving at tick 114, visible again at tick 294, and at its exact kerb at tick 414. Duration
13.8 seconds and capture time 12.8 seconds are unchanged. There is no invincibility, initial
meter adjustment or gameplay change. This is headless action evidence; no new picture is claimed.

The two small intermediate manifests retain why the approach assertion changed. With the
same retreat route and the original tick-294 movement check, the engine is already parked
(`fire-truck-early-arrival.json`). A visibility check at tick 120 finds its center just outside
the camera while she retreats (`fire-truck-outside-view.json`); both movement and visibility
are checked together at the earlier observed tick 114 in the final recipe. Those trials use
the runtime from `f337560a`, with the recipe under edit; their exact recipe hashes are retained.

## Production package audit

`published-v0.25.5-recipes.txt` is the complete development-recipe path subset found by
`tools/audit-pck.sh --list` in the published v0.25.5 Web PCK. The inspected PCK has SHA-256
`b3631f86ceeaeccc1720fd29be0fd3cc4ae15dadfd63340e42ff2264aa03ba90` and contains 22
paths under `scene-recipes/`. The downloaded PCK was removed after this compact path list and
hash were retained.

`recipe-packaging-audit.txt` records the same audit against a release-style Web export from
clean source `85f0ee3e5814c0bff7f7a561265f24048ce7ef9a`. Its PCK has SHA-256
`5d7a07109451ad171c07f10c1d3738b351ea6f9104be7e8586e68a7f4046651d`; the fatal audit
passes with zero development recipe paths. This proves the exported package excludes the
inputs. The local recipe loader is checked separately against the plain JSON files in the
source checkout.
