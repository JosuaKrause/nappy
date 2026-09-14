class_name DebugModeNote
extends CanvasLayer
## The fixed note that a page is running with `?debug=1` (or `--debug`) — see docs/DECISIONS.md,
## M133, "the readout on the live page". `main.gd` builds exactly one of these, only when
## `DevFlags.readout_requested()` holds, and never frees it, hides it or answers to any input:
## no key, no press and no screen this game ever opens takes it back off. An ordinary debug build
## shows the developer readout without this note, since nobody already running a debug build needs
## telling it is one — this exists for the one build that could otherwise pass for the ordinary
## release page a visitor gets everywhere else.
##
## A separate node from `_status` (the readout `main.gd` already draws) on purpose: `_status.visible`
## is flipped off by the title screen and by the `4` key, and a note that could be turned off the
## same way would not be the fixed note the milestone asks for. Plain text is layout, not a picture
## — see the **cues** skill, "A picture is an asset, never code", which names a debug overlay
## alongside a scrim as the two things that rule does not cover.

## Top-left, the readout's own top-right corner mirrored, so the two never compete for the same
## reading position and neither is mistaken for part of the other.
const _MARGIN := Vector2(14.0, 14.0)
## Terse on purpose — a claim to keep reading, not a phrase to parse. "Debug" names what the
## flag is; "on" says the state rather than repeating the readout's own word for it.
##
## **The build stamp follows the words** — `TitleScreen.build_text()`, `git describe`'s form and
## the commit, `v0.10.3 (875609a5)` — *(2026-09-13, playtest 70: "Debug mode should contain the
## commit + describe.")*, because a screenshot of a debug page is evidence of some build, and
## nothing else on it says which: the title screen's version line is off screen the moment a run
## starts, and on a release it names only the tag. Read once here; the readout's first line
## repeats it.
const _TEXT := "DEBUG MODE ON"

func _init() -> void:
	# Above `_status`'s own `CanvasLayer` (the scene's default `layer = 1`), so nothing the readout
	# or a future overlay draws can sit on top of the one label that must stay legible.
	layer = 10

func _ready() -> void:
	var label := Label.new()
	label.name = "Note"
	label.text = "%s   %s" % [_TEXT, TitleScreen.build_text()]
	label.position = _MARGIN
	label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.85))
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("outline_size", 5)
	label.add_theme_font_size_override("font_size", 14)
	add_child(label)
