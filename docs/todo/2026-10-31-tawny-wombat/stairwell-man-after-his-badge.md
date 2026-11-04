# The stairwell masked man is placed when he should appear, warned first

The player: "Stairwell guard could as well be placed when it should appear instead of when
entering", and, answering whether every screen-edge badge stays up until its danger is in sight
(the board question badge-keeps), "The stair guard can become a charger that is triggered by a
location if necessary" (minty-dolphin #852).

**Build:** the escape building's stairwell masked man is no longer placed when she enters the
building. He is placed at the moment he should appear, with his screen-edge badge put up first,
pointing at where he will come from, and his 426px run distance and 23.5px catch (minty-quail-21)
kept. Every catch outcome the stairwell tests pin (a walker is caught, a runner gets through on
every line) holds.

**Once this and the army truck are both placed after their badge**, `BadgeModel`'s
`_measure_dangers_in_the_world()` and what only it reads go, as a deletion, in whichever of
the two PRs lands second.

**Collides with teal-trout-2** (the masked man waits standing): today he is placed at the foot of
the stairwell when she enters and waits there, drawn standing through his wait and his notice and
lunging once the notice is over, and `_test_masked_man_is_drawn_standing_until_he_goes` in
`tests/test_event_views.gd` pins each stage of that picture. **Open:** whether he still has a wait
once he is placed when he should appear (placed, standing, then running, so the drawn stages and
their test stay) or comes on screen already running, which drops the wait stage and changes that
record and its test.

*Proposed, not asked for:* what sets him off is a place on the stairwell she reaches, as the
player's "triggered by a location" allows, rather than a time.
