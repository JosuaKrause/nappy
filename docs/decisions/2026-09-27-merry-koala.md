# merry-koala — The burnt building is a burnt building · built 2026-09-27

*([olive-koala](../playtests/2026-09-27-olive-koala.md), statement 4: "the *building* is what needs to
be burnt *not* an object next to the building!")*

**Built (PR #415).** The `burnt_shell` scar draws nothing on the sidewalk. `City._mark_the_burnt_frontage()`
finds the one building whose lot is north of the scar and draws it `Building.Condition.BURNT`
(blackened, roofless, windows gone), the look burnt-out blocks already have. Day 8's touch point
and cordon are unchanged, and its red arrow ends on the building (M222). A test in
`tests/test_acts.gd` checks that building and only that one turns burnt. No still exists: a forced
fire does not sit at a front, and a real one needs a long unbroken walk no rig managed, so the
review item asks the player to look on day 8.
