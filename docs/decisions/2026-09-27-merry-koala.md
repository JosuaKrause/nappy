# merry-koala — The burnt building is a burnt building · built 2026-09-27

*([olive-koala](../playtests/2026-09-27-olive-koala.md), statement 4: "the *building* is what needs to
be burnt *not* an object next to the building!")*

**Built (PR #415).** The `burnt_shell` scar has no body and draws nothing on the sidewalk.
`City._mark_the_burnt_frontage()` finds the one building whose lot is north of the scar and draws
it `Building.Condition.BURNT`: windows black and broken under soot, the door boarded, the parapet
charred and the wall drained to ash. That look is every `BURNT` building's, the burnt-out blocks
included. A fire is sited only where the tile behind it is on the map, so there is always a lot
to burn. Day 8's touch point is the scar itself, the frontage tile in front of the facade, and no
cordon is drawn. A test in `tests/test_acts.gd` drives the dawn and checks that building, and
only that one, turns burnt. The player approved the look on the PR's stills
([plaid-hare](../playtests/2026-09-27-plaid-hare.md): "visuals approved").
