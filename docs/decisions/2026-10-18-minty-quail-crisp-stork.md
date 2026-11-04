# minty-quail — Building fronts and traffic-light lamps draw through drawers the city hands in (tests through public seams: W5c) · 2026-11-04

minty-quail's `tests-public-seams.md`: the front and lamp drawers, the next step of the drawn-art
shape after the roof drawer (record sandy-raven), from the player's answer to drawn-art-tests (inbox
#1018 in brisk-ferret).

**Built.**
- `FrontDrawer` (`src/city/front_drawer.gd`) lays a picture of a building's front grid and stands an
  overlay (the door, the portico, a fire escape, the station door): every atlas picture of a front
  goes through it, in the same order, place and tint as before. `City._spawn_buildings()` builds one
  over its atlas and hands it to every building through `Building.front_drawer`; a building handed
  none makes its own.
- `TrafficLightDrawer` (`src/city/traffic_light_drawer.gd`) draws a signal head in one of its views
  and paints its lit lamp; `City._spawn_signal_heads()` hands one to every head through
  `TrafficLight.drawer`, and a head handed none makes its own.
- The picture choices (`Building._front_parapet_texture()`, `_clerestory_texture()`,
  `TrafficLight._lamp()`) stay private: each is a pure choice with no random draw that only its own
  class's drawing calls, so a test reads its answer off a recording drawer
  (`tests/recording_front_drawer.gd`, `tests/recording_traffic_light_drawer.gd`) handed through the
  member the city sets. The real drawers paint on a canvas a headless run cannot read back; they are
  the general drawing code, and before and after stills of a lit street on the last day
  (`docs/evidence/front-drawer-2026-11-04/`) show fronts and signal heads unchanged pixel for pixel.
- `test_blackout.gd` (private-read lines 4 to 0) draws a head handed the city's signals and checks it
  shows one lamp while lit and none in the blackout, and draws a station hall dressed with the
  city's own station members, checking its clerestory band after each change of power;
  `test_city_decay.gd` (2 to 1) checks every picture each burnt front was drawn with. Checks 36 and
  164858 to 38 and 165354; twelve mutation runs.

**Open to overturn:** one drawer for a whole front rather than one per element, as the roof drawer
does; the lamp drawer beside the light in the world layer; where a lamp sits on the head, worked out
by the drawer from the light's constants. Burnt parapets alternating their charred pictures is
checked by neither the old nor the new suite.

**Not done:** `test_city_decay.gd`'s `EventScheduler._prefer_beside_a_sack_pile`.
