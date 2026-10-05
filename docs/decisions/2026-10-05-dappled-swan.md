# dappled-swan — What she can see leaves out the touch-control corners · 2026-10-05


Filed from [feathery-lynx](../playtests/2026-10-05-feathery-lynx.md) (inbox #581): "remove the area at
the bottom left and right up to the top of the joystick circle and horizontal extent of the speed
button -- use that everywhere where visibility is concerned -- for the other mode those rectangles
*do* count", then "yes, everything should follow this (and treat it depending on the input mode)";
and inbox #598 in [olive-hedgehog](../playtests/2026-10-05-olive-hedgehog.md): "off screen is not the
same as visible -- the corners get removed for visible not for off screen".

**One visible area answers every "can she see it".** `VisibleView` (`src/ui/visible_view.gd`) is the
camera's view less both bottom corners in the joystick scheme and the whole view in the tap scheme,
following the scheme in use and the screen's rotation: `sees()` for a point, `sees_any()` for a box,
`clear_of_sight()` for the distance at which a box is wholly out of sight. `EventManager` keeps one
per day; `EventManager._is_on_screen()` and `DangerEdge.is_on_screen()` are gone. It answers the
screen-edge badge (on while the thing is out of sight), the chalk mark counting as noticed, the
fire's sighting (and the fire engine's summons), the poster crews' pasting, and the counter's seen.
Joystick-scheme tests cover each.

**Off screen is not visible.** Spawning goes wholly outside the camera's whole view, corners
included (M226's no pop-in); the corners are left out only for what she can see.

**Chosen while building, open to overturn:** the fire's sighting stays a point test against the area;
the poster crews' pasting counts as a sighting; streaming and residency keep the whole view.
