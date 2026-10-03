# merry-koala — The burnt building is a burnt building · built 2026-09-27

*([olive-koala](../playtests/2026-09-27-olive-koala.md), statement 4: "the *building* is what needs to
be burnt *not* an object next to the building!")*

**Built (PR #415).** The `burnt_shell` scar has no body and draws nothing on the sidewalk.
`City.mark_the_burnt_frontage()` finds the one building whose lot is north of the scar and draws
it `Building.Condition.BURNT`: windows black and broken under soot, the door boarded, the parapet
charred and the wall drained to ash. That look is every `BURNT` building's, the burnt-out blocks
included. A fire is sited only where the tile behind it is on the map, so there is always a lot
to burn. No cordon is drawn. Day 8's red arrow and its touch point are on the burnt building's
door, half a tile up its ground floor, and the task is accepted within 48px of it, which covers
the near half of the two-tile sidewalk in front ([sandy-egret](../playtests/2026-10-03-sandy-egret.md),
statement 2: "or better to the door but the acceptance radius centered at the door should have a
large enough radius for half the sidewalk to be covered"; the still is in
`docs/evidence/sandy-egret-arrow-on-door-2026-10-03/`). Every other contact keeps its 36px reach.

When day 8 starts with no scar recorded — a `--day 8` start, or a day 3 whose fire found no site —
the task's shell is placed on the same kind of ground the day-3 fire is sited on, a sidewalk at a
building's front, the scar is recorded there and that building is burnt, so the task still leads
to a burnt building; a lost day restores the dawn's scars, and a won one keeps it. A test in `tests/test_acts.gd` drives the dawn and checks that building, and
only that one, turns burnt. The player approved the look on the PR's stills
([plaid-hare](../playtests/2026-09-27-plaid-hare.md): "visuals approved").

**Open to overturn:** on a front with no entrance door, the door's stand-ins (the civic portico,
then the drawn storefront pair nearest the scar, then the point straight behind it); that a
precinct's six-tile paving gets the same 48px; that the guard's wake band is still measured from
the 36px reach; and that the day-8 fallback burns a building without moving its block along the
burn arc, since no fire burned there.
