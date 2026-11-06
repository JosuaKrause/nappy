# minty-quail — The city, route and recipe suites lose checks that hold nothing · 2026-11-05

minty-quail's `tests-hold-nothing.md`, the audit's findings in 14 city, route, crowd-look and
recipe suites no other build owned, under the player's rule that a check whose setup only a test
can make, that reads a design decision back, that cannot fail, or that repeats another, is removed
(curly-rabbit #1097). Nothing under `src/` changed.

**Removed.** The car views' sector table test; the walker views' mirror table, its per-sector view
and mirror-flag checks and the native 18x38 test; the crowd yields' two `undeclared` sweeps (the
row validation refuses it already), its `stands_as` table cut to one row of each answer; the
retyped `stop_line` body and the literal 4.8 px in the give-way and bollard suites; the
generator's lattice parity check and its 24 home-in-the-middle checks; the home block's lot count
and its duplicate same-building test, whose units guard moved into the test that stays; the
regions suite's "a catalogue roadblock posts two guards"; the route lines' duplicate `"1,9,0"`
case; the closures rig's three share thresholds and the gap count that only fed them; the ground
layers' severity table; the scene recipe task suite's two tests reading authored recipe JSON back
and its two-mast file check.

**Tightened.** The car views' "five views" is now as many trim views as body views, and the walker
views' two `== 5` are relations to the gait tables. The orientation suite's `layers.size() == 8` is
now a guard that the sweep was not empty. The ground layers' 22-row direction table is now a
relation read off the `GroundTiles` constants: each directional family is one component turned four
ways, and a direction turns it the same way in every family; the two-source crosswalk is no longer
asserted.

**Kept.** The car's `look.flipped()` check, which its finding did not name. The closures rig's
per-closure check that none lands on the corridor. The home-to-calm floor in the generator suite.
The `5` and `1,4,5` cases in the route lines suite, whose other home is a suite outside the build.

**Run, not removed.** The route rig suite's comment said its checks fail on seeds 1, 2 and 3. Run
on seeds 1, 2, 3 and 5, only seed 2 fails, and only two checks of the kerbed-van clearance test;
the comment says so now, and `tests-hold-nothing.md` keeps the open question of why.

**Open to overturn, the builder's choices.** The home block's `columns()` check went with its
duplicate test; the ground layers relation is a reading of "derive it from `GroundTiles`", the
other reading being to delete the test; the recipe file checks were not moved into
`SceneRecipeRuntime.validate_runtime`, which would change `src/`.
