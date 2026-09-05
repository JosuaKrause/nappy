class_name ControlsMode
extends RefCounted
## Which of the two ways to say where she goes is driving this run: the on-screen stick (and the
## keyboard and RUN button it mirrors) or a tap that walks her there in a straight line.
##
## Exactly one is active, read once the way `TouchInput.available()` already is, because
## `TouchControls` and `TapControls` are two different nodes rather than two branches of one --
## only one of them ever belongs in the tree at a time. See `main._add_touch_controls()`.
##
## Resolves to the stick today -- every build's own behaviour with nothing asked of it.

enum Mode { STICK, TAP }

static func resolve() -> Mode:
	return Mode.STICK
