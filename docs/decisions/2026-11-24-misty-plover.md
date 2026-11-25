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
the ordinary bag).

**Which marbles are on her route.** Every street of the escape's plan is on her walk (the plan
names only the streets its chains run along, `DayLocations.along()`; every other street is sealed),
so every truck marble is on her route and none stays at dawn. The trucks that seal the streets off her
walk are the seals (`SealPlanner`, the `finale_barricade` row), not marbles, and stay placed as the
off-route blockades the player describes.

**What one marble a street means.** A street that draws the truck marble stands nothing, and the
truck is met wherever she walks, down the lane beside her just ahead of her, at the director's pace
(`EventDirector.AHEAD_INTERVAL`, 11 to 26 seconds of walking), so the bag's 10 trucks are 10 owed and
a walk of about a minute meets two to five. The counts the bag leaves (10 trucks, 8 explosions, 3
vans, 2 roadblocks, 9 empty) are read as before; the plan's placed dangers are the other three rows,
and the trucks are the plan's unplaced `military_convoy` plans (`escape_winnable.gd`'s plan table
counts placed rows, so it shows 0 trucks). lilac-marten (a fuller escape) and sandy-goose (do the
escape city's rows show up) read the counts that way.

**Measured** (`tests/probes/escape_winnable.gd`, seeds 4242, 1, 77, 9001, the game's own bag, the
plain walker): before, 1 of 4 walks to the tunnel out (61.6s) and 1 of 4 to the bridge (40.5s);
after, 3 of 4 to the tunnel (82.5s on average) and 1 of 4 to the bridge (40.6s). Four seeds are a
sample, not a measure of how winnable the section is.

**Rejected:** a further yes-or-no on the spec (the value carries what is sent); a truck marble the
director draws from a bag of its own beside the escape's (two bags for one count); keeping the trucks
placed on streets off her chosen branch (a street off the walk is sealed, so none exists).

**Tests.** `tests/test_event_director.gd` (a walk sending its own trucks is owed the unplaced ones,
none for a placed one or another row, on day 1 and 14), `tests/test_marble_draw.gd` (a truck handed
to the director is recorded unplaced, placed otherwise), `tests/test_walk_siting_spec.gd` (the
hand-off) and `tests/finale_rig.gd` (no truck of the bag is placed at dawn); the first three fail on
main, and calm-hare's test (the escape sends none of an ordinary day's rows) still holds.
