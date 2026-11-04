# minty-quail — The finale suites read the booted game's scene tree and the game's public seams (tests through public seams: W11b) · 2026-11-04

minty-quail's `tests-public-seams.md`: the three finale suites, whose cases are in
`tests/finale_rig.gd`, and the shared `tests/escape_roadblock_rig.gd`. Tests only.

**Built.** `finale_rig.gd` (private-read lines 34 to 1, hand-called frame functions 4 to 0): where a
band stands is read off bands built as the game builds them (`EventInstance.setup()`,
`body_position()`); the roadblock guards walk and warn on real frames, handed an atlas, a drawn
frame being two `process_frame` awaits since the signal comes before the frame's `_process`; the
escape's vans and the tuning's bag come from `EventScheduler.build_day()` with a spec carrying the
bag and the slots; the alley-mouth walls are every wall `SealPlanner.plan_day()` plans on an alley
tile; the street-tint test boots the real `main` on the city section and restarts it through a
loss and the outcome screen's continue; the lured-off band's mark is read off a stroller of its
own. `_test_escape_section_came_from_the_file` is gone: the resumed-escape and hand-over boots
already hold both sides of `main`'s policy, and a mutation either way fails them. The roadblock
rig reads a `CityState` of its own rather than the `GameState` autoload. Eleven mutation runs; the
days half of the alley-fit check holds by construction (a day's alley-mouth row is a soft seal,
which always fits), as it did before. `test_finale_b` takes about 25 s longer for its real frames
and stays under two minutes.

**Not done:** the marble test's one call of `EventScheduler._fill_the_walk_from_the_bag()`, to read
how many marbles a plan drew, which wants the planner to report that count to a game reader (the
run log's account of the plan is a candidate); the lured-off band and the charge test add their
instance to `world.instances` by hand rather than through the manager's spawning; the probes
`escape_roadblock_spacing.gd` and `escape_density.gd`, which are not suites.
