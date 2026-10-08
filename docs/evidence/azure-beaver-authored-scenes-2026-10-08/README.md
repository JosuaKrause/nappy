# Authored street scenes

The day 7 start and later stills show the explicitly loaded stretch, its unread mark,
pedestrians, wear, posters, traffic and task. They use clean source
`91de3882b50b292aa705d116836beea811640a1f`, Godot 4.7.2, run seed 11, and the
recipe hashes and exact capture ticks in the adjacent manifests. These stills establish
layout and visible contents; they do not establish smooth motion or absence of pop-in.
The automated crowd check plays all ten stretches and observes every recycle separately.

Capture command, from that checkout:

```sh
tools/scene-recipes.sh --recipe scene-recipes/task-07-package.json --output /tmp/scene-preview --screenshots
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
