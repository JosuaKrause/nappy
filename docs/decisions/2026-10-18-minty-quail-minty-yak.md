# minty-quail — The move poses and park cordon suites read the world on real ticks, and the cordon is taken by happenings of the suite's own (tests through public seams: W16) · 2026-11-04

minty-quail's `tests-public-seams.md`: `tests/test_move_poses.gd`, `tests/test_park_cordon.gd` and
the seed suites' helper `tests/park_cordon_sweep.gd`, with a new helper
`tests/cordon_in_the_world.gd`. Tests only.

**Built.** The move poses suite (private-read lines 6 to 0, hand-called frames 2 to 0) walks the
booted game on real physics ticks and matches the poses of what the game draws (events, crowd
bodies with `is_turning()`, cordon officers) against the map's `moves.all()`, flagging a listed
move no mover stands at. The cordon suites (5 to 2, 3 to 1) no longer read the director's
happenings or its blocked reach: the fixture builds a `ResistanceHappenings` of its own and hands it
`director.reach_obstruction()` through `take_the_park()`, as the director does at the swing (the
director's own call now reads `reach_obstruction()` too, so the seam has a game caller), so the
happenings are tested apart from the director; the reaching-the-swing test plays through the
director with a real `Stroller` handed to `use_player()` and `director.tick()`, and the officers and
whether the park is shut are read off the world. The count of those taken on is read just after the first tick: one per escort and one per
leaving event in the park of a kind `ParkCordon._walks_out()` takes; it reads 0 on every seed swept,
so the check that the gap closes when the cordon said it would always holds it to its deadline.
Both cordon files give the observers back: finishing the swing's task the game's way would make the
director's own happenings take the park first, so the suite's own `take_the_park()` would refuse,
and the task the director opened in the visit counter stays open.

**Not done:** `ParkCordon._exit`, the way out, which no game class outside the cordon reads;
`ParkCordon._still_to_come_out()`, kept in the check that the gap waits for him, since both public
readings tried still passed with it forced false; the crowd bodies' leaving the moves list, which
the move poses suite cannot see, since a recycled body is moved and never leaves the tree; the
`GameState` stand-in `main`'s boot still uses; `test_park_return.gd`, a later step.
