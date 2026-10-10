# A task scene says what happened to its task

**Low · from the re-review of PR #564 (busy-raven, task scenes start from an unread mark).**
- `SceneRecipeRuntime._bind_task_names()` reports a task gone after the mark is read as "the mark's
  task has nowhere to go" and quits as a failed setup, though a task also disappears on ordinary
  expiry (a `task-10-neighbor.json` walk that arrives after the neighbor is home). Use that message
  only while no task has been placed; afterwards record the expiry in the manifest and let the
  scene's checks fail on it.
- A refused placement is silent in a hand-played scene (`begin()` returns at `if not scripted:`),
  while `docs/SCENE_RECIPES.md` says such a scene "stops … with the director's reasons". Print the
  reasons in hand-played scenes too, or limit the sentence to the headless replay.
- `_box_in_either_view()` assumes portrait shows a 360x640 piece of the world, but the game rotates
  the camera (`main._apply_orientation()`), so portrait shows the same 640x360 drawn sideways; use
  the landscape box or `_camera_world_rect()`, and reword `docs/SCENE_RECIPES.md` where it says
  otherwise.
- Two comments in `src/resistance/resistance_director.gd` say less than the code: the scene task's
  error list is also filled when she reads the mark, and the neighbor's pinned start is never
  cleared (a second neighbor draw in one scene would be refused against it). Reword both, or clear
  the pin once the neighbor is drawn.

**Open, for the player (from PR #592, azure-beaver):** day 9's scene and the station-door corner
show no pursuer a finished task sends, since their stretches have no tile where a sent robber
starts (`docs/SCENE_RECIPES.md` says so). That makes them safer than the real day, against "the
events should still spawn using the same rules". Should they get the robber's approach street
(through `draft.include`) and an observation that he pursues her?
