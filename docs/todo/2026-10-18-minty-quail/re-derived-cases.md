# The other facts derived in more than one place

**The ask.** "try finding more such cases -- that's a code smell" (inbox #1156 in gray-dolphin). On the board's
re-derived-state-cases, "yes" to the order picked: what blocks the way and the door flag in the live
form after dawn; two cases with the dawn plan object; three cases one small pull request each; one
case once the plan object exists (inbox #1156 in gray-dolphin).

**Read as:** one fact derived from raw data in more than one place, or a private method re-deriving
what another place already worked out, is moved into one object that derives it once and is handed
to whoever asks (designing-classes). The dawn cases were built with `DayEvents` and `CalmAreas`
(#1158); the after-dawn ones with `WalkEvents` and `DayReach` (#1169).

**What is left: a scene's walk works out its route tree and locations again.** A scene recipe
makes one `RowGround` and hands it to its rows, its escape actors and its walk (the record
2026-10-18-minty-quail-mossy-puffin). When the walk sites something (day 11's mast),
`SitingMaker._assemble()` grows the route tree again, with the scene's edges shown, because
`EventManager.start_a_given_walk()` never sets `EventsAhead._day_tree`; and it lays out the day's
locations again, though `SceneRecipeRuntime._event_plans()` already holds both. The fix is the
runtime handing the walk the tree and the locations it holds, as it hands the ground.
