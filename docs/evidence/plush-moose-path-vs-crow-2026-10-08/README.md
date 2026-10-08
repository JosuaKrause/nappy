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

## Retained diagnostics and verification limits

`measurement-diagnostic.log` and `measurement-manifest.json` retain the actual numeric
measurement. It used temporary `PR588_MEASURE` instrumentation after candidate collection:
one production `ArrowField` per target was swept to completion, then the live straight-line
distance and walking length were printed. That temporary patch was not retained, so the
measurement command alone cannot reproduce the printout from the committed source. The
diagnostic recipe hash predates the final timing/assertion revision of the companion recipe;
its actor geometry is recorded in the manifest.

Both that log and the first uninstrumented `assertion.log` contain sandbox errors opening
Godot's user log and system certificates. They are retained diagnostics, not clean passing
verification, even though the old wrapper printed PASS. `assertion-manifest.json` retains
the assertions both runs reported: its SHA-256 is identical in the two runs, so only one
manifest is retained. The later `clean-assertion.log` comes from the final companion recipe
with normal permissions:
the same assertion command above, with output `/private/tmp/nappy588-clean-assertion`, at
HEAD `9fe6c905e7733e7c44ee80df423a00b29184b505` with only parent documentation/evidence edits
pending. That run passes, completes playback and contains no engine errors.

The day-11 regression passes in the focused resistance suite. The author did not run the
deletion mutation; its expected failure follows from control-flow inspection and is an
explicit target of independent review, not a measured before/after claim here.
