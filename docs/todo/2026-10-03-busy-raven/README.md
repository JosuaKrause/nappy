priority: now

# busy-raven — Playable scenes for each day's task target and the fire truck event · filed 2026-10-03



[gray-egret, scenes to play each day's target and the fire truck](../../playtests/2026-10-03-gray-egret.md)
files four notes (#497, #498, #499, #502). The player said "we pick those scenes up after the
release" (#499); band `now` is the filer's note, below.

**Asked for**, in the player's words:

- "can I spawn this event in a crafted scene so I can test it directly? actually, this is a good
  idea for tests like this. just build a scene and let me play it out" (#497, about the station
  door's far sidewalk corners, which sit 57.7px from the door against its 50.6px radius).
- "create a new task to create scenes (mark + enough gap blocks + target) for testing each day's
  target. also create a scene to test the fire truck event" (#498).
- "we pick those scenes up after the release" and "and just keep a note that we want to verify each
  task with the scenes" (#499).

So the entry is what the player asked: scenes (a mark, enough gap blocks, and the target) for
testing each day's target, a scene for the `fire_truck` event, played by the player; picked up after
the release; and a note kept that each task is to be verified with the scenes.

**The existing tool.** Authored scene recipes ([`docs/SCENE_RECIPES.md`](../../SCENE_RECIPES.md))
are saved JSON under `scene-recipes/`, built by `RecipeCityBuilder`, played with
`tools/run.sh --recipe <file>` (free play, physical input) and asserted headlessly by
`tools/scene-recipes.sh`. The scenes are recipes, as the player answered (below).

**What a recipe cannot do yet**, which the scenes need:

- `setup` has no field for a resistance mark or a task: nothing places a mark, offers the day's
  task or points the red arrow at a target.
- A recipe installs no event unless it names one ("Only explicit selections install events"), so
  the targets that are events or ride on one need support: the day-11 loudspeaker mast, the
  day-7 delivery van's drop, the day-10 neighbor walking home, the day-3 fire the day-8 burnt
  shell comes from, the day-13 roadblock. Which of these a recipe can already name is read from
  the recipe schema before any is built.
- The `fire_truck` row (`docs/EVENTS.md`) is "Never scheduled: a SCRIPTED def with no day, created
  only once `burning_building` has been seen". Whether naming `burning_building` in a recipe is
  enough to bring the truck in is not known: only explicit selections install events, so the truck
  may need explicit support of its own.

**Where the targets are.** Each day's target, and what counts as reaching it, is in the task
table of [`docs/NARRATIVE.md`](../../NARRATIVE.md), and why each stands where it does in
[`docs/decisions/2026-10-03-feathery-marmot.md`](../../decisions/2026-10-03-feathery-marmot.md).

**The scenes are recipes with live tasks** (inbox #513 in [azure-tapir](../../playtests/2026-10-04-azure-tapir.md)). Asked "how should a scene be built?",
between "Recipes with live tasks" (recipes gain a field for a mark and its task: the day's task
offered from the start, its arrow live, the target events installed, so the task can be played to
completion) and "Authored actors only" (mark and target placed with no task logic running), the
player answered "Recipes with live tasks (Recommended)".

**Proposed, not asked for:**

- Days 6 to 14 as the set: the filer's reading of "each day's target", being the days whose task
  table row names a target.
- A gating rule that a task's target is not called checked until the player has played its scene,
  and a `docs/review/` item per scene as the way it waits on a person. The player said only "keep a
  note that we want to verify each task with the scenes".
- Band `now` is the filer's choice: the notes carry no band, and #499 says only that the scenes
  are picked up after the release.

**The gap, in the player's words** (#502): "in the scene we can use the minimum distance which in
turn also serves as test whether it will be properly off screen". A scene puts the target at the
minimum distance the task allows, so playing it also tests that the target is placed properly off
screen.
