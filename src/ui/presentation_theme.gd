class_name PresentationTheme
extends RefCounted
## Shared screen furniture for the tactile architectural presentation.
##
## The world owns its own palette. These values belong only to the quiet space around it:
## paper, ink, navy shadow and the rust of a lit doorstep. Keeping the styles here means title,
## pause and summary cards agree without making the gameplay palette answer for a menu.

const PAPER := Color("f2eadb")
const PAPER_MUTED := Color("c9c0b1")
const INK := Color("202832")
const NAVY := Color("263746")
const NAVY_DEEP := Color("18242f")
const RUST := Color("bd624d")
const RUST_LIGHT := Color("d98a68")
const OCHRE := Color("d8a45d")
const LINE := Color(0.95, 0.91, 0.84, 0.22)

static func card(fill := NAVY, radius := 18, border := Color(0.95, 0.91, 0.84, 0.2), width := 1) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.shadow_color = Color(0.05, 0.08, 0.1, 0.35)
	style.shadow_size = 12
	style.shadow_offset = Vector2(0, 6)
	style.content_margin_left = 28.0
	style.content_margin_right = 28.0
	style.content_margin_top = 22.0
	style.content_margin_bottom = 22.0
	return style

static func button(normal := Color("344857"), hover := Color("456170"), pressed := RUST) -> Dictionary:
	return {
		"normal": card(normal, 12, Color(0.95, 0.91, 0.84, 0.28), 1),
		"hover": card(hover, 12, RUST_LIGHT, 2),
		"pressed": card(pressed, 12, Color(1.0, 0.93, 0.82, 0.7), 2),
		"focus": card(hover, 12, RUST_LIGHT, 2),
	}
