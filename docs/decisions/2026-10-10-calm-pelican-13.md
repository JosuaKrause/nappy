# calm-pelican — A hut ends the walk under's guard, the task scenes show the sent pursuer, and day 11 shows two masts · 2026-10-10

## Day 9's walk under the boom and a hut's hold

From the re-review of PR #570 (grassy-goose, every guarded target sends the robber from off
screen): walking under day 9's raised boom completes the task and sends only the door's guard, no
robber, and stepping into either hut then is a hold, which under M100 ends the guard's chase, so
that task costs one inspection and no pursuer. The player keeps it (inbox #651 in
[lilac-marmot](../playtests/2026-10-10-lilac-marmot.md)):

> Let's not send the robber in that case and stop the chase. It's a fair cheat getting through the barrier is hard enough. Well earned if the player pulls it off.

Nothing about the behaviour changes. Built in PR #658: `tests/test_resistance.gd`'s
`_test_a_hut_ends_the_guard_the_walk_under_sets_and_sends_nobody` walks under the named boom, steps
into a hut, runs the hold out, lets her through and runs out any warning, and asserts the guard
gives up and neither a second guard nor the robber is sent, in both directions (4 failures with the
director made to set the trap on an inspected crossing of a done task);
`_test_day_nine_is_done_by_crossing_the_door_not_by_standing_at_it` ends the guard an earlier door's
walk under set and asserts a new `door_guard` at the named door's hut, so it can fail (4 failures
with `EventManager._set_a_guard_on_her()` made to return on the named crossing). *The filer's
proposal, open to overturn:* a sentence in `docs/EVENTS.md`'s hold paragraph and in
`docs/NARRATIVE.md`'s day-9 paragraph says the walk under's guard is one a hut ends, with the
player's words. The pictures of the trap on the days #570 changed beyond day 8 (day 9 walked under
and inspected, day 11's mast foot, day 12's swing with the robber closing, day 14's station door)
are in [walk-under-2026-10-10](../evidence/walk-under-2026-10-10/).

## The day-9 and station-door scenes show the sent pursuer

From the re-review of PR #592 (azure-beaver): the two scenes showed no pursuer a finished task
sends, since their stretches had no tile where a sent robber starts. Asked (inbox #650 in
[mossy-beaver](../playtests/2026-10-10-mossy-beaver.md)): "yes include his approach street." Built
in PR #658: `task-09-crossing.json` and `station-door-corner.json` take the street the robber starts
on through `draft.include`, found from the run log's "task handed over" line on a whole-city version
of each recipe and redrafted with `tools/scene-draft.sh`, and each observes
`row:robber_giving_chase` pursuing and near her after the task is done;
`tests/test_scene_recipe_task.gd` keeps the street and the observation in both. *Chosen where the
design was silent, open to overturn:* the added street brings cars through day 9's door, which would
lift the boom for the old walk and turn the inspected crossing into a walk under, so the walk keeps
to the hut's sidewalk; the original actors and posters are kept rather than the redraft's; the crowd
check moved from tick 420 to 290; the observations sit before the catch, since a catch ends scripted
play.

## Day 11 with two masts

From the same re-review (PR #588, plush-moose): no picture showed day 11 with several masts
answering, since a recipe could not give an authored loudspeaker a mast id. Built in PR #658: a
recipe's `loudspeaker` event row is accepted from day 5 (`Tuning.MAST_FIRST_DAY`), on a sidewalk or
square tile `MastSites._is_eligible()` accepts that is not closed, held or on the home block, with
its field clear of the day's doors and clear of earlier placements (`WalkSiting`'s further checks,
unused calm and route junctions, are not applied), and an optional unique `mast_id` that defaults to
`EventScheduler.added_mast_id()`, the name the game gives a mast it adds;
`scene-recipes/task-11-two-masts.json` shows the arrow move from the mast 224px from the mark to the
one her walk reaches, asserted on either side of the switch, with the stills before and after.