# minty-quail — The resistance director's five placement queries become internal, their tests reading the world · 2026-11-06

minty-quail's `tests-own-class-members.md`, the underscore pass, for the resistance director's
five placement queries, which record minty-quail-sunny-heron left public on cost: a public member
only its own class and the tests use becomes internal and its tests move to what the class does
outward (curly-rabbit #1098).

**Built.** `guard_position`, `place_contact`, `nearest_alley_within`, `nearest_alley_among` and
`weighted_mast_index` in `src/resistance/resistance_director.gd` are internal, with no `[kept]`
line: each is checked from outside. The cheap world probe is a relocation: the rig's
`_relocate_round()` stands her stroller far from an unseen mark and runs one `tick()`, and the test
reads where the mark moved and the guard it got off the street (under a millisecond a probe, where
a dawn placement rebuilds the day's reachability flood, about 0.2 s). The sweeps sample every mark
tile of three built cities (seeds 4242, 90210 and 271828, about 300 tiles) where they asked every
alley tile of six bare maps (about 2,456): a mark only ever stands on a mark tile, so the sample
covers through-alley ends, courtyard passages, the two-thirds rule, the catch floor, the touch walk
and the doorstep, with walled alleys and the covered corner reached by relocation. Day 13's
roadblock guard is read where he moves as the red arrow turns to a roadblock; the mast weighting
from two loudspeakers placed as a scene recipe places them, over 32 day-11 reads.

**Mutations** applied to the director and caught by the converted tests: the mark guard drawn from
the whole-circle band (the two-thirds test fails on every mark), the roadblock guard's way-past
check skipped (4 of 67 moves blocked), the dawn contact drawn over alley mouths (0 of 8 one tile
in), relocation over alley mouths (0 of 185), the view refusals removed (marks and guards on
screen), uniform mast weights (near 18 against far 14, not more than twice).

**Removed as holding nothing** (curly-rabbit #1097): the "guard distance varies" check, since every
alley of these cities is 8 tiles long and the 62px floor past the mark never binds on a mark tile
(the test checks the guard's exact spot and that marks at both ends of an alley were met instead);
the mast test's half with no player handed in, a setup only a bare director has. The alley-siting
suite went from 32,376 checks to 2,567 and the replacement suite from 2,157 to 704, at about the
same CPU time; placement kinds gained about 6.6 CPU-seconds.

**Open:** no suite now reaches `_guard_position`'s whole-circle band draw for a mark, and no mark
tile seems able to reach it in the game, so it may be dead code; it is left in place.
`_nearest_alley_among` stays separate from `_nearest_alley_within`, now its only caller.
