class_name HelpText
extends RichTextLabel
## A line of help that can carry the symbol of an on-screen button in the middle of its words.
## *(2026-10-04, the player, inbox #533: "the press pause to pause text should say press <pause
## button> to pause where it uses the in-game symbol. Likewise joystick run should now say hold <run
## button> or double tap to run".)*
##
## A line is plain text with two tokens in it, `{pause}` and `{run}`, each standing for the atlas
## region `TouchControls` draws as that button (`ui/pause`, `ui/run`). `show_line()` lays the words
## out and puts the picture at the token's place, one line tall, centred on the text, so the symbol
## in the sentence is the glyph on the button rather than a word describing it.
##
## **Why a `RichTextLabel` and not a `Label`:** a `Label` cannot hold an image in a line. The
## symbols are regions of the baked `ui` page, which `[img]` markup cannot name (it loads a path),
## so the images are added through `add_image()` with the region's own texture. The atlas group is
## acquired for as long as this node is in the tree — a region is valid only while its group is
## held, see `AtlasLibrary`.
##
## `line` is the line as written, tokens included, so a test (and a caller deciding whether the line
## changed) reads what was said without having to read a picture back out of the layout.

const PAUSE_TOKEN := "{pause}"
const RUN_TOKEN := "{run}"

const _ICONS := {
	PAUSE_TOKEN: &"ui/pause",
	RUN_TOKEN: &"ui/run",
}

## The line as last handed to `show_line()`, tokens unexpanded.
var line := ""

## The control group `TouchControls` joins, so a line can ask which scheme is in force without any
## screen having to be handed the mode: the title screen chooses it at runtime, after the screens
## exist.
const CONTROLS_GROUP := &"touch_controls"

func _enter_tree() -> void:
	AtlasLibrary.acquire(&"ui")

func _exit_tree() -> void:
	AtlasLibrary.release(&"ui")

## Whether the chosen scheme is the joystick one — the only one that draws run buttons, and so the
## only one where a line may name a run button. False when no `TouchControls` exists (a test, or
## a screenshot rig that never built one), which is the tap scheme's wording.
static func joystick_in_force(tree: SceneTree) -> bool:
	var controls := tree.get_first_node_in_group(CONTROLS_GROUP) as TouchControls
	return controls != null and controls.controls_mode() == ControlsMode.Mode.JOYSTICK

## `text` with each token replaced by two letters' worth of width, for `SentenceLines` to measure
## the line by: the icon is one line tall and about as wide.
static func measurable(text: String) -> String:
	return text.replace(PAUSE_TOKEN, "MM").replace(RUN_TOKEN, "MM")

## Replaces what the label shows with `new_line`, centred, the symbols in place.
func show_line(new_line: String) -> void:
	line = new_line
	clear()
	if new_line == "":
		return
	var size := get_theme_font_size("normal_font_size")
	push_paragraph(HORIZONTAL_ALIGNMENT_CENTER)
	var rest := new_line
	while rest != "":
		var at := _next_token(rest)
		if at.x < 0:
			append_text(rest)
			break
		if at.x > 0:
			add_text(rest.substr(0, at.x))
		var token := rest.substr(at.x, at.y)
		add_image(AtlasLibrary.region(_ICONS[token]), size, size, Color.WHITE,
				INLINE_ALIGNMENT_CENTER)
		rest = rest.substr(at.x + at.y)
	pop()

## Where the first token in `text` starts (x) and how long it is (y), or (-1, 0) for none.
static func _next_token(text: String) -> Vector2i:
	var best := Vector2i(-1, 0)
	for token: String in _ICONS:
		var i := text.find(token)
		if i >= 0 and (best.x < 0 or i < best.x):
			best = Vector2i(i, token.length())
	return best
