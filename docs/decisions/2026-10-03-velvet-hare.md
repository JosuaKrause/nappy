# velvet-hare — Ordinary controls and bounded exploration for saved scenes · 2026-10-03

**Sources.** [Mossy-swan](../playtests/2026-10-02-mossy-swan.md) asks to experiment in
bounded scenes, and [gentle-marten](../playtests/2026-10-03-gentle-marten.md) clarifies
that every recipe supports both normal controls and scripted movement. These are two
launch modes of the same saved setup, including both power-station joins and all trailer
recipes. [Dappled-lynx](../playtests/2026-10-03-dappled-lynx.md) requires explicitly
selected events in either mode.

`tools/run.sh --recipe FILE` defaults to free play. Physical input and the ordinary
camera remain active; the recipe's movement/camera script and capture deadline do not
control that run. `--recipe-mode scripted` uses the shared physics clock for inputs,
camera tracks, assertions and capture. Both modes isolate the player's save, and ordinary
collisions and consequences continue inside the authored scene.

Continuing a won day's summary reloads the recipe rather than retaining the ordinary
day increment. Retrying an escape loss also restores the recipe. These paths retain
the authored parent, day, positions and deliberately selected objects. The real-Main
lifecycle suite checks each recipe's applicable continuation or loss path, save isolation,
physical movement in free play and the absence of a recording deadline.

Bounded presentation omits exterior scenery and physical map walls, relaxes the recipe
camera clamp, and supplies walkable plain alley ground outside the authored rectangle.
Leaving and returning does not reconstruct or reset the ongoing scene. The exterior
does not count toward the production route guarantees; the explicit construction witness
provides their context before projection. Ordinary generated cities keep their map walls,
camera bounds and validation behavior.

The launch-mode names, default free mode, restart behavior and plain alley exterior are
implementation choices open to correction. The scene builder, these controls and the
trailer stills are one implementation in #457; separate queue entries do not imply
separate PRs. Recipe construction and activity contracts are in
[SCENE_RECIPES](../SCENE_RECIPES.md), and composition evidence is recorded with
[calm-stork](2026-10-03-calm-stork.md).

**Verification.** At source 9768f6de, 64 lifecycle checks pass, including actual physical
exit and return for both bounded power-station recipes, won-summary continuation for
ordinary recipes, and escape loss/retry. The expanded CLI suite passes 289 checks.
Scripted recipes receive the rig supervisor and vsync handling; physical free play
retains ordinary input. Recording explicitly rejects free mode before dependencies
or launch, since an interactive recipe has no recording completion deadline.
