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
drafting input, not a runtime source of scene placement. Final integration with the trailer,
motion evidence and review remain in [build the stretch](build-the-stretch.md).

The [decision record](../../decisions/2026-10-04-azure-beaver.md) explains the explicit-data
layout, the rejected generated-city dependency and development recipe packaging. Ordinary
generated play keeps its existing behavior.
