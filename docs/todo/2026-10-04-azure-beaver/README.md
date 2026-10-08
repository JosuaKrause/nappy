priority: now

# azure-beaver — The task scenes are a handcrafted stretch with a rigged marble bag · filed 2026-10-04

[polite-dolphin](../../playtests/2026-10-04-polite-dolphin.md) records the original request:
"the whole point of those scenes is that they are not seeded but handcrafted -- you can use a
seed to create it. but then everything should be placed manually. the events should still
spawn using the same rules but the marble bag should be rigged". The stretch is the streets
she walks, both sidewalks and the carriageway, crossings and corners, with no ground beyond.
It includes people, wear and events so it is a useful test of a real day.

[mossy-marmot](../../playtests/2026-10-08-mossy-marmot.md), inbox #618, answers the open layout
question: "Finish fully handcrafted layouts now (Recommended)". Finish that design inside
PR #592; the generated-layout alternative is not selected.

The recipes load explicit map context and editable stretch placements. A seed is an optional
drafting input, not a runtime source of scene placement. Final integration with the trailer
and task arrows, motion evidence and review remain in [build the stretch](build-the-stretch.md).

[pebbly-hare](../../playtests/2026-10-08-pebbly-hare.md), inbox #622, asks whether scene
recipes are ignored in production. They are present in the published package. The proposed
exclusion and local-loading checks are in [development recipe packaging](development-recipe-packaging.md).

The [decision record](../../decisions/2026-10-04-azure-beaver.md) retains the partial work and
the rejected generated-city dependency. Ordinary generated play keeps its existing behavior.
