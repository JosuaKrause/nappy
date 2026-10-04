priority: now

# busy-raven — Playable scenes for each day's task target and the fire truck event · filed 2026-10-03



[gray-egret, scenes to play each day's target and the fire truck](../../playtests/2026-10-03-gray-egret.md)
files three notes (#497, #498, #499). Band `now` is the note's own order on a queue slot: the
player said "we pick those scenes up after the release" (#499), so it is picked up once the
pending release is out, and it is not parked.

**Asked for**, in the player's words:

- "can I spawn this event in a crafted scene so I can test it directly? actually, this is a good
  idea for tests like this. just build a scene and let me play it out" (#497, about the station
  door's far sidewalk corners, which sit 57.7px from the door against its 50.6px radius).
- "create a new task to create scenes (mark + enough gap blocks + target) for testing each day's
  target. also create a scene to test the fire truck event" (#498).
- "we pick those scenes up after the release" and "and just keep a note that we want to verify each
  task with the scenes" (#499).

So the entry is two kinds of scene, both played by the player rather than only asserted: one per
day that has a task target (days 6 to 14), each built from the mark, enough gap blocks between the
mark and the target, and the target; and one for the `fire_truck` event. **And the note to keep:
each task is verified with its scene** — a task's target is not called checked until the player
has played its scene (`docs/review/` is where a thing that waits on a person goes, when a scene
is built).

**The existing tool.** Authored scene recipes ([`docs/SCENE_RECIPES.md`](../../SCENE_RECIPES.md))
are saved JSON under `scene-recipes/`, built by `RecipeCityBuilder`, played with
`tools/run.sh --recipe <file>` (free play, physical input) and asserted headlessly by
`tools/scene-recipes.sh`. The scenes are recipes.

**What a recipe cannot do yet**, which the scenes need:

- `setup` has no field for a resistance mark or a task: nothing places a mark, offers the day's
  task or points the red arrow at a target. The day-6 to day-14 scenes need this before any can
  be built.
- A recipe installs no event unless it names one ("Only explicit selections install events"), so
  the targets that are events or ride on one need support: the day-11 loudspeaker mast, the
  day-7 delivery van's drop, the day-10 neighbor walking home, the day-3 fire the day-8 burnt
  shell comes from, the day-13 roadblock. Which of these a recipe can already name is read from
  the recipe schema before any is built.
- The `fire_truck` row (`docs/EVENTS.md`) is "Never scheduled: a SCRIPTED def with no day, created
  only once `burning_building` has been seen", so its scene names `burning_building` and lets the
  player's sight of it call the truck in; it does not place the truck by hand.

**Where the targets are.** Each day's target, and what counts as reaching it, is in the task
table of [`docs/NARRATIVE.md`](../../NARRATIVE.md) and, for the targets as the open pull request
#480 changes them, in `docs/decisions/2026-10-03-feathery-marmot.md` on that pull request's branch
(not yet on `main`; the path is the link once it merges).
The path measure for "near its mark" is held by that pull request's entry
`docs/todo/2026-10-03-feathery-marmot/`, not by this one.

**Proposed, not asked for:**

- A recipe `setup` field for a mark and its task (a day's task offered from the scene's start, its
  arrow live), and named mast and rider support for the van, as the way to give the scenes what
  they lack. The plainer alternative is a scene with the mark and target as authored actors only,
  with no task logic running, which tests where a target stands but not that the task is reached
  and completed.
- One scene per day 6 to 14 plus the fire truck, as the set. The player named "each day's target"
  and "a scene to test the fire truck event"; the grouping into one recipe file each is the
  filer's.

**Open question, asked of nobody yet:** whether a scene's gap blocks should be as few as the
"near its mark" distance allows or as the real city's gaps run; whoever picks the task up reads
the open pull request #480's measure first and asks the player if it does not settle it.
