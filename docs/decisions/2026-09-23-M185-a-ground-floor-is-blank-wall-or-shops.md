## M185 — A ground floor is blank wall or shops · built 2026-09-23

*([PLAYTEST-123](../playtests/PLAYTEST-123.md), statements 13, 25 and 26;
[PLAYTEST-124](../playtests/PLAYTEST-124.md).)* One Sonnet agent on
`feature/ground-floor-blank-or-shops` built the rule; a fresh Opus agent in the same worktree drew
and placed the entrance doors and redrew the storefronts. Reviewed by the orchestrator; the player
accepted the pictures ("All graphics look okay so far … it's a clear improvement"). The home
block's fixed visuals stay open in `TODO.md`.

**What was built.** `Building._draws_window_at()` leaves the ground-floor row of a multi-story
building without windows unless the building is on the home block (`is_home_building`, set by
`City._spawn_buildings()` from `CityMap.home_block`); a one-row facade and the power station are
unchanged. A multi-story `RESIDENTIAL` or `INDUSTRIAL` front, and a `COMMERCIAL` front with no
complete storefront span, gets one door (`entrance_door_col()`), drawn from
`art/buildings/entrance_door.svg` or `entrance_door_industrial.svg`; a storefront or the civic
portico is already a way in. `blank_ground_floor_cells()` answers the cells a poster crew may
paste on. The twelve `storefront_*.svg` are redrawn in the doors' outlined style. The player's
"Her building is the entire home square" confirmed the whole home block as hers.

**Measured.** No generated commercial lot has an odd number of columns — `Tuning.BLOCK_SIZE`, the
corner square and the alley offset are all even — so the odd-column rule is real code that no
street shows; `tests/test_ground_floor.gd` exercises it on a synthetic front. No existing RNG
stream moved: the test replays the window, front and door seeds.

**Open to overturn, chosen where the design was silent.**
- The door's column is rolled from a stream of its own (`door:`), so no other roll moved.
- It never stands on the fire escape's column, avoids the columns beside it when the front has
  another, and avoids the corners while there is a choice.
- One plain door for every purpose that gets one, and a steel one for industrial fronts.
- The door is 36px tall like a storefront; the first-floor windows above it lift 2px as they do
  over a storefront.
- The poster cells leave out the fire escape's column as well as the door's.
- A boarded or burnt block shows the same door.
- The home block gets no extra door; her own door is already cut into it.
- The four storefront kinds have new colours; the awning covers the display bay only; the
  shuttered storefront carries a spray tag; fascia lettering is abstract bars, not words.
