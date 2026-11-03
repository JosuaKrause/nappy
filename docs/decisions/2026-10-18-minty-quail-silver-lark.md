# minty-quail — The event behaviour and placement suites ask the placed row and its def (tests through public seams) · 2026-11-02

minty-quail's `tests-public-seams.md`: the event behaviour and placement suites, one PR's worth. Eight
of the 29 suites named in its brief read no private member now, six more are partly converted,
and fifteen are untouched; the item says what each still reads and what it wants.

**Built.**
- Pure functions of the scheduler moved onto the value they are about, bodies unchanged but for
  `self`, each still called by the scheduler: `EventScheduler.Planned.gap_to()`,
  `counts_against_the_line()`, `denies()`, `reach_touches()` and `keeps_its_field_clear()` on a
  placed row; `EventDef.line_reach()`, `reach_above()`, `has_a_line_to_avoid()`,
  `reaches_the_far_lane()` and `for_day()` on a row's def. The docs, comments, tests and probes that
  named the old privates name the new members.
- Suites use public seams that already existed where they reached privates
  (`ResistanceDirector.contact().complete_now()`, `rider()`, `reaches_from_home()`,
  `EventManager.plans()`, `WalkSiting.cell_centre()` and `leaves_her_a_way()`); the day-6 and day-7
  suites find what was put on her route as the plans that were not there before and build their own
  `WalkSiting`, rather than read `EventsAhead.director()` and `walk_siting()`, which no game class
  reads. The day-7 suite still reads the rigged bag through `director().route_bag()`, listed as left.
- `test_masts.gd` and `test_loose_dog_arrives.gd` let real physics frames pass under
  `Engine.time_scale` instead of calling `EventManager._physics_process()`.
- The events skill named a removed private (`EventScheduler._keeps_its_field_clear`); it names
  `EventScheduler.Planned.keeps_its_field_clear()` now.
- Private-read lines over the 29 suites 346 to 282, hand-driven frame lines 20 to 18. Every check
  kept; five added where breaking the code survived before: a curfew announcement counts against
  the line with no mast carrying it and stops once one does, a lethal row's line reach is its whole
  field, no row reaches less than its body, and a lethal row classified as a wall keeps nothing
  clear.

**Not done, with the reason:** a public name for a scheduler helper nothing but a test calls
(`_role_for`, `_place_one`, the verdict cache), since a member only a test reads is not a seam
(records -44 and -47); the arrow and task-guard privates, which `retarget_the_arrow()` answers in
the resistance folder; the loose dog's `EventsAhead._send_down_her_line()`, which wants the
director to owe the dog and real frames to place it; and the bare-`EventManager` rig of the checkpoint, chat, manager and
encounter suites, which wants rewriting onto a real tree rather than a seam.
