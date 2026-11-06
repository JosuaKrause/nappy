class_name TouchCover
extends RefCounted
## **The screen cover the on-screen controls hand the world** (`TouchControls.covering`), made the way
## the game makes it: a `TouchControls` told the joystick scheme is in force, and the cover it keeps.
## Shared by the suites that ask what she can see under the joystick's two corners
## (`VisibleView`, `SpawnSiting`, the events' placement). A helper, not a suite: the runner loads
## only `test_*.gd`.

## The cover with the joystick scheme in force: both corners as the controls cover them.
static func joystick() -> ScreenCover:
	var controls := TouchControls.new()
	controls.set_mode(ControlsMode.Mode.JOYSTICK)
	var cover := controls.covering
	controls.free()
	return cover
