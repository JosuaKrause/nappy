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
## pause button next to a perfectly good `WASD`. That is the smaller of the two costs on offer: the
## other one is a phone told to press a key it does not have.
##
## Read once per screen into a member (`TouchControls._touch`, and anywhere a hint has to agree
## with it) rather than asked here at each use site, because a test process is never a touch
## device: a gate asked of the OS directly at every call site would leave the touch shape asserted
## by nothing at all. `QuitOption.available()` and `hud._debug` follow the same pattern for their
## own platform questions.
##
## `--touch` forces this true (`RunConfig.touch_forced`, a debug build's flag like every other dev
## flag): nothing on the machine that runs `tools/test.sh` or an exported build has a real
## touchscreen, so without it a touch-only screen could never be rendered, and
## `tools/shot.sh out.png 3 --touch --walk north` is how the touch HUD is looked at. The run's
## configuration is handed in, so nothing here reads the command line; with none handed in (a
## screen built outside a boot) the answer is the hardware's alone.
static func available(config: RunConfig = null) -> bool:
	if config != null and config.touch_forced:
		return true
	return DisplayServer.is_touchscreen_available()

## Whether `event` is a generic press from a pointing device — a real finger
## (`InputEventScreenTouch`) or a left mouse click — the one shape `TitleScreen`, `DaySummary` and
## `PauseScreen` all need to dismiss themselves: each already tests `ui_accept` on its own for the
## keyboard's equivalent, and ORs this in alongside it rather than this folding `ui_accept` in
## itself, since `ui_accept` has nothing to do with a touch device.
static func is_press(event: InputEvent) -> bool:
	if event is InputEventScreenTouch:
		return (event as InputEventScreenTouch).pressed
	if event is InputEventMouseButton:
		var button := event as InputEventMouseButton
		return button.pressed and button.button_index == MOUSE_BUTTON_LEFT
	return false
