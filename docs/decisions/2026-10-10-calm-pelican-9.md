# calm-pelican — The task-scene tests test what they claim, and a scene says what happened to its task · 2026-10-10

From the re-reviews of PR #592 (azure-beaver, the task scenes are a handcrafted stretch), PR #564
(busy-raven, task scenes start from an unread mark) and one bullet of PR #580's (the trailer).

**Built in PR #646.**

- **The stretch tests.** The stretch suite compares the live map with the recipe's own
  `stretch.tiles` and `context.tiles` rather than with a city generated from the seed, as the
  player's mossy-marmot choice ("Finish fully handcrafted layouts now") requires; a hand edit to the
  day-7 scene fails the old suite and passes the new one. The forced crowd-entry check looks at each
  stretch end from her camera's zoom and from either side, and every accepted entry must land
  outside the view it was made under; deleting the crowd's view checks now fails all ten scenes,
  where the old check still passed. `docs/SCENE_RECIPES.md` excepts the listed buildings' lots from
  the void and says a stretch restores its saved context with no construction run.
- **A scene says what happened to its task.** "Nowhere to go" is reported only while no task has
  been placed; a placed task that later disappears is recorded in the manifest
  (`task.expired_tick`), and any observation still asking about it fails. A hand-played scene now
  prints the director's reasons for a refused placement and carries on with no task, where a
  scripted one stops. `_box_in_either_view()` tests the one real view, the 1280x720 design box at
  the camera's zoom, since the camera turns for portrait and shows the same 640x360 world; four doc
  places say "out of her view, in either presentation". Two comments in the resistance director
  say what the code does.
- **`playback.settled_camera` must be a boolean**, as `camera.fixed` is, with a schema case.

**Dropped, with the reason:** the stretch item's bullet asking the scene-draft tool to test "both
views" for a car at her start. It rested on a portrait view taller than the landscape one; the game
turns the camera instead (`ScreenOrientation.apply_to_camera()`), so the draft's landscape box is
already the whole view. The crowd's own `_beyond_every_view` tests a 640x640 square, stricter than
the real view, and its comment now says so; narrowing it is not filed.

**Chosen where the items were silent, open to overturn:** a refusal in free play does not quit the
game; free play counts ticks only while unpaused; an expiry prints a line and writes the manifest;
the crowd test judges entries by the crowd's own view rule, with a check that the rule does not pass
everything; the observation `clear_of_both_views` keeps its name, since `fire-truck.json` uses it.
The neighbor's pinned start is not cleared (the item offered rewording as enough). Still open for
the player: whether day 9's scene and the station-door corner should show the pursuer a finished
task sends.
