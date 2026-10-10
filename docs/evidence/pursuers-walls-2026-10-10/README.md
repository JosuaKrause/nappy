# calm-pelican, pursuers-and-walls: the alley robber does not notice her through a building

**Claim.** With the fix, the alley robber waiting in an alley does not notice her while a building
stands between them, though she is well inside his 140px notice (`pursues_within`) in a straight
line; he notices her once she is in front of the alley's mouth with the line clear. Before the fix
he noticed her through the building and had already lunged by the same moment.

**Limits.** Two stills of one scene on one city, at one moment of one walk. They show the waiting
and the lunge; the timing of the lunge from the stand-off is checked by
`tests/test_events_pursuit.gd`, not here.

## The scene

`robber-behind-the-building.json` is a scene recipe (`docs/SCENE_RECIPES.md`): the trailer
recipes' city (seed 11, `context_seed` 1917501), day 8, the robber placed by the ordinary
scheduler's own checks on alley tile (135, 133), one tile in from the mouth at (135, 132); she
starts 220px east of the building's corner on the sidewalk along its north face, facing west, and
walks west for 2.8s at the walk speed. No crowd and no other events.

Run headless with its assertions:

    tools/scene-recipes.sh --recipe docs/evidence/pursuers-walls-2026-10-10/robber-behind-the-building.json

Each still:

    tools/shot.sh OUT.png 1.75 --recipe docs/evidence/pursuers-walls-2026-10-10/robber-behind-the-building.json \
        --recipe-mode scripted --player-view --no-save --recipe-manifest OUT.json

## Retained

- `after-he-does-not-notice-her.png` — the commit that adds this folder, 1.75s in. She is about
  102px from him round the building's corner; he stands in the alley in his waiting posture. The
  capture's manifest at tick 52 (1.73s): robber at (4336, 4272), `telegraphing` false, `pursuing`
  false, so still waiting. At tick 80 (2.67s), her in front of the mouth at (4331, 4210), the
  headless run records him `telegraphing` true: he has noticed her.
- `before-he-lunged-through-the-building.png` — the same scene and command with
  `src/events/event_instance.gd` as it stands at e2e21bac (before the fix), 1.75s in. The manifest
  at tick 52: robber at (4352, 4245), `pursuing` true — he noticed her through the building,
  closed and lunged, and stands at the mouth reaching for her. The headless run of this version
  stops at tick 64 (2.13s) with him 21px from her, inside his 26px catch: she is caught, and the
  scene's playback never completes.

Nothing else from the runs is kept: the manifests' relevant lines are quoted above, and the logs
carry only boot output.
