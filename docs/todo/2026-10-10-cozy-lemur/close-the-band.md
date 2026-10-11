Space the posts so the carriageway band at each precinct mouth is impassable to her body and the
pram, and the pavements beside the row stay passable. M53's `BOLLARD_SPACING` was 14px, five posts
on the 64px band (`City.bollard_positions()` derives the count from the band and the spacing);
the spacing only has to leave every gap narrower than her body (`Tuning.PLAYER_BODY_RADIUS`, 14px)
plus the pram's circle at every facing, so 14px is the starting point, not a requirement. Each post
keeps its `StaticBody2D` (`Prop._add_bollard_body()`).

Rewrite what states the gaps are passable: the `BOLLARD_SPACING` comment in `src/city/city.gd`,
the comment over `_add_bollard_body()` in `src/city/prop.gd`, `docs/CITY.md`'s bollard paragraph,
and `tests/test_bollards.gd` (its gap tests become: the row stops her walking straight at it and
at 30° and 45° either way from every offset across the band, the pavement beside the row lets her
pass). The review item `docs/review/2026-10-07-tall-walrus.md` asks whether the gap lets her
through, so it is replaced by one asking the player to walk a precinct mouth and see the road
closed and the pavements open.

Check what still walks through the band: the day's route line and the route rig (`src/dev/route_rig.gd`)
may draw or walk straight through the posts' cell of the junction box, where the pavements are the
way past now; a route that "never has to cost" must go round on the pavement. Crowd walkers have no
bodies and pass through the posts; say in the record whether that still reads, and leave it unless
it does not. Connectivity is unaffected: the pavements either side stay open, so the row is a
detour inside the junction box, never a cut.
