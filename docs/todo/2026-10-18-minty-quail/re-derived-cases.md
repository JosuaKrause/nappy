# The other facts derived in more than one place

**The ask.** "try finding more such cases -- that's a code smell" (inbox #1156 in gray-dolphin). On the board's
re-derived-state-cases, "yes" to the order picked: what blocks the way and the door flag in the live
form after dawn; two cases with the dawn plan object; three cases one small pull request each; one
case once the plan object exists (inbox #1156 in gray-dolphin).

**Read as:** one fact derived from raw data in more than one place, or a private method re-deriving
what another place already worked out, is moved into one object that derives it once and is handed
to whoever asks (designing-classes). The dawn cases were built with `DayEvents` and `CalmAreas`
(#1158); the after-dawn ones with `WalkEvents` and `DayReach` (#1169).

**What is left of the last case, the ground cache** (which tiles each row may stand on): the day's
walk derives it once, in polite-tapir's `RowGround` (`src/events/row_ground.gd`), which the dawn
makes and hands to every pass and to the walk's sitings. Three places outside a day's walk still scan for themselves: `EventScheduler.recipe_placement()`
makes one ground per authored row of a scene recipe, `SceneRecipeRuntime._finale_placement()` one per
escape actor, and a scene recipe's walk carries no ground, so `EventsAhead._ground_of_the_walk()` makes
one per siting and the resistance director one per ask. The fix is the recipe runtime making one
`RowGround` for its scene and handing it to all three, its walk included. Placement by construction
(polite-tapir's `placement-by-construction.md`) replaces the code `recipe_placement()` sits in, so it
is done there or after.
