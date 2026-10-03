# Authored trailer scenes

The seven captures under `recipe-reviewed-stills/` use integrated source `8941448c`;
`recipe-city-active/` uses source `a23858a4`. Both are retained by PR #457's integration branch.
Godot 4.7.2 stable, macOS Apple M2, Compatibility OpenGL, 1280×720. Their recipe data and
scripted simulation are the scene slice's implementation; this extraction changes launch
availability, not those captured setups. Complete original telemetry runs accompany every
capture, along with headless action manifests, capture manifests and logs.

Reproduce with `tools/scene-recipes.sh --screenshots --output /tmp/authored-scenes`.
No video is made. `capture_at` chooses each still after the full simulation starts. The
separate shot-list `in` trims recording pre-roll and is independently adjustable.

| Scene | Requested action and captured composition |
|---|---|
| `trailer-choice` | Mother takes a wrong route, turns back and uses the other street. The captured moment is on that alternate route. A leaf blower supplies the authored obstacle; it is an implementation choice. |
| `trailer-blower` | Father approaches an early ordinary danger, the leaf blower. |
| `trailer-dog` | Mother runs from the actual charging dog during its pursuit. |
| `trailer-title` | The title appears over the ordinary game view. |
| `trailer-trucks` | Mother walks beside the production three-truck army formation. |
| `trailer-gatehouse` | Father approaches the visible front of the region gatehouse. |
| `trailer-chase` | Mother visibly carries her baby and runs from an actively pursuing guard. |
| `trailer-city` | Camera pulls from her doorstep to the full city, with production walkers and cars across the view. |

Stills establish composition, not motion. Every headless scene completes its observations.
The chase capture records physics tick 42, carrying, speed 168 and a pursuing guard. Its
contact stride keeps the running pose legible. Authored tutorial-complete state removes
onboarding prompts; normal gameplay warnings remain visible.

At city capture tick 150, the manifest records 2,396 production agents and 348 cars, with
274 cars moving: NW 85, NE 47, SW 87, SE 55. Every quadrant also has moving walkers. The
explicit city crowd scope uses ordinary field area density over the whole map; normal
gameplay stays local. Focused tests independently measure actual displacement in all
quadrants. The still establishes full framing and distributed subjects; those checks
establish activity.
