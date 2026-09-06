class_name DirectionalParts extends RefCounted
## Directional PNG-sheet registrations and the direction selector shared by modular actors.
##
## A registration is deliberately data-only: eight real rectangles, one logical anchor,
## one texture pivot and eight layer values. Missing views are errors rather than an
## invitation to mirror a different drawing.

enum Direction { N, NE, E, SE, S, SW, W, NW }

const DIRECTION_NAMES: PackedStringArray = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
static var DIRECTION_VECTORS: Array[Vector2] = [
	Vector2(0.0, -1.0), Vector2(1.0, -1.0).normalized(), Vector2(1.0, 0.0),
	Vector2(1.0, 1.0).normalized(), Vector2(0.0, 1.0),
	Vector2(-1.0, 1.0).normalized(), Vector2(-1.0, 0.0),
	Vector2(-1.0, -1.0).normalized(),
]


class PartRegistration extends RefCounted:
	var part_id: String
	var variant: String
	var texture: Texture2D
	var rects: Array[Rect2]
	var anchor: Vector2
	var pivot: Vector2
	var pivots: Array[Vector2]
	var z_orders: Array[int]

	func pivot_for(direction: int) -> Vector2:
		if direction < 0 or direction >= pivots.size():
			return pivot
		return pivots[direction]

	func rect_for(direction: int) -> Rect2:
		if direction < 0 or direction >= DirectionalParts.DIRECTION_NAMES.size():
			return Rect2()
		return rects[direction]

	func z_for(direction: int) -> int:
		if direction < 0 or direction >= DirectionalParts.DIRECTION_NAMES.size():
			return 0
		return z_orders[direction]


class SpriteManifest extends RefCounted:
	var _parts: Dictionary = {}
	var errors: Array[String] = []

	func register_part(part_id: String, texture: Texture2D, rects: Array[Rect2],
			anchor: Vector2, pivot: Variant, z_orders: Array[int], variant: String = "default") -> bool:
		var key: String = _key(part_id, variant)
		if part_id.is_empty():
			return _fail("part id is empty")
		if texture == null:
			return _fail("part '%s' variant '%s' has no PNG texture" % [part_id, variant])
		if rects.size() != DirectionalParts.DIRECTION_NAMES.size():
			return _fail("part '%s' variant '%s' needs 8 direction rectangles, got %d" % [part_id, variant, rects.size()])
		if z_orders.size() != DirectionalParts.DIRECTION_NAMES.size():
			return _fail("part '%s' variant '%s' needs 8 direction z-orders, got %d" % [part_id, variant, z_orders.size()])
		for direction: int in DirectionalParts.DIRECTION_NAMES.size():
			if rects[direction].size.x <= 0.0 or rects[direction].size.y <= 0.0:
				return _fail("part '%s' variant '%s' has an empty %s direction rectangle" % [part_id, variant, DirectionalParts.DIRECTION_NAMES[direction]])
		if _parts.has(key):
			return _fail("part '%s' variant '%s' is already registered" % [part_id, variant])
		var registration: PartRegistration = PartRegistration.new()
		registration.part_id = part_id
		registration.variant = variant
		registration.texture = texture
		registration.rects = rects.duplicate()
		registration.anchor = anchor
		registration.pivots = _pivots(pivot)
		registration.pivot = registration.pivots[0]
		registration.z_orders = z_orders.duplicate()
		_parts[key] = registration
		return true

	func register_variant(part_id: String, variant: String, texture: Texture2D, rects: Array[Rect2],
			anchor: Vector2, pivot: Variant, z_orders: Array[int]) -> bool:
		return register_part(part_id, texture, rects, anchor, pivot, z_orders, variant)

	func has_part(part_id: String, variant: String = "default") -> bool:
		return _parts.has(_key(part_id, variant))

	func require_part(part_id: String, variant: String = "default") -> PartRegistration:
		var key: String = _key(part_id, variant)
		if not _parts.has(key):
			_fail("missing part '%s' variant '%s'" % [part_id, variant])
			return null
		return _parts[key] as PartRegistration

	func make_sprite(part_id: String, direction: int, variant: String = "default") -> Sprite2D:
		var registration: PartRegistration = require_part(part_id, variant)
		if registration == null:
			return null
		if direction < 0 or direction >= DirectionalParts.DIRECTION_NAMES.size():
			_fail("part '%s' received missing direction index %d" % [part_id, direction])
			return null
		var sprite: Sprite2D = Sprite2D.new()
		sprite.name = part_id
		sprite.texture = registration.texture
		sprite.region_enabled = true
		sprite.region_rect = registration.rect_for(direction)
		sprite.centered = false
		sprite.offset = -registration.pivot_for(direction)
		sprite.position = registration.anchor
		sprite.z_index = registration.z_for(direction)
		return sprite

	func update_sprite(sprite: Sprite2D, part_id: String, direction: int, variant: String = "default") -> bool:
		var registration: PartRegistration = require_part(part_id, variant)
		if registration == null:
			return false
		if direction < 0 or direction >= DirectionalParts.DIRECTION_NAMES.size():
			_fail("part '%s' received missing direction index %d" % [part_id, direction])
			return false
		sprite.texture = registration.texture
		sprite.region_enabled = true
		sprite.region_rect = registration.rect_for(direction)
		sprite.centered = false
		sprite.offset = -registration.pivot_for(direction)
		sprite.z_index = registration.z_for(direction)
		return true

	func part_count() -> int:
		return _parts.size()

	func _key(part_id: String, variant: String) -> String:
		return "%s\u001f%s" % [variant, part_id]

	func _pivots(value: Variant) -> Array[Vector2]:
		var result: Array[Vector2] = []
		if value is Array:
			for item: Variant in value:
				if item is Vector2:
					result.append(item)
		if result.size() == DirectionalParts.DIRECTION_NAMES.size():
			return result
		result.clear()
		var fallback: Vector2 = value as Vector2
		for _direction in DirectionalParts.DIRECTION_NAMES.size():
			result.append(fallback)
		return result

	func _fail(message: String) -> bool:
		errors.append(message)
		push_error(message)
		return false


static func new_manifest() -> SpriteManifest:
	return SpriteManifest.new()


static func direction_from_heading(heading: Vector2, fallback: int = Direction.S) -> int:
	if heading.length_squared() <= 0.000001:
		return fallback
	var normalized: Vector2 = heading.normalized()
	var best: int = fallback
	var best_dot: float = -INF
	for direction: int in DIRECTION_VECTORS.size():
		var dot: float = normalized.dot(DIRECTION_VECTORS[direction])
		if dot > best_dot:
			best_dot = dot
			best = direction
	return best


static func select_direction(velocity: Vector2, heading: Vector2, previous: int,
			hysteresis_degrees: float = 12.0, deadzone: float = 0.01) -> int:
	var source: Vector2 = heading if velocity.length() <= deadzone else velocity
	var candidate: int = direction_from_heading(source, previous)
	if previous < 0 or previous >= DIRECTION_VECTORS.size():
		return candidate
	var current_vector: Vector2 = DIRECTION_VECTORS[previous]
	var source_vector: Vector2 = source.normalized()
	var sector_half: float = PI / 8.0
	var hysteresis: float = deg_to_rad(hysteresis_degrees)
	if current_vector.dot(source_vector) >= cos(sector_half + hysteresis):
		return previous
	return candidate


static func direction_name(direction: int) -> String:
	if direction < 0 or direction >= DIRECTION_NAMES.size():
		return ""
	return DIRECTION_NAMES[direction]
