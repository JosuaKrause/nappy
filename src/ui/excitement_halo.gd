class_name ExcitementHalo
extends Node2D
## A soft glow around whatever is actually charging the meter right now — an identification cue,
## not a map. It answers *which of the six things around her*, which the meter itself cannot: a
## number says how much, never which.
##
## **It traces the thing's own outline and stops four pixels past it.** *(2026-09-07, the player:
## "halo meaning only the outline of the object not the influence radius. it's only meant to show
## which objects currently affect the player (and how much depending on the strength of the halo).
## the halo should not extend more than a few pixels beyond the object's outline.")*
## `EventDef.outer_radius` — how far a source's excitement actually reaches — is a large fraction of
## what the camera shows at all, a 640x360 world view at the game's own zoom against radii up to
## 200px, so drawing *that* paints most of the screen however the brightness inside it is shaped.
## `glow_radius()` reads `EventDef.obstructs_radius`, half the thing's silhouette, instead.
##
## **Size answers *which*, brightness answers *how much*, and neither answers the other.** Brightness
## is `EventInstance.contribution_at(her position)` — the real excitement model, the one part of the
## first reading of "what is causing excitement to go up" that was right — so a source that barely
## clears the floor glows faintly and one near its own peak glows close to full, each at its own
## body's size either way.
##
## Two questions decide what gets drawn: which sources count (`select_sources()`) and how bright
## each one's own circle reads. See `docs/EVENTS.md`, "The visual vocabulary", for how this cue
## sits beside the caret, the badge and the exclamation mark rather than replacing any of them.

## Excitement/s a source has to reach at her own position before it earns a place in the halo.
##
## **A felt number, not a derived one.** `Busker` (9/s) is the lowest ordinary intensity in the
## catalogue and a `crouching cat` at rest still reaches `Tuning.MARK_WORTH_A_DETOUR` (25/s) at
## its centre, so 1.0/s sits comfortably under both: anything genuinely inside a field is drawn,
## and only the thin, nearly-spent tail of a falloff — where the number would round to nothing
## on the meter anyway — is left off. Checked against a screenshot, not derived from a formula:
## there is no arithmetic that says where "reaching her" starts to matter.
const CONTRIBUTION_FLOOR := 1.0

## The most sources one frame may draw, matched to the shader's own fixed-size uniform arrays in
## `assets/shaders/excitement_halo.gdshader`. **Past the cap the weakest contributors are the
## ones left out**, in `select_sources()` below — not the furthest and not the newest — because
## dropping the smallest terms of a sum is the smallest possible error the drawn total can carry.
## An ordinary corner never approaches this: `CLAUDE.md`'s own note is that the *whole city's*
## concurrent event count stays a few dozen even on the last day, and this is a filter over what
## is above `CONTRIBUTION_FLOOR` at one point, which is a handful by construction.
const MAX_SOURCES := 8

## Which live events earn a place in the halo, strongest contribution first, capped at
## `MAX_SOURCES`.
##
## **A cue that marks everything says nothing** (`.claude/skills/cues/SKILL.md`), so the set is
## never "every event the day planned" — it is `EventInstance.contribution_at(at)` above the
## floor, which is a handful at a time by construction and goes to zero the instant she walks out
## of every field at once.
##
## **A `city_wide` source is excluded on purpose.** `contribution_at()` answers it with the flat
## intensity from anywhere in the city — "there is nowhere in the city it does not reach" — so
## drawing a localised glow at its instance's own position would show a field it does not have.
## `docs/EVENTS.md`'s vocabulary already has its answer for that source: a HUD line, "for a
## `city_wide` source, which has no position and therefore nothing to stand under."
##
## Pulled out as a static function so a test can hold the selection, the floor and the drop order
## without a scene, a shader or a viewport — the same reason `DangerEdge.announces()` is static.
static func select_sources(instances: Array[EventInstance], at: Vector2) -> Array[EventInstance]:
	var ranked: Array = []
	for instance in instances:
		if instance.def.city_wide:
			continue
		var contribution := instance.contribution_at(at)
		if contribution > CONTRIBUTION_FLOOR:
			ranked.append([contribution, instance])
	# Strongest first, so a cap keeps the sources that matter most to the sum and drops the ones
	# that would have changed it least.
	ranked.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
	var picked: Array[EventInstance] = []
	for i in mini(ranked.size(), MAX_SOURCES):
		picked.append(ranked[i][1])
	return picked

# ------------------------------------------------------------------ drawing ---
# One node, one shader, fed the active sources as uniform arrays — not one shape per event, so
# two sources standing close together still sum in the shader's own per-fragment total and read
# brighter where their small circles cross. It is no longer a picture of `EventManager
# .total_excitement_at()` the way an earlier version of this file was — that sum is a field
# spanning each source's whole `outer_radius`, and a field is nearly the whole screen at this
# camera's zoom. What is drawn now is a compact glow per source, sized in `glow_radius()` below,
# with `EventInstance.contribution_at()` deciding only how bright each one's own circle is. See
# `assets/shaders/excitement_halo.gdshader`.

const SHADER := preload("res://assets/shaders/excitement_halo.gdshader")

## Excitement/s at which a source's own glow reads at its brightest. Shared with
## `Tuning.MARK_WORTH_A_DETOUR` (25/s) — the same line the caret already draws between
## "ignorable" and "worth a detour" — so the halo and the caret agree on what counts as loud.
const SATURATES_AT := 25.0

## How far past a source's own outline its glow may reach, in world px. *(2026-09-07, the player:
## "halo meaning only the outline of the object not the influence radius ... the halo should not
## extend more than a few pixels beyond the object's outline.")* **Four pixels is "a few" at this
## game's scale**: the whole visible world is 640x360 at zoom 2, and a person's own half-width
## (`EventCatalogue.PERSON_BODY`, 11px) is barely more than twice it — so the glow reads as light
## coming off the silhouette rather than as a disc the thing is standing in.
const GLOW_BODY_MARGIN := 4.0
## What a row with no outline to trace gets, before the margin above is added. Every `mobile` row
## is exempt from carrying an `obstructs_radius` at all (`docs/EVENTS.md`, "Anything that stands
## still is solid at the width it is drawn") — a `dog_walker` and a `homeless_yeller` are both
## people-shaped on screen and both would otherwise glow at zero — so they are treated as the
## person they are drawn as, `EventCatalogue.PERSON_BODY` (11px).
const GLOW_BODYLESS_RADIUS := 11.0

## The radius one source's glow is drawn at: **its own outline plus `GLOW_BODY_MARGIN` (4px), and
## nothing else.**
##
## `EventDef.obstructs_radius` is "half the silhouette" for anything that stands still
## (`docs/EVENTS.md`, "Solid things are solid"), so it is the one number already on a def that means
## *how big is the thing* rather than *how far does it reach* — which is the whole distinction this
## cue rests on. A busker (`PERSON_BODY`, 11px) glows at 15px and a `barricade` (62px) at 66px:
## **there is no ceiling, because a ceiling would draw a big thing's halo inside its own outline**,
## which is the one shape this is not allowed to be.
static func glow_radius(def: EventDef) -> float:
	var outline := def.obstructs_radius if def.obstructs_radius > 0.0 else GLOW_BODYLESS_RADIUS
	return outline + GLOW_BODY_MARGIN

var _events: EventManager
var _player: Node2D
var _material: ShaderMaterial
## What `_draw()` fills with the shader material this frame, in this node's own local space —
## which is world space, since this node never moves. Empty while nothing clears the floor.
var _bounds := Rect2()
var _drawing := false

func setup(events: EventManager, player: Node2D) -> void:
	_events = events
	_player = player

func _ready() -> void:
	_material = ShaderMaterial.new()
	_material.shader = SHADER
	# The same amber the excitement bar itself fills with — see Palette.EXCITEMENT_FIELD's own
	# doc — so the glow and the number it is a picture of read as one fact rather than two.
	_material.set_shader_parameter("halo_colour", Palette.EXCITEMENT_FIELD)
	_material.set_shader_parameter("saturates_at", SATURATES_AT)
	material = _material

func _process(_delta: float) -> void:
	if not _events or not _player:
		return
	var here := _player.global_position
	_update_sources(select_sources(_events.instances(), here), here)
	queue_redraw()

## Writes the shader's uniform arrays and works out how much ground `_draw()` needs to cover.
##
## The arrays are fixed at `MAX_SOURCES` because a Godot shader array uniform is fixed-size —
## unused slots past `picked.size()` are written with a harmless zero radius and brightness and
## never read, since the shader's own loop stops at `source_count`.
func _update_sources(picked: Array[EventInstance], here: Vector2) -> void:
	var positions := PackedVector2Array()
	var radii := PackedFloat32Array()
	var brightness := PackedFloat32Array()
	positions.resize(MAX_SOURCES)
	radii.resize(MAX_SOURCES)
	brightness.resize(MAX_SOURCES)
	var bounds := Rect2()
	for i in picked.size():
		var instance := picked[i]
		var at := to_local(instance.global_position)
		var radius := glow_radius(instance.def)
		positions[i] = at
		radii[i] = radius
		# What is actually reaching her, not the source's own peak: a source she can only just
		# feel glows faintly at its own body, one near its centre glows near full, and both are
		# the same size — the size answers *which thing*, the brightness answers *how much*.
		brightness[i] = instance.contribution_at(here)
		var reach := Rect2(at - Vector2.ONE * radius, Vector2.ONE * radius * 2.0)
		bounds = reach if i == 0 else bounds.merge(reach)
	_drawing = not picked.is_empty()
	_bounds = bounds
	_material.set_shader_parameter("source_position", positions)
	_material.set_shader_parameter("source_radius", radii)
	_material.set_shader_parameter("source_brightness", brightness)
	_material.set_shader_parameter("source_count", picked.size())

func _draw() -> void:
	if not _drawing:
		return
	# The rect is only what `_update_sources()` says is worth covering, not the whole screen: the
	# shader's own sum is only ever nonzero inside it, so anything wider is overdraw with nothing
	# to show for it.
	draw_rect(_bounds, Color.WHITE)
