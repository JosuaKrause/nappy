class_name SceneryResidency
extends Node
## Prepares camera-adjacent artwork while retaining the complete gameplay city. The inner
## guard is synchronous; ordinary offscreen preparation is bounded and nearest-first. A jump
## or a changed view prepares the destination before the renderer sees it.

## An eight-cell batch is 256px; at 168px/s it takes 1.52s to cross the load margin.
## The 96px emergency guard covers a full 92px facing reversal plus a physics step;
## the remaining 160px normally gives about 0.95s to drain bounded preparation work.
## The wider retention boundary gives another 1.52s of reversal tolerance. These are visual
## scheduling distances, not gameplay reach.
const LOAD_MARGIN := 256.0
const RETAIN_MARGIN := 512.0
const GUARD_MARGIN := 96.0
## Soft CPU preparation limit: finish the current job or ground quadrant, including its
## TileMap renderer preparation. GPU drawing and water redraw are separate; guards are synchronous.
## Each update runs at least one job, so the queue always advances, and whatever is left waits for
## the next frame's update under a budget of its own, and so on, never dumped whole into one frame.
## *(2026-10-03, the player, on keeping it for ground mode 1: "if we keep the 2ms budget then it
## also should apply to the next frame and so on".)*
const BUDGET_USEC := 2000
## BUDGET_USEC, lowered by a test to make the per-frame spill-over countable.
var budget_usec := BUDGET_USEC
var city: City
var view := Rect2()
var _items: Array[Node2D] = []
var worst_update_usec := 0
var ordinary_guard_preparations := 0
var _pending := false
var _ground_step_frame := -1
## Keep the frame fence outside jobs: cancellation must not allow a second step for that key.
var _ground_stepped: Dictionary = {}
## The process frame that last prepared a whole ground region here, guard included: ONE's
## at-most-one-a-frame fence.
var _whole_region_frame := -1

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
	# The frame record's `scenery` (`FrameRecord`): the whole update, guard preparations included,
	# with the jobs it ran counted by kind and what it spent past `budget_usec` kept apart.
	var recording := FrameRecord.on
	var outer := FrameRecord.enter(FrameRecord.SCENERY) if recording else 0
	immediate = immediate or city.map.recipe_frame_locked
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
			if recording:
				FrameRecord.scenery_job(FrameLedger.GUARD_PREPARATIONS)
			ground.prepare(key)
			_whole_region_frame = Engine.get_process_frames()
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
			if recording:
				FrameRecord.scenery_job(FrameLedger.GUARD_PREPARATIONS)
			item.set_scenery_resident(true)
		elif load_view.intersects(bounds):
			pending.append({"distance": bounds.get_center().distance_squared_to(view.get_center()),
					"prepare": item.set_scenery_resident.bind(true),
					"kind": FrameLedger.JOBS_BUILDING if item is Building else FrameLedger.JOBS_PROP})
	var enqueue := func(bounds: Rect2, prepare: Callable, kind: int) -> void:
		if guard.intersects(bounds):
			if not immediate and not relocated:
				ordinary_guard_preparations += 1
			if recording:
				FrameRecord.scenery_job(FrameLedger.GUARD_PREPARATIONS)
			prepare.call()
		else:
			pending.append({"distance": bounds.get_center().distance_squared_to(view.get_center()),
					"prepare": prepare, "kind": kind})
	city._building_shadows.update_view(load_view, retained,
			enqueue.bind(FrameLedger.JOBS_SHADOW))
	city._decals.update_view(load_view, retained, enqueue.bind(FrameLedger.JOBS_DECAL))
	pending.sort_custom(func(a: Dictionary, b: Dictionary): return a.distance < b.distance)
	_pending = false
	# At least one job runs before the budget can stop the queue, in every mode and for every kind
	# of job, so the queue always advances. `started` is taken before the synchronous guard
	# preparations, so the frames where this adds a job beyond the budget are the ones the guard
	# (or this update's own bookkeeping) has already spent it in: the heaviest frames.
	var ran := 0
	for job in pending:
		if not city.map.recipe_frame_locked and ran > 0 \
				and Time.get_ticks_usec() - started >= budget_usec:
			_pending = true
			break
		if job.has("ground_key"):
			if city.map.recipe_frame_locked or ground.mode == SceneryGround.Mode.ALL:
				ground.prepare(job.ground_key)
				ran += 1
				if recording:
					FrameRecord.scenery_job(FrameLedger.JOBS_GROUND)
				continue
			var frame := Engine.get_process_frames()
			if ground.mode == SceneryGround.Mode.ONE:
				# The fence is per process frame, so repeating an explicit update cannot add a
				# second region; a guard preparation earlier in this frame has spent it too.
				if _whole_region_frame == frame:
					_pending = true
					continue
				_whole_region_frame = frame
				ground.prepare(job.ground_key)
				ran += 1
				if recording:
					FrameRecord.scenery_job(FrameLedger.JOBS_GROUND)
				continue
			# Several regions may approach together. Advance each once within the shared budget;
			# repeating an explicit update or replacing a canceled job cannot drain one region.
			if _ground_step_frame != frame:
				_ground_step_frame = frame
				_ground_stepped.clear()
			if _ground_stepped.has(job.ground_key):
				_pending = true
				continue
			_ground_stepped[job.ground_key] = true
			ran += 1
			if recording:
				FrameRecord.scenery_job(FrameLedger.JOBS_GROUND)
			if not ground.prepare_step(job.ground_key):
				_pending = true
		else:
			(job.prepare as Callable).call()
			ran += 1
			if recording:
				FrameRecord.scenery_job(job.kind)
	var elapsed := Time.get_ticks_usec() - started
	worst_update_usec = maxi(worst_update_usec, elapsed)
	if recording:
		FrameRecord.scenery_update(elapsed, budget_usec)
		FrameRecord.leave(outer)
