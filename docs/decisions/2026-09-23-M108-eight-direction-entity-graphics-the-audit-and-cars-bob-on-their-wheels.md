## M108 — Eight-direction entity graphics · the audit and cars bob on their wheels, built 2026-09-23

*(2026-09-11, [PLAYTEST-56](../playtests/PLAYTEST-56.md): "cars could bop up and down while the
wheels stay in the same place".)* Two commits (5dcf316b, the audit; 280bb3fe, the wheel split),
reviewed here. **The audit** compared every tracked SVG under `art/` against
`assets/atlases/membership.json` and the region-name literals in `src/`, `scenes/` and the
TileSet, and resolved every path `GRAPHICS.md` names against the tree; only three dead constants
had no runtime caller. It corrected `GRAPHICS.md`'s prepared/live table — the protester's eight
`protester_point_*` poses were live but marked prepared, and M106, the M100 vent and portico, and
most of the M108 vehicle rows were marked "now live" without staying current — narrowed the table
to work that still has an owner, and added an "Unbound, with nothing to bind them" table naming
every superseded or unreachable source. The linked inventories (`svg-vehicles-2026-09-10/facings.
csv` + README, `svg-environment-2026-09-10/sources.csv` + INVENTORY, the people matrix) had their
binding/status columns dropped rather than refreshed, since a second copy of the binding is
exactly how they went stale — each now says the catalogue alone records what is bound. A new
`_test_a_transfer_only_ever_stands_in_for_its_own_source` in `tests/test_atlas_library.gd` checks
221 regions (94 diagonals drawn from their own SVG, 26 from their own PNG) so an available
cardinal PNG cannot stand in for a diagonal or another state's frame.

**Cars bob on their wheels.** Each crowd car view's tyres moved out of `car_{view}_trim.svg` into
a third layer, `car_{view}_wheels.svg`, on the same canvas and anchor; the six event vehicles that
move (police car, fire engine, unmarked van, riot van, army truck, lorry) each got the same split
across their five views — 35 new files, 35 `membership.json` lines. `src/visuals/wheel_bob.gd`
holds one curve shared by both owners: a **1px** rise and fall over every **64px** of road
covered. The crowd car (`CrowdAgent._body_bob()`) bobs at full height from the 60px/s turn speed
upward and **fades below that turn speed**, so a stopped car sits still on its wheels; the event
vehicles (`EventInstance._current_bob()`) ride the same curve over ground covered, replacing the
2.5px walking-stride bob they used to share with people, and read zero on a tick with no movement.
`EntityHalo` lifts its ring by the same `bob()` so the rim traces what is drawn. On the ten 34×50
truck and van end views the tyres were always drawn under the body's edge, so there
`EventInstance.WHEELS_BEHIND_THE_BODY` keeps them under it; everywhere else they draw over it. At
rest, every split view differs from its old picture by at most 3/255, on no pixel by more than
8/255.

**Rejected / left as is:** the inventories' status columns were dropped rather than refreshed
(above); the parked delivery van and ice-cream van keep their tyres in one picture, since they sit
still; 1px and 64px are felt values, open to change after a look, not derived; the army truck is
included though M108's item didn't name it, since it is an event vehicle that moves.
