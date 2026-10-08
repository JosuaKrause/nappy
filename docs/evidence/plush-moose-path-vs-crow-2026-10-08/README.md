# Day 6 path-distance selection

This recipe places a second man on the nearer parallel street while the day 6 task offers its own man farther away by crow distance. At the first stable retarget after the offer, the player is at `[2961.199, 2256]`: the second man is at `[3376, 2384]`, `434.10px` away by crow distance but `26` walking tiles away, while the task's man at `[3344, 1808]` is `589.27px` away by crow distance but `23` walking tiles away. The second man then paces toward her, becoming nearer still by crow distance while his walking distance remains `26` tiles. The red arrow points to the task's man because reaching him is the shorter walk through the street network.

The evidence was captured from source commit `510e1c42d068fc8fdbe7535fd99241e3d1ae9020` with the exact companion recipe in this directory, seed `11`, city context seed `1917501`, a `0.3` camera zoom, and a capture time of `3.0` seconds. Distances above are the production `ArrowField`'s four-connected walking lengths and the live actors' straight-line distances at that retarget. The recipe assertion at tick 90 checks that the active task is arrowed after both men exist. The still shows both candidates and the resulting arrow selection; it does not prove the route calculation by itself.

Run the assertion with:

```sh
./tools/scene-recipes.sh --recipe docs/evidence/plush-moose-path-vs-crow-2026-10-08/day06-path-vs-crow.json --output /private/tmp/nappy588-finish/evidence
```

Reproduce the still with:

```sh
./tools/shot.sh docs/evidence/plush-moose-path-vs-crow-2026-10-08/day06-path-vs-crow.png 3.0 --recipe docs/evidence/plush-moose-path-vs-crow-2026-10-08/day06-path-vs-crow.json --recipe-mode scripted --no-save --invincible --player-view
```
