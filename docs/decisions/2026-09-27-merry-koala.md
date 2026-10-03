# merry-koala — The burnt building is a burnt building · built 2026-09-27

*([olive-koala](../playtests/2026-09-27-olive-koala.md), statement 4: "the *building* is what needs to
be burnt *not* an object next to the building!")*

**Built (PR #415).** The `burnt_shell` scar has no body and draws nothing on the sidewalk.
`City.mark_the_burnt_frontage()` finds the one building whose lot is north of the scar and draws
it `Building.Condition.BURNT`: windows black and broken under soot, the door boarded, the parapet
charred and the wall drained to ash. That look is every `BURNT` building's, the burnt-out blocks
included. A fire is sited only where the tile behind it is on the map, so there is always a lot
to burn. Day 8's touch point is the scar itself, the frontage tile in front of the facade, and no
cordon is drawn. The red arrow for that task ends on the burnt building's ground floor, one tile
north of the scar, not on the bare sidewalk (the item's "the red arrow ends on the building. A
still in the PR."; the still is in
`docs/evidence/merry-koala-arrow-on-burnt-building-2026-10-03/`).

When day 8 starts with no scar recorded — a `--day 8` start, or a day 3 whose fire found no site —
the task's shell is placed on the same kind of ground the day-3 fire is sited on, a sidewalk at a
building's front, the scar is recorded there and that building is burnt, so the task still leads
to a burnt building; a lost day restores the dawn's scars, and a won one keeps it. A test in `tests/test_acts.gd` drives the dawn and checks that building, and
only that one, turns burnt. The player approved the look on the PR's stills
([plaid-hare](../playtests/2026-09-27-plaid-hare.md): "visuals approved").

**Open to overturn:** the arrow's end at one tile north of the scar; and that the day-8 fallback
burns a building without moving its block along the burn arc, since no fire burned there.
