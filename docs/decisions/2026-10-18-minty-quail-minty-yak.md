# minty-quail — The move poses and park cordon suites read the world on real ticks, and the cordon is taken by happenings of the suite's own (tests through public seams: W16) · 2026-11-04

minty-quail's `tests-public-seams.md`: `tests/test_move_poses.gd`, `tests/test_park_cordon.gd` and
the seed suites' helper `tests/park_cordon_sweep.gd`, with a new helper
`tests/cordon_in_the_world.gd`. Tests only.

**Built.** The move poses suite (private-read lines 6 to 0, hand-called frames 2 to 0) walks the
booted game on real physics ticks and matches the poses of what the game draws (events, crowd
bodies with `is_turning()`, cordon officers) against the map's `moves.all()`, flagging a listed
move no mover stands at. The cordon suites (5 to 2, 3 to 1) no longer read the director's
happenings or its blocked reach: the fixture builds a `ResistanceHappenings` of its own and hands it
`director.reach_obstruction()` through `take_the_park()`, as the director does at the swing, so the
happenings are tested apart from the director; the reaching-the-swing test plays through the
director with a real `Stroller` handed to `use_player()` and `director.tick()`, and the officers and
whether the park is shut are read off the world. The count of those still to leave is the escort
count with the park's own leaving events. Both cordon files give the observers back, since the
director opens the swing's task in the visit counter and the suite's own happenings never finish
it.

**Not done:** `ParkCordon._exit`, the way out, which no game class outside the cordon reads;
`ParkCordon._still_to_come_out()`, kept in the check that the gap waits for him, since both public
readings tried still passed with it forced false; the crowd bodies' leaving the moves list, which
the move poses suite cannot see, since a recycled body is moved and never leaves the tree; the
`GameState` stand-in `main`'s boot still uses; `test_park_return.gd`, a later step.
