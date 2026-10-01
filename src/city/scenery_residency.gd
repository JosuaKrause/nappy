class_name SceneryResidency
extends Node
## Prepares camera-adjacent artwork while retaining the complete gameplay city. The inner
## guard is synchronous; ordinary offscreen preparation is bounded and nearest-first. A jump
## or a changed view prepares the destination before the renderer sees it.

const LOAD_MARGIN := 256.0
const RETAIN_MARGIN := 512.0
const GUARD_MARGIN := 96.0
const BUDGET_USEC := 2000
var city: City
var view := Rect2()
var _items: Array[Node2D] = []
var worst_update_usec := 0

func _ready() -> void:
	# Camera and rig callbacks finish before residency reads their final transform. This node
	# also works while the game is paused, because orientation and overview can still change.
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_priority = 1000

func register(item: Node2D) -> void:
	_items.append(item)
	item.set_scenery_resident(false)

func _process(_delta: float) -> void:
	if city and city.map and city.is_visible_in_tree():
		update(camera_view())

func camera_view() -> Rect2:
	var viewport := city.get_viewport()
	if viewport.get_camera_2d() == null:
		return Rect2(city.map.doorstep_world_position() - Tuning.VIEW_HALF_EXTENT,
				Tuning.VIEW_HALF_EXTENT * 2.0)
	var inverse := viewport.get_canvas_transform().affine_inverse()
	var size := viewport.get_visible_rect().size
	var rect := Rect2(inverse * Vector2.ZERO, Vector2.ZERO)
	for corner: Vector2 in [Vector2(size.x, 0), size, Vector2(0, size.y)]:
		rect = rect.expand(inverse * corner)
	return rect

func update(next_view: Rect2, immediate := false) -> void:
	var started := Time.get_ticks_usec()
	var relocated := not view.has_area() or view.size != next_view.size \
			or view.get_center().distance_to(next_view.get_center()) > GUARD_MARGIN
	view = next_view
	var load_view := view.grow(LOAD_MARGIN)
	var retained := view.grow(RETAIN_MARGIN)
	var guard := load_view if immediate or relocated else view.grow(GUARD_MARGIN)
	var ground := city._ground
	for key: Vector2i in ground.chunks.keys():
		if not retained.intersects(SceneryGround.bounds(key)):
			ground.release(key)
	var pending: Array[Dictionary] = []
	for key in ground.keys_in(load_view):
		if ground.chunks.has(key):
			continue
		var bounds := SceneryGround.bounds(key)
		if guard.intersects(bounds):
			ground.prepare(key)
		else:
			pending.append({"distance": bounds.get_center().distance_squared_to(view.get_center()),
					"prepare": ground.prepare.bind(key)})
	for item in _items.duplicate():
		if not is_instance_valid(item) or item.is_queued_for_deletion():
			_items.erase(item)
			continue
		var bounds: Rect2 = item.scenery_bounds()
		if item.scenery_resident:
			if not retained.intersects(bounds):
				item.set_scenery_resident(false)
		elif guard.intersects(bounds):
			item.set_scenery_resident(true)
		elif load_view.intersects(bounds):
			pending.append({"distance": bounds.get_center().distance_squared_to(view.get_center()),
					"prepare": item.set_scenery_resident.bind(true)})
	pending.sort_custom(func(a: Dictionary, b: Dictionary): return a.distance < b.distance)
	for job in pending:
		if Time.get_ticks_usec() - started >= BUDGET_USEC:
			break
		(job.prepare as Callable).call()
	city._building_shadows.update_view(load_view, retained)
	city._decals.update_view(load_view, retained)
	worst_update_usec = maxi(worst_update_usec, Time.get_ticks_usec() - started)
