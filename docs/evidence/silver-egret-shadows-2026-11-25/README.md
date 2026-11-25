# silver-egret — a car's shadow lies under its wheels · 2026-11-25

**The claim.** A car's and every other vehicle's shadow now lies where its wheels meet the ground,
one squashed oval per wheel pair (`GroundShape.paired_shadow_outlines()`), the nearer pair on the
bottom of its picture, where before it was its ground shape's one oval or capsule, which on the cars
drawn over their bodies (the crowd cars, the police car, the fire engine) spread behind the whole
picture and past the roof of the end-on views. The riot van and the moving van keep their whole
body's shadow. Props are unchanged.

**What each file shows.**

- `cars-sheet.png`: the crowd car, the police car and the fire engine at all eight sectors, east
  first and then clockwise, each row before and after; the police car a third time with its body
  riding up `WheelBob.HEIGHT` (1px) over its wheels and shadow, its second ride frame.
- `vans-sheet.png`: the delivery van, the army truck, the ice-cream van, the reversing lorry and the
  unmarked van at all eight sectors, and the burnt-out car side on and end on, before and after.
  Most of these are only ever seen side on in play (`docs/decisions/2026-09-11-M108-eight-direction-entity-graphics-the-event-vehicles-and-the-police-car.md`);
  every sector is drawn so a view the game may reach later is judged too.
- `ingame-junction.png`: the game, before (left) and after (right), at a T junction on the
  recipe city: the start frame (a crowd car side on, the parked delivery van, the police car heading
  south at the top) over the frame a second later (the crowd car mid-turn, the police car end on).
- `ingame-truck.png`: the same street a second earlier on another recipe, before and after: the army
  truck and the delivery van side on.

**Limits.** The sheets are drawn by a probe, not the renderer: the pictures are re-rasterised from
their SVGs and the shadows filled pixel by pixel on a plain sidewalk-coloured ground, though the
shadow outlines come from the game's own calls (`EventLook.shadow_outlines()`,
`AgentLook.shadow_outlines()`) and the pictures stand where the game stands them. On the road's dark
asphalt a shadow reads fainter than on the sheets. The in-game stills are single frames of one
seed and route; the police car's diagonal and both ride frames are shown on the sheet only, since
no recipe here catches it mid-turn. The halo round the cars charging her is the game's own.

**How they were made**: the "before" captures from `main` at c60129fad, the "after" ones and the
sheets from the branch's commit dc76a0be2129b5018dd074e5a4b4e261c65a5938 (`feature-silver-egret-shadows`):

- the sheets: `tools/test.sh probes/silver_egret_shadow_sheet.gd` writes one PNG per row under the
  game's `user://silver-egret-shadow-sheet/`, and `python3 -I compose_sheet.py <that folder>
  cars-sheet.png 0.5 crowd-car-before crowd-car-after police-before police-after
  police-after-riding fire-engine-before fire-engine-after` (and the same with the van rows) labels
  and stacks them; the PNGs are quantised to 256 colours to stay small;
- the in-game stills: `tools/scene-recipes.sh --recipe recipe-junction.json --screenshots` and the
  same with `recipe-truck.json` (seed 11, construction city 1917501, day 13, a fixed camera at zoom
  1.6), once on `main` and once on the branch, each pair halved and set side by side.

**The cost**, measured as the M139 record's desktop walk was (`tools/shot.sh out.png 20 --seed
3265820891 --day 1 --walk 3s17e`, the mean of the run log's `frame` entries from two seconds in, one
run each): before 281.4 draws, 3842 primitives, 115.8 fps, 9.3ms process, 21.7ms physics; after
284.8 draws, 3947 primitives, 114.4 fps, 9.1ms process, 21.6ms physics. A vehicle on screen fills
two polygons where it filled one, about three more draw calls on this walk, and the crowd's tick
(the physics line) does not move.
