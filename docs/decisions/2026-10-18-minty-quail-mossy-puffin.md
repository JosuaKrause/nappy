# minty-quail — A scene makes one RowGround for its placements and its walk (D3) · 2026-11-24

minty-quail's scene recipes' pass (`.claude/briefs/designs/minty-quail-scene-recipes-pass.md`, D3,
§2.12 and §2.13), the last case of `re-derived-cases.md` (the facts derived in more than one place,
inbox #1156 in gray-dolphin): the ground cache, which tiles each row may stand on. A day's walk derived
it once in `RowGround`; a scene recipe still scanned for itself in three places:
`EventScheduler.recipe_placement()` made one ground per authored row,
`SceneRecipeRuntime._finale_placement()` one per escape actor, and the scene's walk carried none, so
`EventsAhead._ground_of_the_walk()` made one per siting.

**Built.**
- `SceneRecipeRuntime._event_plans()` makes one `RowGround` after the authored seals and the home's
  holds are on the map, inside the `CityMap.witness_only()` bracket, and hands it to
  `recipe_placement()` (a required parameter), to `_finale_placement()` and to
  `EventManager.start_recipe()` (an optional one), which puts it on the walk's plan; the walk's
  events and `_ground_of_the_walk()` read it. A rig that hands none keeps the fallback.
- The ground case of `re-derived-cases.md` is closed; what is left of it is a scene's walk working
  out its route tree and locations again (a review of this pull request found it).

**Noted.**
- Made inside the witness bracket, the ground keeps each answer from the first time it is asked: a
  question the install asks is answered with a bounded scene's exterior and a stretch's void off,
  and the walk keeps that answer, while a question first asked as she walks (day 8's
  burnt-building front) is answered with the edges shown, since the ground's side test reads
  `tile_at()`, `pavement_inward()` and `is_street()`, which answer differently with them on. No
  scene shows a difference today.
- Every scene recipe passes and all 25 manifests are byte-identical to main's.
