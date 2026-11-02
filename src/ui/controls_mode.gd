class_name ControlsMode
extends RefCounted
## The player's choice of aiming origin, and in joystick mode of the side that steers. Both modes
## lock a heading from a press, run on a double press and re-aim while dragging.
##
## - JOYSTICK aims from the steering focus on the chosen `Side`; the other focus is Run, from the
##   first frame of play. The side is chosen on the title and never swaps during play *(2026-10-10,
##   the player: "selecting the left one will make the left side permanently joystick and the right
##   side permanently run button (permanently for the sitting)")*. See `TouchControls`.
## - TAP aims from her world position, stopping within TouchControls.TAP_STOP_RADIUS of her.
##
## **Neither is tied to a device.** *(2026-09-07, the player: "both modes for in both settings so
## let's let the player choose instead of forcing one ... independent of whether tap is available".)*
## A touchscreen can be set to `TAP` and a mouse can be set to `JOYSTICK` — `TouchInput.available()`
## still answers whether this device has touch hardware, and nothing here reads it any more.
##
## `from_word()` and `side_from_word()` give, once, before the title screen exists, the mode a
## rig gets if it skips the title screen entirely (`--no-title`, a screenshot rig): the command line
## first (`--controls joystick|joystick-left|joystick-right|tap`), then the page's own URL
## (`?controls=`, the same words), then `TAP` — the wording every existing capture and `--walk`
## script was taken under, so a rig's back catalogue keeps reproducing. The run's configuration
## resolves the word (`RunConfig.controls_word`). **The title screen's own buttons are not a third
## step in this order**: they are what decides instead of it, every time the title is actually
## shown — see `TitleScreen`, whose buttons are the only pointer way in and always answer the
## question, the side included. `main._add_touch_controls()` asks the two mappings, and
## `main._on_title_start()` overrides both the moment a player actually presses a button.

enum Mode { JOYSTICK, TAP }
## Which half of the screen steers in `Mode.JOYSTICK`; the other half is Run. Meaningless in
## `Mode.TAP`, where nothing is drawn to choose between.
enum Side { LEFT, RIGHT }

## The word `from_word()` and `side_from_word()` read back as `mode` and `side`: `"tap"` for
## `Mode.TAP`, whose side means nothing, and `"joystick-left"` or `"joystick-right"` for
## `Mode.JOYSTICK`. `main` keeps the title's answer in this form on the `Sitting` it hands down
## (`Sitting.controls_word`), so the boots that open no title of their own read it the way they
## read the configured word.
static func word_for(mode: ControlsMode.Mode, side: ControlsMode.Side) -> String:
	if mode != Mode.JOYSTICK:
		return "tap"
	return "joystick-right" if side == Side.RIGHT else "joystick-left"

## The bare mapping from a raw word — `--controls`/`?controls=`, which the run's configuration
## resolves (`RunConfig.controls_word`) — onto a `Mode`. `"joystick"`, `"joystick-left"` and
## `"joystick-right"` select it; anything else, including an empty string, is `TAP`.
static func from_word(word: String) -> Mode:
	return Mode.JOYSTICK if word in ["joystick", "joystick-left", "joystick-right"] else Mode.TAP

## The steering side a rig gets with the mode `from_word()` answers: `joystick-right` steers from the
## right, and every other word — `joystick` and `joystick-left` included — from the left. Only a
## boot whose title does not ask reads it — a rig that skips the title, or a boot that opens none
## and reads the title's earlier answer (`word_for()`); the title's two joystick buttons choose the
## side themselves.
static func side_from_word(word: String) -> ControlsMode.Side:
	return Side.RIGHT if word == "joystick-right" else Side.LEFT
