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
a dawn placement rebuilds the day's reachability flood, about 0.2 s). The sweeps relocate onto
every mark tile of six built cities, the six seeds the bare-map sweeps asked (4242, 90210,
2295276695, 314159, 271828, 555555; 2295276695 is the seed M100's robber stuck in a building was
found on), kept whole since those sweeps found real bugs (brisk-moose #1130), where they asked
every alley tile of six bare maps (about 2,456): a mark only ever stands on a mark tile, so the
sample covers through-alley ends, courtyard passages, the two-thirds rule, the catch floor, the
touch walk and the doorstep, with walled alleys and the covered corner reached by relocation. The
courtyard sweep checks that it met both kinds of passage, a one-tile passage whose mark stands on
the courtyard's first tile and a passage into an apartment complex's wider court. Every mark and
guard the relocation sweep stands is held off the doorstep's lethal reach too, which widens
PLAYTEST-55's spawn-kill sweep from 33 dawn draws (days 4 to 14 on three seeds) to every mark tile
of six cities, beside its 12 dawn draws (the even mark days 6 to 12 on three seeds). Day 13's
roadblock guard is read where he moves as the red arrow turns to a roadblock; the mast weighting
from two loudspeakers placed as a scene recipe places them, over 32 day-11 reads.

**Deleted as dead:** the whole-circle band a mark's guard was drawn from when its tile was in
neither a through-alley nor a courtyard's passage (`_draw_guard_position()`, with its `toward`
parameter, and the "band" label `_maybe_set_a_trap()` gave a mark): a mark only stands on a mark
tile, and every mark tile is in one or the other, so no mark reached it (none in 130 generated
cities, by the review's probe); only the bare-map test with a mark on a non-alley tile ever did.
`_guard_position()` answers `Vector2.INF` for such a point, as `_guard_spot()` does off an alley.
The probe `tests/probes/m213_far_end.gd` loses the band half it compared against.

**Mutations** applied to the director and caught by the converted tests: the through-alley guard at
half the alley instead of two-thirds (the two-thirds test fails on every mark), the roadblock
guard's way-past check skipped (4 of 67 moves blocked), the dawn contact drawn over alley mouths (0
of 8 one tile in), relocation over alley mouths (0 of 185), the view refusals removed (marks and
guards on screen), uniform mast weights (near 18 against far 14, not more than twice), and a
relocation put on the doorstep (the doorstep check, on all six cities). Dropping the legal-ground
refusal from the relocation fails nothing: no mark tile lies within the doorstep's lethal reach, so
that check holds by the city's own shape as well as by the placement.

**Removed as holding nothing** (curly-rabbit #1097): the "guard distance varies" check, since every
through-alley the generator makes spans a one-block lot, 8 tiles (`CityGenerator._alley_rect()`;
the only wider lots, calm zones and apartment complexes, never get one, and a scene recipe refuses a
multi-block built lot), so his distance from a mark one tile in is the same on every mark tile, and
the 62px floor past the mark binds on none (the test checks the guard's exact spot and that marks at
both ends of an alley were met instead); the mast test's half with no player handed in, a setup only
a bare director has. `_weighted_mast_index()`'s own fallback to the doorstep with no player stays,
the reason on it: every read of her position in the director has a place to fall back to, and with
none every weight would be zero and the draw would fall on the last mast.

**The covered-corner sweep keeps 75 cases where it kept 259.** A case is now kept only where her tick
would put the mark on that tile with the view nowhere near, which is the one place the refusal under
the touch-control corner shows from outside; the dropped cases handed the director a tile it would
never have chosen. Removing the view refusals from `_nearest_alley_among()` fails all 75.

**Counts.** The alley-siting suite went from 32,376 checks to 6,310 and the replacement suite from
2,157 to 1,015, at about the same CPU time; placement kinds gained about 6.6 CPU-seconds, the 32
day-11 reads. `_nearest_alley_among` stays a function of its own beside `_nearest_alley_within`, its
only caller, the underscores being this pass's whole change to it.
