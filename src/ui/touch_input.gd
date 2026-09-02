class_name TouchInput
extends RefCounted
## Whether this device has a touchscreen, and the single place that question is answered.
##
## `DisplayServer.is_touchscreen_available()` rather than `OS.has_feature("mobile")`. The game
## ships as one Web export (see M60) that runs unchanged whether the tab is opened on a phone or
## a desktop, and `has_feature("mobile")` is a tag baked into the export at build time — it cannot
## vary with the device that happens to load the page, so on this project's only distribution it
## would answer the same way for everyone. `is_touchscreen_available()` asks the browser what the
## visiting device actually reports, which is the only one of the two that can drive "the controls
## appear only where they are used" at all.
##
## It also answers `true` for a touchscreen laptop that has a keyboard too, which then draws the
## on-screen stick and run button next to a perfectly good `WASD`. That is the smaller of the two
## costs on offer: the other one is a phone told to press a key it does not have.
##
## Read once per screen into a member (`TouchControls._touch`, and anywhere a hint has to agree
## with it) rather than asked here at each use site, because a test process is never a touch
## device: a gate asked of the OS directly at every call site would leave the touch shape asserted
## by nothing at all. `QuitOption.available()` and `hud._debug` follow the same pattern for their
## own platform questions.

static func available() -> bool:
	return DisplayServer.is_touchscreen_available()
