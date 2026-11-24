# minty-quail — The scene recipes' private reaches go through public answers (D2c) · 2026-11-24

minty-quail's scene recipes' pass (`.claude/briefs/designs/minty-quail-scene-recipes-pass.md`, D2c,
§2.8 to §2.10). The scene recipes' runtime and draft reached into other classes' private members:
`ResistanceHappenings._bring_the_column()`, `CrowdAgent._beyond_every_view()`, an agent's `_corridor`,
`_vertical`, `_direction` and `_speed` by string, `ZoomOutCamera._process(0)` called by hand, and
`SealPlanner.SitedSeal.bodies`.

**Built.**
- `ResistanceHappenings.column_fits_at(place, going)` and `bring_the_column_at(place, going)`, the
  trucks answered front first; the lane and the road's ends are shared with `_send_the_column()`.
  `column_trucks()`, read by nothing, is deleted.
- `SealPlanner.candidate_named(id)` answers the runtime's two loops over the candidates;
  `SitedSeal.bodies` is private behind `bodies()`; `SitedSeal.stand_whole(map)` holds a hard seal's
  street or shuts a soft seal's two sidewalks.
- `LaneMover.beyond_every_view()` is public; the runtime reads `agent.lane().corridor_index()`, the
  draft `lane().is_vertical()`, `lane().direction()` and `speed()`. `ZoomOutCamera.hold_still()`
  replaces the hand-called `_process(0)`.

**Noted.**
- The design's §2.8 has the column's happenings take no fronts. With none, the neighbor's window is
  not boarded on day 11 and later (`test_recipe_structures`), since the day start boards it through
  the fronts; the runtime still hands `_world.dressing().fronts()`, and no scene changes.
- `SealPlanner.candidates()` and `pictures_for()` are internal (`_candidates()`, `_pictures_for()`): once the
  runtime stopped reading the table, only the seal planner's own file and `test_seals` and `test_shapes`
  did, and no `[kept]` line was written for them. The two suites ask the pictures through
  `SealPlanner.candidate_named()` over the ids `tests/seal_picture_ids.gd` lists, and a check holds that every
  row a day's sited seals stand is one of those pictures', so a picture added to the table and sited is found.
- Every scene recipe passes, and a `task-13-roadblock` draft is byte-identical before and after.
