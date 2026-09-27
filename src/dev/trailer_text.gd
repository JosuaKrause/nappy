class_name TrailerText
extends CanvasLayer
## The on-screen text of a trailer shot: `--caption <text>`, one line high on the screen, and
## `--title-card <text>`, the game's name across the middle over the title screen's own scrim.
## *(PLAYTEST-139: "we can put some on-screen texts.")*
##
## **Drawn in the game rather than by ffmpeg afterwards**, so the words are set in the same font,
## outline and colours the title screen sets its own in (`scenes/ui/title_screen.tscn`: the title at
## 64px with an 8px black outline over a 0.62 scrim, the body in its warm grey) — ffmpeg's
## `drawtext` would need a font file on the machine and would set it in a face the game never
## uses. It also puts the text inside the frames `tools/trailer.sh --check` compares, so a caption
## is part of what "the same output every time" is checked against.
##
## Both fade in over `FADE_SECONDS` once `DELAY_SECONDS` of the shot has passed and then hold; the
## cut to black at the end of each shot is `tools/trailer.sh`'s, so nothing here fades out. The
## clock is the frame's own `delta`, which the movie writer's `--fixed-fps` makes the same on every
## render.

## Seconds of the shot before the text starts to appear — long enough that the cut into the shot is
## read as a picture first.
const DELAY_SECONDS := 0.3
const FADE_SECONDS := 0.5

## The title screen's own scrim colour, and its body text's warm grey.
const SCRIM := Color(0.04, 0.04, 0.06, 0.62)
const CAPTION_COLOR := Color(0.8, 0.78, 0.74, 1.0)

var _elapsed := 0.0
var _root: Control

## Builds whatever the two flags asked for; `null` when neither was given, so `main.gd` adds nothing
## to an ordinary run's tree.
static func from_flags() -> TrailerText:
	return build(DevFlags.caption_text(), DevFlags.title_card_text())

## The same, from the two strings directly, so a test can build one without a command line.
static func build(caption: String, title: String) -> TrailerText:
	if caption == "" and title == "":
		return null
	var node := TrailerText.new()
	node.name = "TrailerText"
	# Above the HUD and the screen-edge badge, below nothing a trailer shot shows.
	node.layer = 100
	node._root = Control.new()
	node._root.name = "Root"
	node._root.set_anchors_preset(Control.PRESET_FULL_RECT)
	node._root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node._root.modulate.a = 0.0
	node.add_child(node._root)
	if title != "":
		var scrim := ColorRect.new()
		scrim.name = "Scrim"
		scrim.color = SCRIM
		scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
		scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
		node._root.add_child(scrim)
		node._root.add_child(_label("Title", title, 64, 8, Color.WHITE,
				Control.PRESET_FULL_RECT))
	if caption != "":
		# High on the screen, under the clock: the lower half is where the HUD's own one-line
		# lessons ("Tap to walk, double tap to run") and the meters stand.
		var line := _label("Caption", caption, 30, 6, CAPTION_COLOR, Control.PRESET_TOP_WIDE)
		line.offset_top = 70.0
		line.offset_bottom = 130.0
		node._root.add_child(line)
	return node

static func _label(label_name: String, text: String, size: int, outline: int, color: Color,
		preset: Control.LayoutPreset) -> Label:
	var label := Label.new()
	label.name = label_name
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(preset)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_constant_override("outline_size", outline)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_color_override("font_color", color)
	return label

func _process(delta: float) -> void:
	_elapsed += delta
	_root.modulate.a = opacity_at(_elapsed)

## How visible the text is `elapsed` seconds into the shot: nothing until `DELAY_SECONDS`, then a
## linear rise to full over `FADE_SECONDS`, then full.
static func opacity_at(elapsed: float) -> float:
	return clampf((elapsed - DELAY_SECONDS) / FADE_SECONDS, 0.0, 1.0)
