class_name ControlsMode
extends RefCounted
## Which of the two ways to say where she goes is driving this run: the on-screen stick (and the
## keyboard and RUN button it mirrors) or a tap that walks her there in a straight line.
##
## Exactly one is active, read once the way `TouchInput.available()` already is, because
## `TouchControls` and `TapControls` are two different nodes rather than two branches of one --
## only one of them ever belongs in the tree at a time. See `main._add_touch_controls()`.
##
## Resolves to the stick unless the local command line says otherwise — `--controls tap|stick`,
## gated behind `DevFlags.enabled()` like every other developer flag, since a debug build is the
## only place a command line can reach at all.

enum Mode { STICK, TAP }

static func resolve() -> Mode:
	return from_word(DevFlags.controls_override())

## The bare mapping from a raw word, such as `DevFlags.controls_override()`'s own, onto a `Mode`.
## Pulled out so a test can ask the mapping directly without a real command line to answer through.
static func from_word(word: String) -> Mode:
	return Mode.TAP if word == "tap" else Mode.STICK
