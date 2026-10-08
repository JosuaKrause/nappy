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

The trailer and task-arrow integration is separate from this preview; these pictures do
not claim to show those pending PRs.

`covered-movie-*` records a failed motion capture at clean source
`f1ac0061e43800360715c6458433aad6f7eec760`, using:

```sh
tools/record.sh --out azure-beaver-day7.mp4 --recipe scene-recipes/task-07-package.json --recipe-mode scripted
```

The simulation completed every assertion without engine errors, but visual inspection found
frozen movie frames: one PNG hash repeats 456 times and another 124 times. The selected
decoded frames at approximately 0.5 and 8.5 seconds show the resulting jump. Settings and
raw frame hashes preserve provenance; the whole movie remains local. This is a capture
failure, not crowd-motion evidence. The trailer's covered-window drawing correction must
be integrated before repeating the short motion proof.

`fire-truck-crying.json` and its one-line run-log excerpt retain a separate failure at that
same clean source. `tools/scene-recipes.sh --output /tmp/all-saved-scenes` stops on the
unchanged full-city fire-truck recipe: its waiting route reaches excitement 100 and loses
to crying at tick 261, before the required truck arrival observations. This result does
not affect the ten passing stretch playbacks; it prevents claiming every saved recipe passes.
