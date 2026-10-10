class_name DebugLayers
extends Node2D
## Three world-space overlays over the live game state — fields, shadows and bounding boxes — each
## toggleable by its own number key. See docs/TODO.md, M104, "the debug view".
##
## **Drawn from queries of the live objects, never a change to their own drawing.** The excitement
## halo already has this shape — a duplicate drawing over the source, see `ExcitementHalo` and
## `EntityHalo` — and this node goes the other way: outlines rather than glows, geometry rather
## than a picture. `EventInstance`, `CrowdAgent`, `Building`, `Prop` and `Stroller` are read, never
## written, and the handful of private fields this needed (a flock's own bird offsets, a car's
## travel axis, a jolt's own radii, `City`'s building and prop lists) each got the smallest
## read-only getter rather than a second copy of the geometry kept here.
##
## **The bounding-box layer is the one exception, and reads the physics tree itself instead of a
## query.** `collision_nodes_under()` walks every *enabled* `CollisionShape2D`/`CollisionPolygon2D`
## under a `StaticBody2D` or `CharacterBody2D` anywhere in `_world`'s or `_player`'s own subtree —
## hers, the pram's, every building, a road closure's and the map
## boundary's own barrier bodies, every solid event's obstruction (a checkpoint hut or gate, a
## region wall, a barricade), and in the escape's building every wall blocker and the fire on the
## stairs — so a body a future row grows needs nothing added here to be drawn,
## and this layer cannot disagree with what she actually collides against. `_draw_bodies()` and
## `body_outline_count()` both read this one list, and `tests/test_debug_layers.gd` counts the same
## tree independently to check the two never drift apart.
##
## **One node, three booleans, not three nodes.** Godot skips `_draw()` on an invisible `CanvasItem`
## entirely, so a plain `visible` flag per section already buys "no work happens while a layer is
## off" without a second node per layer to manage — `main.gd` owns the fourth layer (the developer
## readout) on its own pre-existing `CanvasLayer`, which is not a `CanvasItem` this class could
## parent anyway.
##
## **Every field is the real level set**, not a circle standing in for it —
## `GroundShape.field_outline()` and `field_outline_at()`, the same effective-distance arithmetic
## `Tuning.falloff()` prices, so this layer cannot disagree with what the meter does: a capsule
## about a stationary body's own spine, an ellipse (the emitter at one focus) about a moving one.
## **And cut where a wall stops it**: an outline is drawn only where the emitter's own walls
## (`EventInstance.wall_grid()`, `CrowdAgent.wall_grid()`) let its field reach, so behind a
## building, where the meter receives nothing, there is no line either. `_draw_fields()` is where the
## shape-per-emitter decision is made, and `open_runs()` where the cut is.
##
## **The building shows what the city shows.** Nothing here needs a day: the events are an event
## source (anything answering `instances() -> Array[EventInstance]`, which `InteriorEvents` does as
## well as `EventManager`), the crowd may be null, and the world is any `Node2D` whose subtree holds
## the bodies — `City` or `InteriorScene`. Only the props are a city's, and a building has none.

## The falloff's own outline colour for a merely costly field — `Palette.MARK_COSTLY`, the same
## amber the caret already uses for "worth going round", so this view speaks the vocabulary the
## game already has rather than inventing a third pair of danger colours.
const FIELD_COSTLY := Palette.MARK_COSTLY
## And the same deep red `Palette.MARK_LETHAL` for a `hard_fail` event's field and a car's strike
## box — "lethal != noise ... lethal is when you get hit by a car" (the player, 2026-09-10): a
## car's ordinary noise field is never this colour, only the box that can end the day.
const FIELD_LETHAL := Palette.MARK_LETHAL
## Debug-only: neither colour is used anywhere else, so a shadow outline cannot be mistaken for a
## danger cue.
const SHADOW_COLOUR := Color(0.32, 0.78, 0.95, 0.85)
const BODY_COLOUR := Color(0.55, 1.0, 0.55, 0.9)

const LINE_WIDTH := 1.5
const _CIRCLE_SEGMENTS := 40

var fields_on := false
var shadows_on := false
var bodies_on := false

## Set by `set_layer()` and `apply_initial_state()` on every change, cleared by `_process()` once
## it has queued the redraw the change owed. See `_wants_a_redraw()`.
var _redraw_owed := false

## The event source — see the class doc.
var _events: Node
## Null where there is no crowd: the escape's building.
var _crowd: Crowd
## Whose subtree the bodies are walked from: the `City`, or the escape's `InteriorScene`.
var _world: Node2D
var _player: Stroller

## **Called again when the escape walks out of the service door**, with the city in place of the
## building, so the one node and the state of its three switches carry across the section change.
func setup(events: Node, crowd: Crowd, world: Node2D, player: Stroller) -> void:
	_events = events
	_crowd = crowd
	_world = world
	_player = player

## The live instances, typed — see `DangerEdge._live()` for why the duck-typed source is read
## through one function.
func _live() -> Array[EventInstance]:
	return _events.instances()

## The crowd's agents, or none where there is no crowd.
func _agents() -> Array[CrowdAgent]:
	if not _crowd:
		return []
	return _crowd.agents()

## Sets which layers start on — `1` fields, `2` shadows, `3` bounding boxes — from
## `DevFlags.layers_override()`. Pulled out from `main._add_debug_layers()` so a test can drive it
## directly without a real command line to read: see `DevFlags.parse_layers()` for the same split.
func apply_initial_state(indices: Array[int]) -> void:
	fields_on = 1 in indices
	shadows_on = 2 in indices
	bodies_on = 3 in indices
	_redraw_owed = true

## `1` fields, `2` shadows, `3` bounding boxes — a number key's own numbering once `main.gd`
## wires one to each; `4` (the readout) lives on its own pre-existing layer and never reaches here.
func set_layer(index: int, on: bool) -> void:
	match index:
		1: fields_on = on
		2: shadows_on = on
		3: bodies_on = on
	_redraw_owed = true

func layer_on(index: int) -> bool:
	match index:
		1: return fields_on
		2: return shadows_on
		3: return bodies_on
		_: return false

## Gated on a layer actually being on, or a redraw still owed: with all three off and nothing
## owed, asking for one anyway would cost a queued `_draw()` call sixty times a second for a view
## that never turns anything on. But `_draw()` is retained — it re-runs only on `queue_redraw()`
## — so it keeps its last picture until something asks again, and the toggle that turns the last
## layer off is exactly the change nothing was asking a redraw for any more. `set_layer()` and
## `apply_initial_state()` mark `_redraw_owed` on every change, so the switch-off queues the one
## `_draw()` that draws nothing and the picture goes back to matching the booleans; see
## docs/DECISIONS.md, M142, "a layer turned off is drawn off".
func _process(_delta: float) -> void:
	if _wants_a_redraw():
		queue_redraw()
		_redraw_owed = false

## Pulled out of `_process()` so a test can hold the gate without a viewport to actually ask
## `queue_redraw()`/`_draw()` about. True while any layer is on, or while a redraw from the last
## change to one is still owed — see `_process()`.
func _wants_a_redraw() -> bool:
	return fields_on or shadows_on or bodies_on or _redraw_owed

func _draw() -> void:
	if not _events or not _player:
		return
	if fields_on:
		_draw_fields()
	if shadows_on:
		_draw_shadows()
	if bodies_on:
		_draw_bodies()

# ------------------------------------------------------------------ fields ---

## Every emitter's actual falloff boundary — `GroundShape.field_outline()`, the same effective-
## distance arithmetic `Tuning.falloff()` prices, so this layer cannot disagree with what the
## meter does: a capsule about a stationary body's own spine, an ellipse (focus at the emitter)
## about a moving one, and a plain circle at zero speed, exactly as it always drew — a mast's field
## included, now that it stands somewhere. A flock draws one pair per bird, at its own position and
## its own `heading * speed`, and `flock_outer_radius()` rather than `outer_radius` — the same
## radius `_flock_contribution_at()` sums over, so drawing the flat number instead would show a
## field wider than what the birds actually emit. Each outline is cut wherever the emitter's own
## walls keep the field from that point — see `open_runs()`.
func _draw_fields() -> void:
	for drawn in field_runs(_view_rect()):
		for run: PackedVector2Array in drawn[0]:
			draw_polyline(run, drawn[1], LINE_WIDTH, true)

## What `_draw_fields()` draws, as `[runs, colour]` per outline, for every outline that meets `view`
## — pulled out of the draw so a test can ask it, and time it, with no viewport to draw into.
func field_runs(view: Rect2) -> Array:
	var drawn: Array = []
	var cuts := {}
	_cut_calls += 1
	for instance in _live():
		if instance.is_finished:
			continue
		var colour := FIELD_LETHAL if instance.def.hard_fail else FIELD_COSTLY
		var source := instance.global_position
		var grid := instance.wall_grid()
		var id := instance.get_instance_id()
		var offsets := instance.flock_offsets()
		if offsets.is_empty():
			var axis := instance.solid_axis()
			var velocity := instance.travel_velocity()
			var shape := instance.def.shape
			var spine := shape.half_length if shape != null else 0.0
			for level: float in [instance.def.inner_radius, instance.def.outer_radius]:
				if not _may_be_seen(view, source, level, spine):
					continue
				var outline := shape.field_outline(source, axis, velocity, level) if shape != null \
						else GroundShape.field_outline_at(source, velocity, level)
				_field_boundary(outline, source, grid, colour, [id, -1, level], view, cuts, drawn)
			continue
		var outer := instance.flock_outer_radius()
		var velocities := instance.flock_velocities()
		# Every bird's outline is cut by the flock's own line, from its centre, which is the line
		# `contribution_at()` asks for the whole flock.
		for i in offsets.size():
			var at := source + offsets[i]
			for level: float in [instance.def.inner_radius, outer]:
				if not _may_be_seen(view, at, level):
					continue
				var outline := GroundShape.field_outline_at(at, velocities[i], level)
				_field_boundary(outline, source, grid, colour, [id, i, level], view, cuts, drawn)
	for agent in _agents():
		var is_car := agent.kind == CrowdAgent.Kind.CAR
		var inner := Tuning.CAR_INNER_RADIUS if is_car else Tuning.PEDESTRIAN_INNER_RADIUS
		var outer := Tuning.CAR_OUTER_RADIUS if is_car else Tuning.PEDESTRIAN_OUTER_RADIUS
		# Noise, never lethal — a car's strike box is drawn in the bounding-box layer instead, in
		# the same lethal colour, because being hit is a body question and this is a field one. A
		# crowd body is always a point in field terms (see `CrowdAgent.contribution_at()`'s own
		# doc), so it is outlined as a point whatever the agent's own shadow shape says.
		var velocity := agent.velocity()
		var levels: Array[float] = [inner, outer]
		if agent.is_startled():
			var jolt := agent.jolt_radii()
			levels.append(jolt.x)
			levels.append(jolt.y)
		var source := agent.global_position
		var grid := agent.wall_grid()
		var id := agent.get_instance_id()
		for level in levels:
			if not _may_be_seen(view, source, level):
				continue
			var outline := GroundShape.field_outline_at(source, velocity, level)
			_field_boundary(outline, source, grid, FIELD_COSTLY, [id, -1, level], view, cuts,
					drawn)
	_cuts = cuts
	return drawn

## The cut outlines of the last frame, by `[emitter id, bird or -1, level]`: `[outline, runs]`.
## **An outline the same as last frame's is cut the same way**, so a standing source — most events
## — asks its walls once rather than every frame; anything that moved is asked again. Rebuilt every
## frame from the outlines drawn, so nothing gone or off screen stays in it, and every outline is
## asked again once every `_CUT_REFRESH_FRAMES` frames, so a change to the ground under a standing
## source (a task scene's stretch coming on) is drawn within a second — each on a frame of its own,
## chosen by its key, so a screen's worth of fresh cuts never lands on one frame.
var _cuts := {}
var _cut_calls := 0
const _CUT_REFRESH_FRAMES := 60

## The world the camera shows, so an outline nobody can see costs nothing: the wall questions
## behind a cut are the expensive part of this layer, and most of a day's emitters are off screen.
func _view_rect() -> Rect2:
	return get_canvas_transform().affine_inverse() * get_viewport_rect()

## Whether a field level about `at` can reach into `view`, asked before its outline is built: no
## outline reaches further from its emitter than `level / (1 - Tuning.FIELD_ECCENTRICITY_MAX)`,
## the bound `CrowdAgent.contribution_at()` culls by, past the end of a body's own `spine`.
static func _may_be_seen(view: Rect2, at: Vector2, level: float, spine := 0.0) -> bool:
	return view.grow(level / (1.0 - Tuning.FIELD_ECCENTRICITY_MAX) + spine).has_point(at)

## One level of one field's boundary — an outline from `GroundShape.field_outline()` or its
## plain-point form `field_outline_at()` (a crowd agent or one bird of a flock, neither of which
## owns a body in field terms) — added to `drawn` as the runs `open_runs()` leaves, and not at all
## off screen. See `_cuts` for `key` and `cuts`.
func _field_boundary(outline: PackedVector2Array, source: Vector2, grid: CityMap, colour: Color,
		key: Array, view: Rect2, cuts: Dictionary, drawn: Array) -> void:
	if outline.is_empty() or not view.intersects(_bounds_of(outline)):
		return
	var runs: Array[PackedVector2Array] = []
	var cached: Array = _cuts.get(key, [])
	var refresh := posmod(_cut_calls + key.hash(), _CUT_REFRESH_FRAMES) == 0
	if not refresh and not cached.is_empty() and cached[0] == outline:
		runs = cached[1]
	else:
		runs = open_runs(outline, source, grid)
	cuts[key] = [outline, runs]
	drawn.append([runs, colour])

static func _bounds_of(points: PackedVector2Array) -> Rect2:
	var rect := Rect2(points[0], Vector2.ZERO)
	for point in points:
		rect = rect.expand(point)
	return rect

## The longest stretch of outline asked as one: once a wall is possible every edge is cut into
## pieces no longer than this before any line is asked, so a wall is never missed for falling
## between two corners of the outline — the widest rows' outlines have edges of a hundred pixels and
## more. A walled or open stretch shorter than one piece, between two of the other kind, is the one
## thing this cannot see.
const CUT_PIECE := 8.0
## How many halvings `_where_the_wall_starts()` takes over one piece: four leave the cut within half a
## pixel of where the wall's answer turns.
const _CUT_STEPS := 4

## A closed outline as the open polylines left once every stretch of it a wall keeps the field from
## is cut away: walled where `grid.wall_between()` blocks the line from `source`, the emitter's own
## node, to the point — the line `contribution_at()` asks, of the grid the emitter asks it of
## (`EventInstance.wall_grid()`, `CrowdAgent.wall_grid()`). With nothing walled it is the whole
## loop, closed; with everything walled it is nothing; with no grid nothing is walled. The outline
## is asked piece by piece (`CUT_PIECE`), and **where a piece runs from open to walled, the cut is
## where the answer turns along it**, found by halving it, so the line ends at the wall's depth
## rather than at whichever point of the outline happened to fall short of it.
##
## **Most outlines ask no line at all**: `_deep_ground_meets()` answers first whether anything
## within the outline's bounds could be deep enough in a building to wall one, and a walker on a
## sidewalk beside a facade almost never reaches that far in.
static func open_runs(points: PackedVector2Array, source: Vector2, grid: CityMap
		) -> Array[PackedVector2Array]:
	var runs: Array[PackedVector2Array] = []
	if points.size() < 2:
		return runs
	var shut: Array[bool] = []
	var first_shut := -1
	var pieces := PackedVector2Array()
	if grid != null and _deep_ground_meets(grid, _bounds_of(points).expand(source)):
		pieces = _in_pieces(points)
		for i in pieces.size():
			var is_shut := grid.wall_between(source, pieces[i])
			shut.append(is_shut)
			if is_shut and first_shut < 0:
				first_shut = i
	if first_shut < 0:
		var closed := points.duplicate()
		closed.append(points[0])
		runs.append(closed)
		return runs
	# Starting from a walled point, every open stretch begins and ends inside the one pass.
	var count := pieces.size()
	var run := PackedVector2Array()
	for k in count:
		var i := (first_shut + k) % count
		var j := (i + 1) % count
		if shut[i] and shut[j]:
			continue
		if shut[i]:
			run = PackedVector2Array([
					_where_the_wall_starts(pieces[j], pieces[i], source, grid), pieces[j]])
		elif shut[j]:
			run.append(_where_the_wall_starts(pieces[i], pieces[j], source, grid))
			runs.append(run)
			run = PackedVector2Array()
		else:
			run.append(pieces[j])
	return runs

## The closed outline with every edge cut into equal pieces no longer than `CUT_PIECE`: its own
## corners and the points between, in order, the last piece ending back at the first corner.
static func _in_pieces(points: PackedVector2Array) -> PackedVector2Array:
	var pieces := PackedVector2Array()
	var count := points.size()
	for i in count:
		var from := points[i]
		var to := points[(i + 1) % count]
		var parts := maxi(1, ceili(from.distance_to(to) / CUT_PIECE))
		for k in parts:
			pieces.append(from.lerp(to, float(k) / float(parts)))
	return pieces

## The last point from `open` towards `shut`, one piece apart, whose line from `source` the grid
## leaves open.
static func _where_the_wall_starts(open: Vector2, shut: Vector2, source: Vector2, grid: CityMap
		) -> Vector2:
	for _i in _CUT_STEPS:
		var middle := (open + shut) * 0.5
		if grid.wall_between(source, middle):
			shut = middle
		else:
			open = middle
	return open

## Whether any point of `rect` lies in a building tile at least `Tuning.THIN_WALL_SHIELD_DEPTH` in
## from each of its open sides — a superset of the ground deep enough for `CityMap.wall_between()`
## to block at, since no tile asks less than that depth and the corner discs it also leaves out only
## take more away. A line from the source to the outline lies inside the outline's bounds with the
## source added, so where this is false no line on it can be walled and none need be asked.
static func _deep_ground_meets(grid: CityMap, rect: Rect2) -> bool:
	var size := float(Tuning.TILE_SIZE)
	var depth := minf(Tuning.THIN_WALL_SHIELD_DEPTH, Tuning.WALL_SHIELD_DEPTH)
	var first := grid.world_to_tile(rect.position)
	var last := grid.world_to_tile(rect.end)
	for y in range(first.y, last.y + 1):
		for x in range(first.x, last.x + 1):
			var tile := Vector2i(x, y)
			if grid.is_walkable(tile):
				continue
			var low := Vector2(tile) * size
			var high := low + Vector2(size, size)
			if grid.is_walkable(Vector2i(x - 1, y)):
				low.x += depth
			if grid.is_walkable(Vector2i(x + 1, y)):
				high.x -= depth
			if grid.is_walkable(Vector2i(x, y - 1)):
				low.y += depth
			if grid.is_walkable(Vector2i(x, y + 1)):
				high.y -= depth
			if low.x <= high.x and low.y <= high.y \
					and low.x <= rect.end.x and rect.position.x <= high.x \
					and low.y <= rect.end.y and rect.position.y <= high.y:
				return true
	return false

# ----------------------------------------------------------------- shadows ---

## The ground extent every `GroundShape` shadow is drawn over today — events, crowd agents, props,
## her and the pram. **Buildings draw no shadow** (`Building.shape`'s own doc: "Buildings draw no
## shadow, so this is read for its body alone today"), so none is drawn here for one either; its
## `shape` still appears in the bounding-box layer below.
func _draw_shadows() -> void:
	for instance in _live():
		if instance.is_finished:
			continue
		_draw_shadow_outline(instance.def.shape, instance.global_position, instance.solid_axis())
	for agent in _agents():
		var axis := agent.travel_axis() if agent.kind == CrowdAgent.Kind.CAR else Vector2.RIGHT
		_draw_shadow_outline(agent.shape, agent.global_position, axis)
	var props: Array = (_world as City).props() if _world is City else []
	for prop in props:
		if prop is Prop:
			_draw_shadow_outline((prop as Prop).shape, prop.global_position, Vector2.RIGHT)
	_draw_shadow_outline(_player.shape, _player.global_position, Vector2.RIGHT)
	# In the escape she carries the baby and there is no pram, so no pram shadow is drawn
	# (`Stroller._draw()`) and none is outlined here either.
	if not _player.carrying:
		_draw_shadow_outline(_player.pram_shape, _pram_position(), Vector2.RIGHT)

func _draw_shadow_outline(shape: GroundShape, at: Vector2, axis: Vector2) -> void:
	_draw_closed_polyline(shape.shadow_outline(at, axis), SHADOW_COLOUR)

## The visible pram's own offset, shared with its shadow, cue and field instead of reconstructed
## from facing here. Its collision body's separate position comes from the physics tree below.
func _pram_position() -> Vector2:
	return _player.global_position + _player.pram_draw_offset()

# ------------------------------------------------------------- bounding boxes ---

## Every enabled collision shape a body in the tree could touch, traced from the actual
## `CollisionShape2D`/`CollisionPolygon2D` nodes physics reads via `collision_nodes_under()` —
## hers, the pram's, every building, a road closure's and the map
## boundary's own barrier bodies, and every solid event's obstruction — plus a moving car's strike
## box, drawn in the field layer's own lethal colour because it is not a body
## (`CrowdAgent._car_shadow_shape()`'s own doc: "no body for a car") but is exactly what
## `will_be_lethal()` tests against. **Walkers and cars have no body; nothing is invented for
## them.**
func _draw_bodies() -> void:
	for node in collision_nodes_under(_world):
		_draw_collision_node(node)
	for node in collision_nodes_under(_player):
		_draw_collision_node(node)
	for agent in _strike_box_agents():
		_draw_closed_polyline(_rect_corners(agent.global_position, agent.heading(),
				Vector2(Tuning.CAR_STRIKE_HALF_LENGTH, Tuning.CAR_STRIKE_HALF_WIDTH)), FIELD_LETHAL)

## How many outlines `_draw_bodies()` draws right now — the same `collision_nodes_under()` lists it
## draws from, plus a fast car's own strike box. The seam `tests/test_debug_layers.gd` checks
## against an independent tree walk of its own, so a body this layer stops drawing is a number this
## count would also drop.
func body_outline_count() -> int:
	return collision_nodes_under(_world).size() + collision_nodes_under(_player).size() \
			+ _strike_box_agents().size()

func _strike_box_agents() -> Array[CrowdAgent]:
	var found: Array[CrowdAgent] = []
	for agent in _agents():
		if agent.kind == CrowdAgent.Kind.CAR and agent.speed() >= Tuning.CAR_STRIKE_MIN_SPEED:
			found.append(agent)
	return found

## Every enabled `CollisionShape2D` (with a shape) or `CollisionPolygon2D`, under a `StaticBody2D`
## or `CharacterBody2D`, anywhere in `root`'s own subtree — recursive rather than a per-kind list,
## so a new body needs nothing added here to be found. This is the one place that decides what
## counts as a body for the debug view; `_draw_bodies()` and `body_outline_count()` both read it,
## and `tests/test_debug_layers.gd` walks the same tree by hand as an independent check.
##
## A thin wrapper over `_collect_collision_nodes_into()`, which walks into one array the caller
## already owns rather than `append_array`-ing a fresh `Array[Node]` back up through every level of
## recursion — the whole tree under a `City` is buildings, props, event instances and crowd agents
## and all of their own children, so a level-deep tree paid for one allocation per level on top of
## the one this function itself returns; now it pays for exactly one.
static func collision_nodes_under(root: Node) -> Array[Node]:
	var found: Array[Node] = []
	_collect_collision_nodes_into(root, found)
	return found

static func _collect_collision_nodes_into(root: Node, into: Array[Node]) -> void:
	if root == null:
		return
	if root is StaticBody2D or root is CharacterBody2D:
		for child in root.get_children():
			if child is CollisionShape2D and not child.disabled and child.shape != null:
				into.append(child)
			elif child is CollisionPolygon2D and not child.disabled:
				into.append(child)
	for child in root.get_children():
		_collect_collision_nodes_into(child, into)

## Draws one collision node's own shape at its own `global_position` — never a second copy of its
## geometry, so this cannot disagree with what the node actually collides as.
func _draw_collision_node(node: Node) -> void:
	var at: Vector2 = (node as Node2D).global_position
	if node is CollisionPolygon2D:
		_draw_closed_polyline(_polygon_world_points(node), BODY_COLOUR)
		return
	var shape: Shape2D = (node as CollisionShape2D).shape
	if shape is CircleShape2D:
		draw_arc(at, shape.radius, 0.0, TAU, _CIRCLE_SEGMENTS, BODY_COLOUR, LINE_WIDTH, true)
	elif shape is RectangleShape2D:
		var axis := Vector2.RIGHT.rotated((node as Node2D).global_rotation)
		_draw_closed_polyline(_rect_corners(at, axis, shape.size * 0.5), BODY_COLOUR)
	elif shape is CapsuleShape2D:
		# Godot's capsule stands along local Y (`GroundShape.collision_shape()`'s own doc), so the
		# spine's world axis is the node's rotated +Y, not its +X.
		var axis := Vector2.UP.rotated((node as Node2D).global_rotation)
		var half_length := maxf(0.0, shape.height * 0.5 - shape.radius)
		_draw_closed_polyline(_capsule_outline(at, axis, half_length, shape.radius), BODY_COLOUR)

func _polygon_world_points(node: CollisionPolygon2D) -> PackedVector2Array:
	var points := PackedVector2Array()
	var xform := node.global_transform
	for point in node.polygon:
		points.append(xform * point)
	return points

# ------------------------------------------------------------------ geometry ---
# Unsquashed — a bounding body and a field are both stated in the plain 2D plane the physics and
# `Tuning.falloff()` already use; only a shadow (`GroundShape.shadow_outline()`) carries the
# oblique view's own foreshortening.

func _rect_corners(at: Vector2, axis: Vector2, half_extents: Vector2) -> PackedVector2Array:
	var along := axis.normalized()
	var across := Vector2(-along.y, along.x)
	var corners: Array[Vector2] = [
		Vector2(-half_extents.x, -half_extents.y), Vector2(half_extents.x, -half_extents.y),
		Vector2(half_extents.x, half_extents.y), Vector2(-half_extents.x, half_extents.y),
	]
	var points := PackedVector2Array()
	for corner in corners:
		points.append(at + along * corner.x + across * corner.y)
	return points

## A stadium: a half-turn of arc at each end of the spine, joined by the two straight sides the
## polyline draws between them on its own. Wound the same direction both halves, so the second
## cap's start meets the first cap's end and the loop closes on the *other* straight side too.
func _capsule_outline(at: Vector2, axis: Vector2, half_length: float, radius: float
		) -> PackedVector2Array:
	var along := axis.normalized()
	var base := along.angle()
	var lead := at + along * half_length
	var trail := at - along * half_length
	var segments := _CIRCLE_SEGMENTS / 2
	var points := PackedVector2Array()
	for i in segments + 1:
		var a := base - PI * 0.5 + PI * float(i) / float(segments)
		points.append(lead + Vector2(cos(a), sin(a)) * radius)
	for i in segments + 1:
		var a := base + PI * 0.5 + PI * float(i) / float(segments)
		points.append(trail + Vector2(cos(a), sin(a)) * radius)
	return points

func _draw_closed_polyline(points: PackedVector2Array, colour: Color) -> void:
	if points.size() < 2:
		return
	var closed := points.duplicate()
	closed.append(points[0])
	draw_polyline(closed, colour, LINE_WIDTH, true)
