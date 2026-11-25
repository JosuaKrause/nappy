# lilac-marten — Every charger warns for 1.75s and notices her from a quarter farther, with a flag to play other pairs · 2026-11-25

Built for curly-moose #803 (every charger, the stairwell masked man the one exception) and
minty-dolphin #834 (the numbers found by playing them).

**What is built.** `ChargerTiming` holds one warning and one factor on every written notice radius;
the catalogue builds every row from the run's (`EventCatalogue.use_charger_timing()`), shipped as
1.75s and x1.25 (`CHARGER_WARNING`, `CHARGER_REACH`). The written radii stay what they were (the
waiting dog 130px, the alley robber and every man drawn as him 180px, `EventDef.HEAT_HUNTS_WITHIN`
180px, `EventDef.HEAT_INVESTIGATE_WITHIN` 150px), so `--chargers 2 1` (or `?debug=1&chargers=2,1`)
plays the numbers shipped before. A door's crossing warns for the same warning. A charger's field
grows with its notice; a vehicle never notices her past its own field (the patrol: 185px).

**The men sent at her keep their field.** The task's robber, the torn poster's policeman and
guardsman and day 13's sent task guard read the alley robber's field off his row by design (the
same man), so the first build widened theirs with his, 200px to 245px and a pass from 23.3 to 27.9
points, without anybody choosing it. The twenty pixels past his notice are for a man who waits for
her, and these arrive already charging; the item asked for notices and warnings, and a cost the
player feels moves only on their word (inbox #1278 in olive-ferret). So they read his field as
written, 200px (`EventCatalogue._robber_field()`).

**A refused flag is shown.** A `--chargers` or `?chargers=` outside the warning floor or the
0.85 to 1.4 factors plays the shipped pair; the released page's DEBUG MODE ON note names the timing
played, so nobody judges a refused pair by playing the shipped one.

**The alley robber at 225px.** No guard is placed within his notice of her (brisk-wombat, built for
olive-koala 7), and at 225px that left a mark moved into an alley she had come near unguarded
wherever the alley's guard spot, two-thirds through, lay within 225px of her
(`test_resistance_alley_siting`). The first build swapped the notice refusal for the view alone
whenever the guard is kept out of view, which overturned brisk-wombat (`test_resistance_replacement`
failed 613 checks in CI) and was reverted. What is built keeps both: a move never lands in an alley
whose guard would stand within his notice of her (`ResistanceDirector._nearest_alley_among()`),
as it never lands where he would show. Measured with `tests/probes/m213_far_end.gd`, her on every
walkable tile of every other row and column of twenty cities, her screen round her (93760
places): with brisk-wombat alone the mark moved from 23574 of them, landing 327px from her on
average, and went unguarded 46 times at 225px (0.2%) and never at 180px. With the move refused it
moves from 22952 (2.6% fewer, the mark staying where it was), lands 326px off on average and is
never unguarded at 225px; at 180px nothing changes, the view refusing those alleys first. The
probe's older walk, her on every alley tile of six cities (717 moves), never reached the failing
case. The suites that stood her on a mark tile with no screen stand her outside its mouth, since on
the tile its guard would stand within his notice. The roadblock guard's farthest spot follows his band
(`ResistanceDirector.task_guard_farthest()`), since a 225px band left no ring past it inside the
fixed 448px (`test_day13_guard`).

**The patrol's policeman.** Stopped at 185px, the car pulled away into her once its man was back
and struck her when its horn ran out; `EventCarDriving.stand_for_her()` keeps it standing while she
is in its lane within the radius it stopped at (`test_police_car`).

**The escape's roadblock.** A walker straight past a posted band is now caught some 20 to 60px past
it rather than some 260px, so the corner case of `tests/finale_rig.gd` stands its band 48 to 112px
short of the cross street. The trailer's escape chase (`scene-recipes/trailer-chase.json`) stood
its roadblock 240px from her start, inside the guard's wider notice, which the recipe's placement
refuses; it stands 272px off, and she sets off 0.05s later, so he is still within 180px of her
through the shot.

**Open to the player:** the pair itself; a charger's field growing with its notice; a vehicle's
notice capped at its field; a mark that does not move where its guard would notice her.
