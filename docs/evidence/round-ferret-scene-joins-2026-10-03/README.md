# Power-station hall and yard joins

These two reviewed stills come from integrated source `8941448c`, Godot 4.7.2,
Compatibility/OpenGL on Apple M2, 1280×720. They show the production hall roof covering
the adjoining facade and the yard retaining that facade. Both recipes pass the existing
city checks as normal scenes; neither needs a fixture allowance.

The builder extraction retains their construction, map and building-presentation code.
These are source-build evidence, not captures of the extracted commit and not a claim
of pixel equality after extraction. The focused tests independently construct both joins
and assert roof coverage, facade preservation and live Main startup in this slice.

| Case | Still | Recipe capture manifest |
|---|---|---|
| Hall | [Image](recipe-reviewed-stills/power-station-hall.png) | [Manifest](recipe-reviewed-stills/power-station-hall-capture.json) |
| Yard | [Image](recipe-reviewed-stills/power-station-yard.png) | [Manifest](recipe-reviewed-stills/power-station-yard-capture.json) |

The capture manifests preserve the geometry checks, recipe hash, setup, tick and camera
needed to interpret these two stills. Generic boot/atlas logs and duplicate headless
setup manifests add no evidence for the roof/facade claim and are omitted. Original
capture runs are `rig-000024-seed11-v0.21.5-16-g8941448c` (hall) and
`rig-000028-seed11-v0.21.5-16-g8941448c` (yard). No other scene or movie output belongs here.

Rerun from a checkout with imported assets and a display-capable Godot:

```sh
tools/check.sh
tools/shot.sh /tmp/hall.png 0.5 --recipe scene-recipes/power-station-hall.json --recipe-mode scripted --recipe-manifest /tmp/hall.json
tools/shot.sh /tmp/yard.png 0.5 --recipe scene-recipes/power-station-yard.json --recipe-mode scripted --recipe-manifest /tmp/yard.json
```

Both captures use runtime seed 11 and construction context 1917501. They capture physics
tick 15 after the setup. The
stills establish static join composition only. They do not establish movement, free-play
behavior or repeatable movie output.
