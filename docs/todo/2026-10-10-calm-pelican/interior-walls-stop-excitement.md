# Walls inside the building stop excitement too

**Medium · from the re-review of PR #567 (polite-rabbit, excitement does not go through a wall).**
The player: "Excitement should not go through **any** wall". Indoor events are spawned with no map
(`src/finale/interior_events.gd`, `_spawn`), and `EventInstance._walled_off()` answers "not walled
off" whenever there is no map, so the masked man on the stairs, the fire in the left shaft and the
basement's mouse or steam can reach her through interior walls; nobody has measured whether any
does. The record [polite-rabbit-2](../../decisions/2026-10-04-polite-rabbit-2.md) lists interiors as
"Left open", but #567 deleted the queue entry. Build a wall check over the interior map's walls, or
measure that no indoor field crosses a wall and say so in the PR.

**Low, same area:**
- The debug fields layer still draws fields through buildings (`docs/TELEMETRY.md` and
  `docs/EVENTS.md` admit it), against the layer's purpose, that it "cannot disagree with what the
  meter does". Cut or tint the outline where `CityMap.wall_between()` blocks.
- Three places still call the building-ends question open after the player answered it in
  bouncy-kestrel (#568): `src/city/city_map.gd` ("the end is open to them"), `docs/EVENTS.md`
  ("with the ends open to them"), `tests/test_wall_shield.gd` ("the end is a question put to
  them"). Replace each with the answer.
- `docs/MECHANICS.md`'s "So any wall stops it" is false as built: a line through a two-tile-thick
  building gets through within a tile of an open end (the tests pin 31px from the end as passing),
  and a 2x2 building blocks only a line through its middle. Describe what is built.
