# The stairwell masked man is placed when he should appear, warned first

The player: "Stairwell guard could as well be placed when it should appear instead of when
entering", and, asked whether the stairwell guard keeps the charger's badge rule, "The stair guard
can become a charger that is triggered by a location if necessary" (minty-dolphin #852).

**Build:** the escape building's stairwell masked man is no longer placed when she enters the
building. He is placed at the moment he should appear, with his screen-edge badge put up first,
pointing at where he will come from, and his 426px run distance and 23.5px catch (minty-quail-21)
kept. Every outcome the stairwell tests pin (a walker is caught, a runner gets through on every line)
holds.

**Once this and the army truck are both placed after their badge**, `BadgeModel`'s
`_measure_dangers_in_the_world()` and what only it reads go, as a deletion, in whichever of
the two PRs lands second.

*Proposed, not asked for:* what sets him off is a place on the stairwell she reaches, as the
player's "triggered by a location" allows, rather than a time.
