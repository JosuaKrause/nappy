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
- `SealPlanner.candidates()` stays public with a `[kept]` line: once the runtime stopped reading it,
  only `test_seals` and `test_shapes` do. Whether the game gets a reader or it goes internal is the
  seal planner's own pass (§6).
- Every scene recipe passes, and a `task-13-roadblock` draft is byte-identical before and after.
