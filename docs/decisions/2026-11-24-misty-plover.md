# misty-plover — The escape's army trucks are sent ahead of her by the director (misty-plover) · 2026-11-25

The player: "no, trucks get placed ahead of her if they're on route. are you referring to trucks as
barriers? if so then, sure they're off route blokades" (inbox #1740 in minty-hare); of a day's
convoy, "just spawn in the car just ahead of the player" (silky-lemur #1460).

**What was built.** The escape city's army trucks are sent ahead of her by the event director as a
day's convoy is. `DaySpec.DirectorSends` has a third value, `SENT_AHEAD_ROWS_OF_ITS_PLAN`, which the city section's
spec sets (the building stays `NOTHING`). `DaySpec.hands_the_director(row)` says which marbles of the
walk's bag are the director's: a row the director sends ahead of her on a day
(`EventDef.is_sent_ahead()`), here `military_convoy`. `DawnDraw` hands `MarbleDraw` that question; a
drawn truck is laid out and judged like any row, then kept with no position as the poster crew is
(`EventScheduler.owed_to_her_walk()`), so its street stands nothing and the rows laid after it are
judged without it. `EventDirector.start_day()` under `SENT_AHEAD_ROWS_OF_ITS_PLAN` owes one slot and one marble for
each unplaced sent-ahead plan of the walk, in a route bag of those trucks alone, and nothing else: no
row of an ordinary day, no rig, no sprinkled dog, no cap by `max_per_day` (the trucks are not rows of
the ordinary bag). The escape hands the director its handouts at its own pace: a quarter of a day's
wait between two (`DaySpec.ESCAPE_HANDOUT_WAIT_SHARE` 0.25 of `EventDirector.AHEAD_INTERVAL`'s 11 to
26 seconds of walking, handed through `DaySpec.handout_wait_share()` and `EventDirector.start_day()`).
A convoy is sited only where it could still be created from wherever the camera can be once its badge
has been up (`EventDirector._holds_while_its_badge_is_up()`), so no badge goes down with nothing
behind it ("a badge shouldn't disappear before the entity is visible", minty-dolphin #852). And where
the lane beside her has no room for it, the director sends the convoy down the street crossing hers
at the next junction box ahead of her, out of sight up it and through the box
(`EventDirector._down_the_street_she_comes_to()`): a rule of every convoy the director sends, a
day's from day 13 as well as the escape's.

**Which marbles are on her route.** Every street of the escape's plan is on one of her two ways out
(the plan names only the streets its chains run along, `DayLocations.along()`; every other street is
sealed), so every truck marble is on her route and none stays at dawn. Once she takes one exit the
other chain's streets are off her walk; nothing stands there under this design, so nothing vanishes,
but the 10 owed trucks span both chains. The trucks that seal the streets off her walk are the seals
(`SealPlanner`, the `finale_barricade` row), not marbles, and stay placed as the off-route blockades
the player describes.

**What one marble a street means.** A street that draws the truck marble stands nothing, and the
truck is met wherever she walks, sent ahead of her at the escape's pace, so the bag's 10 trucks are
10 owed; what she meets is measured below. The counts the bag leaves (10 trucks, 8 explosions, 3 vans,
2 roadblocks, 9 empty) are read as before; the plan's placed dangers are the other three rows, and the
trucks are the plan's unplaced `military_convoy` plans (`escape_winnable.gd`'s plan table counts
placed rows, so it shows 0 trucks). lilac-marten (a fuller escape) reads the counts that way.
sandy-goose's finding, a truck in 10 of 12 walks, describes the trucks placed at dawn, before this
change.

**Measured** (`tests/probes/escape_winnable.gd`, seeds 4242, 1, 77, 9001, 23, 5, 31337, 2024, 7, 808,
11 and 13, both exits, 24 walks, the plain walker; a truck met is a run of `near military_convoy`
lines in the run log less than 2.5 s apart):

| Run | Trucks met | A minute | Walks meeting none | Of walks of 40 s or more, meeting none | Truck badges | Withdrawn | Won |
|---|---|---|---|---|---|---|---|
| main, trucks placed at dawn (`6cd1965eb`) | 28 | 1.56 | 4 | 2 of 15 | 34 | 0 | 10 |
| sent ahead, a day's pace | 15 | 0.79 | 13 | 6 of 17 | 23 | 8 | 9 |
| half a day's wait, badge held while it is up | 17 | 0.90 | 13 | 7 of 17 | 18 | 0 | 9 |
| a quarter of a day's wait | 30 | 1.58 | 13 | 7 of 17 | 30 | 0 | 9 |
| a quarter, and the street she comes to (this change) | 30 | 1.77 | 12 | 7 of 14 | 30 | 0 | 7 |

The second row is the review's measurement of the first version. **The pace moves how many trucks she
meets, not which walks meet one**: the same 13 walks met none at half and at a quarter of a day's
wait, and 9 of the 12 walks to the bridge meet none in the last row. Logging every refused siting on
two walks to the bridge found why: off a plain sidewalk edge there is no lane to site in, and on one
every siting failed because the truck's leg up the lane is cut by an impact crater standing in the
lane (`Navigator.trim()`: the crater is solid to 32 px and the truck, 26 px across, drives straight
down its lane); down the street she comes to, every leg was refused, the cross streets off her walk
being sealed by the barricade trucks. No check is stricter than the game needs: the badge-held check
sweeps the camera along the lane, the one way her moving shifts the truck's place. The losses to the
truck rows are trucks doing their job: three walks to the tunnel are lost to the baby crying (seeds
9001, 11 and 808), and the wins fall from 9 to 7. The four-seed claim this record first carried (the
tunnel out in 1 of 4 walks before and 3 of 4 after) came from the plan reshuffling once a truck was
unplaced and is not a measure of how winnable the section is.

**The gap is accepted for now** (the board question escape-trucks-bridge, the orchestrator's pick):
the escape meets as many trucks a minute as with the trucks placed, and the walks to the bridge that
meet none go to lilac-marten (a fuller escape), whose `fuller-escape.md` names the craters in the
lanes and the sealed cross streets for its builder.

**Rejected:** a further yes-or-no on the spec (the value carries what is sent); a truck marble the
director draws from a bag of its own beside the escape's (two bags for one count); keeping the trucks
placed on streets off her chosen branch (a street off the walk is sealed, so none exists); keeping a
share of the trucks placed at dawn beside her route (a truck on her route is sent ahead of her,
inbox #1740 in minty-hare); a lower pace alone (it moves the count, not which walks meet one); the
badge's place asked again only from where she is (8 of 23 badges went down with nothing behind them
where the lane breaks a second on).

**Tests.** `tests/test_event_director.gd` (a walk sending its own trucks is owed the unplaced ones,
none for a placed one or another row, on day 1 and 14; a walk lets the share of the wait it names pass
between handouts; a convoy is sited only where the ground holds while its badge is up; where the lane
beside her has no leg a car may drive, the convoy comes down the street she comes to),
`tests/test_marble_draw.gd` (a truck handed to the director is recorded unplaced, placed otherwise),
`tests/test_walk_siting_spec.gd` (the hand-off and the pace) and `tests/finale_rig.gd` (no truck of
the bag is placed at dawn). The first version's cases fail on main (the review ran them there), the
street-she-comes-to case fails without its fallback, and calm-hare's test (the escape sends none of an
ordinary day's rows) still holds.
