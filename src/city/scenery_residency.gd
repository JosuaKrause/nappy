class_name SceneryResidency
extends Node
## Prepares camera-adjacent artwork while retaining the complete gameplay city. The inner
## guard is synchronous; ordinary offscreen preparation is bounded and nearest-first. A jump
## or a changed view prepares the destination before the renderer sees it.

## An eight-cell batch is 256px; at 168px/s it takes 1.52s to cross the load margin.
## The 96px emergency guard covers a full 92px facing reversal plus a physics step;
## the remaining 160px normally gives about 0.95s to drain bounded preparation work.
## The wider retention boundary gives another 1.52s of reversal tolerance. These are visual
## scheduling distances, not gameplay reach. Native acceptance measures every entered batch.
const LOAD_MARGIN := 256.0
const RETAIN_MARGIN := 512.0
const GUARD_MARGIN := 96.0
## Soft CPU preparation limit: finish the current job or ground quadrant, including its
## TileMap renderer preparation. GPU drawing and water redraw are separate; guards are synchronous.
const BUDGET_USEC := 2000
var city: City
var view := Rect2()
var _items: Array[Node2D] = []
var worst_update_usec := 0
var ordinary_guard_preparations := 0
var _pending := false
var _ground_step_frame := -1

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
		var next := camera_view()
		# The guard remains at least 80px ahead between these 16px maintenance steps.
		if _pending or next.size != view.size \
				or next.get_center().distance_to(view.get_center()) >= 16.0:
			update(next)

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
	# Keep unfinished allocations through the wider retention ring too. They pause outside
	# the load boundary, so reversing there resumes the same work without allocation churn.
	for key: Vector2i in ground.pending.keys():
		if not retained.intersects(SceneryGround.bounds(key)):
			ground.cancel(key)
	var pending: Array[Dictionary] = []
	for key in ground.keys_in(load_view):
		if ground.chunks.has(key):
			continue
		var bounds := SceneryGround.bounds(key)
		if guard.intersects(bounds):
			if not immediate and not relocated:
				ordinary_guard_preparations += 1
			ground.prepare(key)
		else:
			pending.append({"distance": bounds.get_center().distance_squared_to(view.get_center()),
					"ground_key": key})
	for item in _items.duplicate():
		if not is_instance_valid(item) or item.is_queued_for_deletion():
			_items.erase(item)
			continue
		var bounds: Rect2 = item.scenery_bounds()
		if item.scenery_resident:
			if not retained.intersects(bounds):
				item.set_scenery_resident(false)
		elif guard.intersects(bounds):
			if not immediate and not relocated:
				ordinary_guard_preparations += 1
			item.set_scenery_resident(true)
		elif load_view.intersects(bounds):
			pending.append({"distance": bounds.get_center().distance_squared_to(view.get_center()),
					"prepare": item.set_scenery_resident.bind(true)})
	var enqueue := func(bounds: Rect2, prepare: Callable) -> void:
		if guard.intersects(bounds):
			if not immediate and not relocated:
				ordinary_guard_preparations += 1
			prepare.call()
		else:
			pending.append({"distance": bounds.get_center().distance_squared_to(view.get_center()),
					"prepare": prepare})
	city._building_shadows.update_view(load_view, retained, enqueue)
	city._decals.update_view(load_view, retained, enqueue)
	pending.sort_custom(func(a: Dictionary, b: Dictionary): return a.distance < b.distance)
	_pending = false
	for job in pending:
		if Time.get_ticks_usec() - started >= BUDGET_USEC:
			_pending = true
			break
		if job.has("ground_key"):
			# A frame may contain several explicit updates as camera/game state changes. Never
			# turn those into several off-screen renderer batches in the same frame.
			var frame := Engine.get_process_frames()
			if _ground_step_frame == frame:
				_pending = true
				continue
			_ground_step_frame = frame
			if not ground.prepare_step(job.ground_key):
				_pending = true
		else:
			(job.prepare as Callable).call()
	worst_update_usec = maxi(worst_update_usec, Time.get_ticks_usec() - started)
