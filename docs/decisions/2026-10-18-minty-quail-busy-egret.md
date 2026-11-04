# minty-quail — The posters suite tears posters with a real stroller on real ticks (tests through public seams: W12) · 2026-11-04

minty-quail's `tests-public-seams.md` and `run-state-handed-in.md`: the posters suite, subtask W12 of
the scoped plan. One `src/` change: `PosterWalls.wall_count()`, which only this suite read, goes;
`fronts().size()` answers the same.

**Built.** `test_posters.gd` (private-read lines 37 to 0, `GameState` lines 81 to 0) builds each
test's city on a run of its own, hands the events a real `Stroller` through `use_player()`, and holds
a movement key while real physics ticks pass, one a frame at twice real time: the city's building
bodies stop her at the wall and the poster walls tick on their own. The push, slide, door, marble,
crew and crossed-notice tests all tear posters that way; a door is a real door found in the city,
a bollard holds her off reach, pursuers are retired through `EventManager.retire()`, and the crew
test checks the events see each crew. `tests/fixtures/poster_view.gd` reads the city's own run. A
diagonal push cannot stand still at a wall, so the first sheet's wait is checked with a straight
push and the diagonal then slides her on. Checks 9224 to 9233; eleven mutation runs. The suite takes
about thirty seconds.

**Open to overturn:** "the slide is still going" is folded into the check that the sheet after the
door tears at once.
