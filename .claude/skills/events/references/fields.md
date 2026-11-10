# The fields that are decisions, and the ones that are not

Read this before adding a row, or before changing a row's `spawn_mode`, `on_her_way`, `hard_fail`,
`pavement_side`, `departs_at` or `flock_size`, or what `EventScheduler.role_for()` answers.

**`spawn_mode` is a decision.** `MAP` is the default and is right for anything the player could plan
around: it is a place, and finding out it is there is what walking a street is for.
`AHEAD_OF_PLAYER` is for the small number whose entire content is *the moment it happens to you* —
three seconds of cat is not a place. `TOWARD_PLAYER` (`cyclist`, `loose_dog`) is sited on her line
coming at her: traffic she answers with a route, not an ambush. Neither director-sited mode may
obstruct.

**`EventDef.on_her_way` is a decision about *when* a place is chosen.** A `MAP` row, a one-shot
(day 3's fire) or recurring (the poster crews), never mobile, placed by her walk rather than at
dawn; `EventDef.validate()` refuses any other combination.

**`hard_fail` is a decision, and it decides where the thing goes as well as what it does.**

**The role is not a decision.** `EventScheduler.role_for()` reads it off the def: scenery, ambient
and director-sited rows get none; a one-shot is a **set piece**, sited on her way, since something
she must meet exists wherever she goes (`docs/CITY.md`, "A set piece has to be met"), and
`EventDef.validate()` refuses a one-shot without `on_her_way`; `hard_fail`, a `walk_through_cost()`
at or over `EventScheduler.WALL_WORTH_OF_COST` (a share of the meter), or a reach that leaves no
line past it along a sidewalk makes a **wall** (zero copies on any cell a route runs along);
anything else is **friction** (weighted onto the corridor). A `paces` row's role depends on where
its beat runs, so `StreetInvalidation._a_pacing_beat_walls_a_sidewalk()` decides it in the
candidate loop, where the beat exists. A row that wants a role its data does not imply needs a
change to `EventScheduler.role_for()`, not a new field.

**`obstructs_radius` is not a decision.** If it stands still and it is drawn, it is solid at half
its silhouette.

**`pavement_side` usually is not one either** — `ANY` is right for most rows. A kerb
(`AT_THE_KERB`) is for what parks at the road's edge, a van or a skip; a wall
(`AGAINST_THE_BUILDING`) is for what belongs to a frontage, a lorry backing in or a poster crew.

**`departs_at` is only a decision for a stationary event with a `duration`.** Anything mobile
already leaves at its own speed, and anything without a duration never ends.

**`flock_size` changes what a row *is* rather than what it does.** Reach for it only when the event
genuinely is a number of creatures, and set `flock_spread` out of `outer_radius` rather than on top
of it.
