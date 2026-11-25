**The riot van and the moving van keep an oval across their whole body, which is what
minty-hedgehog 1 complains about** ("the shadow of a car goes all the way above the roof of the car. it
should only be where the wheels would reasonably be."). Their ground shape is the scene round the
van, not its body (`EventVehicleLook.SCENE_SHAPED`): the night raid's 44px disc holding the officers
round the riot van, and the moving van's band along the street under its ramp and its boxes. Drawn
from those shapes, wheel ovals would be two discs wider than the van, so both keep the shape's
whole oval, wider than the van (the sheet `vans-sheet.png` in
`docs/evidence/silver-egret-shadows-2026-11-25/` shows both as they look now).

**They need a shadow shape of their own**: where the wheels are is not in the ground shape, so it is
found elsewhere, for instance from the picture's own drawn width, as `_draw_stationary_vehicle()`
already uses for the moving van, then laid as the other vehicles' ovals are
(`GroundShape.paired_shadow_outlines()`, one oval per wheel pair). The ground shape stays what the
scene needs it to be: the officers' disc and the ramp's band keep what they are for. Check both
on the vans sheet, the riot van at every sector and the moving van side on and end on.
