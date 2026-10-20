# Day 12's cordon officers walk through the navigator

Every mover goes through the world's one `Navigator` and asks `CityMap.passable()` except day 12's
cordon officers, the police who walk in from out of sight and tape the park shut
(`ParkCordon._walk_path_for()`, whose comment says why). Their walk in and the taper's walk round
the park's edge are laid straight, at a fixed offset outside the park, through whatever the day
stands there: on seed runs a `collapsed_frontage` band on the park's sidewalk and a `busker` in the
park. The close is timed and its pace set over those straight walks (`_round_path()`,
`_time_the_close()`). So an officer walks through a body that stops her.

Put on the navigator as they stand, an officer stalls at such a body and the cordon never closes.
Made to go round to his next point, the last gap closes 15–37s after the touch on 9 of
`test_park_cordon_seeds`' parks, against the deadline the cordon solves (no sooner than
`Tuning.PARK_CLOSING_SECONDS`, 12s, and the walk from where she stood to the gap plus 2s; the
plush-marten record), and the busker's escort no longer brings him out through the gap.

The player: "I mean that happens with a lot of events (eg cat / bike just completely ignoring
buildings; neighbor walking through barricades) we need to do a fix for this at some point but not
now", and "those are examples not an exhaustive list" (minty-lemur #791).

**Build:** `ParkCordon` plans the officers' approach, the taper's round path and its timing round
the day's bodies on the record before walking them, and walks them through the navigator; the close
keeps its deadline and the escorts still bring the park's people out through the last gap.
