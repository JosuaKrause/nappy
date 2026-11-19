# minty-quail — The screen-edge badge's members only its own class and the tests used become internal · 2026-11-19

minty-quail's `tests-own-class-members.md`, the underscore pass, for the screen-edge badge's control
(`src/ui/danger_edge.gd`), the one module outside the events and the resistance left with no wait
once the day director's pass (`2026-10-18-minty-quail-gray-gecko`) was done: a public member only its
own class and the tests use becomes internal and its tests move to what the class does outward
(curly-rabbit #1098).

**Built.** Internal: `DangerEdge._model`, `_sees()` and `_view()`; their three lines leave the
list. Nothing under `src/` outside the file read them, so no game code changed.

- `tests/test_drawn_view.gd` asked the model whether a badge was up (`edge.model.has_badges()`). It
  asks the edge what it draws (`edge.announcing()`, the list the edge's own redraw and the
  telemetry observer read) and checks it is not empty. The two checks it feeds (the frame a badge
  goes up is the frame it is drawn, and it is redrawn every frame it stays up) keep their meaning.
- `tests/masked_man_meeting.gd`, the rig the building's masked-man suites play through, asked the
  edge's own sight (`edge.sees()`, `edge.view().sees_any()`) whether she could see him. The edge
  reads that sight off its event source (`EventManager.visible_view()`), so the rig asks the
  event manager it already holds (`EventManager.sees()`, `visible_view()`): the same view, from
  the source rather than through the edge.

**Mutations run**, each reverted and never committed:

- Dropping `or _drew_badges` from `_watch_the_edge()` (the edge redraws only when it has badges
  this frame, so the frame a badge goes up is not drawn) fails `test_drawn_view.gd`'s "the frame
  the badge goes up is the frame it is drawn".
- Making `_sees()` always answer true (nothing is ever off screen, so no badge is raised) fails
  `test_interior_masked_man_badge.gd`'s "the edge badge is up from the frame he runs until he is in
  view" in all twenty starts. Making it always answer false first passed that suite: the suite
  counts a badge down while she cannot see him, and a badge that stays up too long is not a case it
  holds. It was not weakened here, and no test was added, since the pass keeps test parity.

**Remeasure:** nothing; no behavior changed.
