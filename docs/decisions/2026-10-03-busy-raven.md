# busy-raven — Playable scenes for each day's task target and the fire truck · built 2026-10-04

*([gray-egret](../playtests/2026-10-03-gray-egret.md): "create a new task to create scenes (mark +
enough gap blocks + target) for testing each day's target. also create a scene to test the fire
truck event" (#498); "can I spawn this event in a crafted scene so I can test it directly? ... just
build a scene and let me play it out" (#497, the station door's far sidewalk corners); "and just
keep a note that we want to verify each task with the scenes" (#499); "in the scene we can use the
minimum distance which in turn also serves as test whether it will be properly off screen" (#502).
Asked how a scene is built, the player chose "Recipes with live tasks (Recommended)" (inbox #513 in [azure-tapir](../playtests/2026-10-04-azure-tapir.md)).)*

**What was built** (PR #536). A scene recipe's `setup.task` starts a day's task: `mark` pins the
chalk mark on days 6 to 13, `{}` starts day 14 with the resistance goal met, and day 10 also takes
`neighbor` to pin where the neighbor starts. `ResistanceDirector.start_recipe_task()` runs the day's
step with the mark at the pinned place and reads it at once, so the target is placed by the same
code a touched mark runs; a pin that is not an alley mouth's tile centre on open ground reachable
from home is refused, never moved. The runtime starts the task in `begin()`, not `install()`,
because the off-screen placement asks the live camera what is on screen. A task scene keeps the
day's other happenings out (`ResistanceHappenings.start_day(day, with_its_events)`); day 12's park
still closes when the swing is reached. Observations gained `beyond`, `off_screen`, `offered`,
`done`, `arrowed` and `unarrowed`, and the subjects `row:<catalogue id>`, `mark`, `task` and
`rider`.

The scenes, under `scene-recipes/`: `task-06-note.json` to `task-14-last-night.json`, one per day
whose task row names a target; `fire-truck.json` (naming `burning_building` already brings the
`fire_truck` once she sees the fire); `station-door-corner.json`, her start on the station door's far
west corner, 57.7px from the door against its 50.6px reach. `tools/scene-recipes.sh` asserts each:
at the first tick the task is offered, the arrow ends on the target (none on days 6 and 13), the
target is off screen and at its stated distance, and the recorded walk completes the task; the
station door is not touched from the corner and is touched one step east. `docs/SCENE_RECIPES.md`
says how to play each. Stills are in `docs/evidence/busy-raven-scenes-2026-10-04/`.

**One game rule changed.** On day 11, when no live mast stands anywhere, a mast is now put up near
the mark, as the task table's "when none is near, a new mast the day puts up near the mark" says;
before, the task had nowhere to go. In ordinary play this arises only when the day's holds took
every mast site.

**Proposed, not asked for, and open to overturn:** days 6 to 14 as the set; the mark already read
when the scene begins; the director placing its own targets (days 6, 7, 8, 11 and 13, 576 to 608px
from the mark) while the fixed targets (day 9's door, day 12's swing, day 14's station door) sit
just past the same 576px circle, and day 10's neighbor at their own 400px minimum; day 8 on the path
of a run with no day-3 fire, so nothing covers a recorded scar; happenings kept out of task scenes;
one city for all (seed 11, no background crowd); day 14 with the goal met but no earlier steps
recorded; the guard robbers left where the day puts them, so on day 9 the door's guard catches her
about half a second after the inspection lets her through; the west corner for the station door,
since the east corner is 100px from the door's guard; the scene assertions run by
`tools/scene-recipes.sh` and not in CI, where the lifecycle suite still boots every scene. No
gating rule was built; the player's "verify each task with the scenes" is the review item
[busy-raven](../review/2026-10-03-busy-raven.md).
