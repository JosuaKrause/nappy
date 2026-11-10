@warning_ignore_start("untyped_declaration", "unsafe_method_access")
extends RefCounted
## The eight-sector heading selector (`EightDirection`) and its walker caller (`CrowdAgent`).
##
## `tests/test_stroller.gd` already pins the selector's own boundary/hold behaviour through the
## rig that used to own it; this suite pins the same behaviour through the shared class directly,
## plus the walker-specific wiring: which sector a heading selects, that body and trim
## can never disagree about which view they are, that a stopped walker keeps its last facing, and
## that a fresh placement's own heading clears whatever was drawn before in one step.

## The speed of a clear heading handed to the selector directly: well above any idle threshold.
const SPEED := 90.0

## How far a sidestep asked of a walker moves its steering target (`CrowdAgent.step_aside()`), so
## a diagonal sector is a walker whose lane has a gap to close, the way a bump or a narrow pavement
## leaves it. Any distance does: the cross term is `LaneMover.STEER_SPEED` at either size.
const SIDESTEP := 8.0

## Every sector's `[lane heading, sidestep]`, `0` (east) to `7` (north-east): the cardinal sectors are a
## walker on a lane with nothing to steer across, the diagonals one of the two lanes that lead to it
## and the sidestep that opens the cross-lane gap.
const SECTOR_LANES: Array = [
	[Vector2.RIGHT, Vector2.ZERO],   # 0 E
	[Vector2.RIGHT, Vector2.DOWN],   # 1 SE
	[Vector2.DOWN, Vector2.ZERO],    # 2 S
	[Vector2.DOWN, Vector2.LEFT],    # 3 SW
	[Vector2.LEFT, Vector2.ZERO],    # 4 W
	[Vector2.LEFT, Vector2.UP],      # 5 NW
	[Vector2.UP, Vector2.ZERO],      # 6 N
	[Vector2.UP, Vector2.RIGHT],     # 7 NE
]

const ViewRig := preload("res://tests/view_rig.gd")

var _rig: ViewRig

func run(t) -> void:
	_rig = ViewRig.new(t)
	_test_selector_nearest_covers_all_eight(t)
	_test_selector_boundary_hold(t)
	_test_selector_wrap_boundary_holds(t)
	_test_selector_idle_threshold_retains(t)
	_test_walker_headings_select_the_expected_view(t)
	_test_body_and_trim_can_never_disagree(t)
	_test_a_stopped_walker_keeps_its_view(t)
	_test_a_fresh_heading_clears_the_previous_hold_in_one_step(t)
	_test_advancing_the_gait_tracks_distance_not_time(t)
	_test_a_moving_walker_alternates_gait_frames(t)
	_test_a_stopped_walker_holds_gait_frame_a(t)
	_test_walker_gait_b_tables_agree_with_a(t)
	_test_walker_gait_b_tables_cover_every_sector(t)
	_rig.free_city()

# ------------------------------------------------------------------- selector ---

func _test_selector_nearest_covers_all_eight(t) -> void:
	for sector in range(8):
		var heading := Vector2.from_angle(deg_to_rad(sector * 45.0))
		t.check(EightDirection.nearest(heading) == sector,
				"heading at %d degrees is nearest sector %d" % [sector * 45, sector])

func _test_selector_boundary_hold(t) -> void:
	var current := EightDirection.nearest(Vector2.from_angle(deg_to_rad(0.0)))
	current = EightDirection.update(current, Vector2.from_angle(deg_to_rad(26.0)))
	t.check(current == 0, "five degree hold keeps east just past the 22.5 degree boundary")
	current = EightDirection.update(current, Vector2.from_angle(deg_to_rad(28.0)))
	t.check(current == 1, "east changes to southeast after the hysteresis margin")
	current = EightDirection.update(current, Vector2.from_angle(deg_to_rad(24.0)))
	t.check(current == 1, "southeast holds while turning back inside the margin")
	current = EightDirection.update(current, Vector2.from_angle(deg_to_rad(16.0)))
	t.check(current == 0, "southeast returns to east below the margin")

func _test_selector_wrap_boundary_holds(t) -> void:
	var current := EightDirection.update(2, Vector2.from_angle(deg_to_rad(330.0)))
	current = EightDirection.update(current, Vector2.from_angle(deg_to_rad(340.0)))
	t.check(current == 7, "north-east holds through the zero degree wrap")
	current = EightDirection.update(current, Vector2.from_angle(deg_to_rad(345.0)))
	t.check(current == 0, "east wins after crossing the wrapped boundary")

## The one behaviour `Stroller` never needed, since its own `facing` is never the zero vector:
## a heading at or below the idle threshold holds instead of being read as a facing at all.
func _test_selector_idle_threshold_retains(t) -> void:
	var current := EightDirection.update(6, Vector2.from_angle(deg_to_rad(90.0)) * SPEED, 5.0)
	t.check(current == 2, "a clear heading above the threshold still updates normally")
	current = EightDirection.update(current, Vector2(3.0, 0.0), 5.0)
	t.check(current == 2, "a heading at or under the idle threshold holds the current sector")
	current = EightDirection.update(current, Vector2.ZERO, 5.0)
	t.check(current == 2, "a exactly zero heading holds too")
	current = EightDirection.update(current, Vector2.ZERO)
	t.check(current == 2, "and so does the default zero threshold Stroller relies on")

# --------------------------------------------------------------------- walker ---

## A walker the game placed on a lane running along `heading` (`CrowdAgent.setup()`), at the pace
## that placement rolled.
func _walker(t, heading: Vector2) -> CrowdAgent:
	var agent := _rig.place(CrowdAgent.Kind.WALKER, heading)
	t.check(agent != null, "a walker is placed heading %s" % heading)
	return agent

## A walker facing `sector`: placed on the lane of `SECTOR_LANES`, and for a diagonal sidestepped
## (`CrowdAgent.step_aside()`) so its steering target is a lane over and its heading swings onto the
## diagonal, as it does for a walker nudged aside by the player. Null when there is no such
## placement; that the walker then draws that sector is what the callers read off its look.
func _walker_facing(t, sector: int) -> CrowdAgent:
	var lane: Array = SECTOR_LANES[sector]
	var agent := _walker(t, lane[0])
	if agent == null:
		return null
	if lane[1] != Vector2.ZERO:
		agent.step_aside(lane[1], SIDESTEP, 1.0)
	return agent

func _test_walker_headings_select_the_expected_view(t) -> void:
	for sector in range(8):
		var agent := _walker_facing(t, sector)
		if agent == null:
			continue
		var look := ViewRig.walker_look(agent)
		# Started from the opposite sector every time, so the assertion below is never passing
		# because the previous iteration's hold happened to already agree.
		look.view = (sector + 4) % 8
		var frame := look.sector()
		t.check(frame == sector,
				"heading %d degrees selects sector %d (got %d)" % [sector * 45, sector, frame])
		agent.free()

## `AgentLook.draw_body()` looks the view up once and indexes both dictionaries with it, but this pins the
## invariant structurally too: nothing can add a body without its trim, or the two would be able
## to draw two different walkers' worth of coat and hands. And it pins the tint split at the same
## time: body and trim have to be two distinct baked regions, or tinting the body (`AgentLook.draw_body()`'s
## own `colour` argument) would tint the trim drawn over it as well.
func _test_body_and_trim_can_never_disagree(t) -> void:
	var body_views := WalkerLook.BODY_BY_VIEW.keys()
	var trim_views := WalkerLook.TRIM_BY_VIEW.keys()
	t.check(body_views.size() == trim_views.size(), "the walker family has as many trim views as body views")
	for view in body_views:
		t.check(WalkerLook.TRIM_BY_VIEW.has(view),
				"every body view %s has a matching trim view" % view)
		var body_region := StringName(WalkerLook.BODY_BY_VIEW[view])
		var trim_region := StringName(WalkerLook.TRIM_BY_VIEW[view])
		t.check(AtlasTable.baked().has_region(body_region) and AtlasTable.baked().has_region(trim_region),
				"both regions for %s are actually baked" % view)
		t.check(body_region != trim_region,
				"body and trim for %s are two separate regions, so tinting one leaves the other" % view)
	for sector in range(8):
		t.check(body_views.has(WalkerLook.VIEW_BY_SECTOR[sector]),
				"sector %d names a view the tables actually carry" % sector)

## A give-way, a queue or a halt all reach the walker the same way: `WalkerStrategy._yield_factor()` zeroing
## `LaneMover.velocity()` while it has already arrived at its lane centre, which is exactly the "at rest"
## the look reads as no heading at all. A walker is told to wait the way the player's
## bump tells it (`CrowdAgent.step_aside()` along its own line of travel, away from where it is going).
func _test_a_stopped_walker_keeps_its_view(t) -> void:
	var agent := _walker(t, Vector2.RIGHT)
	if agent == null:
		return
	var look := ViewRig.walker_look(agent)
	look.view = 6  # start from the opposite sector so the frame below cannot pass by luck
	var moving_frame := look.sector()
	t.check(moving_frame == 0, "walking east settles on the east view first")

	# Stopped: no cross-lane gap, and the along term reads zero through the same yield the crowd
	# actually stops a walker with.
	_stop(agent)
	var stopped_frame := look.sector()
	t.check(stopped_frame == moving_frame,
			"a stopped walker keeps the view it was last drawn with (%d, still %d)"
			% [moving_frame, stopped_frame])
	agent.free()

## Tells `agent` to wait where it stands: asked to get out of the way of somebody ahead of it on its
## own line of travel, it waits rather than hurrying across (`WalkerStrategy.step_aside()`).
func _stop(agent: CrowdAgent) -> void:
	var behind := -agent.heading()
	agent.step_aside(behind, SIDESTEP, 1.0)

## `LaneMover.setup()` places a walker with no cross-lane steering yet running
## (`WalkerLook.sector()`'s own doc), so this pins the property through the real placement: a walker
## drawn as one sector, then placed again, shows the new lane's own heading on the very next frame,
## because that heading is exactly on a sector centre, 45 degrees clear of its neighbours — twice the
## hold's own 27.5 degree reach — the same "no prior-view hold" guarantee `Stroller.reset_at()`
## gives a new day.
func _test_a_fresh_heading_clears_the_previous_hold_in_one_step(t) -> void:
	var agent := _walker_facing(t, 1)  # south-east, the kind of diagonal only real steering ever produces
	if agent == null:
		return
	var look := ViewRig.walker_look(agent)
	look.view = 1
	t.check(look.sector() == 1, "settled on southeast before the placement")

	# A fresh placement: a new lane and direction, no detour or yield left running, sitting exactly
	# on its own lane centre. Placed again until it points north, an adjacent-ish sector to the
	# stale one above.
	var placed_north := false
	for seed_value in range(1, ViewRig.ROLLS):
		look.view = 1
		agent.setup(CrowdAgent.Kind.WALKER, _rig.city.map, _rig.city.crowd.field(), seed_value,
				0.5 * float(seed_value % 2))
		if agent.heading().is_equal_approx(Vector2.UP):
			placed_north = true
			break
	t.check(placed_north, "a walker is placed again heading north")
	t.check(look.sector() == 6,
			"the new north heading already wins over the stale southeast view (got %d)"
			% look.sector())
	agent.free()

# ---------------------------------------------------------------------- gait ---
# `WalkerLook.advance()`/`WalkerLook.gait_frame()`, the walker's own two-frame stride —
# `Stroller._walk_phase`/`_draw_mother()`'s pattern, extended to the crowd (M108, "every living
# thing that moves has a stride"). The stride phase is internal: it is reached by walking the look
# a distance (`advance()` adds `distance * GAIT_RATE`) and read as the frame drawn. The frame is
# feet passing on the two quarter-turns `(0, PI/2)` and `(PI, 3*PI/2)` of a full `TAU` cycle and the
# rest pose on the other two.

## Restarts the look and walks it the distance whose stride phase is `phase`, in one tick.
func _stride_to(look: WalkerLook, phase: float) -> void:
	look.restart()
	look.advance(Vector2.RIGHT * phase / WalkerLook.GAIT_RATE, 1.0)

## A placed walker has a nonzero `LaneMover.velocity()` — the same "moving by default" shape
## `_test_walker_headings_select_the_expected_view()` relies on. The stride is advanced with an
## injected `delta`: this checks the arithmetic of one tick, which the crowd's tick hands the look
## (`WalkerLook.advance()`).
func _test_advancing_the_gait_tracks_distance_not_time(t) -> void:
	var agent := _walker(t, Vector2.RIGHT)
	if agent == null:
		return
	var look := ViewRig.walker_look(agent)
	look.restart()
	look.advance(Vector2.RIGHT * (PI / 4.0) / WalkerLook.GAIT_RATE, 1.0)
	t.check(look.gait_frame() == 1, "a walker that covered ground has moved on in its stride")

	# The same ground in two ticks of different lengths is the same stride: distance, not time.
	var other := WalkerLook.new(agent)
	other.restart()
	var step := Vector2.RIGHT * (PI / 4.0) / WalkerLook.GAIT_RATE
	other.advance(step, 0.25)
	other.advance(step, 0.75)
	_stride_to(look, PI / 4.0)
	t.check(other.gait_frame() == look.gait_frame(),
			"the same ground in two ticks lands where one tick of it does")

	_stride_to(look, PI / 4.0)
	look.advance(Vector2.ZERO, 1.0)
	t.check(look.gait_frame() == 1,
			"a walker covering no distance advances no stride at all")
	agent.free()

func _test_a_moving_walker_alternates_gait_frames(t) -> void:
	var agent := _walker(t, Vector2.RIGHT)
	if agent == null:
		return
	var look := ViewRig.walker_look(agent)
	_stride_to(look, 0.0)
	t.check(look.gait_frame() == 0, "phase zero draws the rest pose")
	_stride_to(look, PI / 4.0)
	t.check(look.gait_frame() == 1, "a quarter into the cycle draws feet passing")
	_stride_to(look, 3.0 * PI / 4.0)
	t.check(look.gait_frame() == 0, "past the half turn it returns to the rest pose")
	_stride_to(look, 5.0 * PI / 4.0)
	t.check(look.gait_frame() == 1, "the second half of the cycle passes feet again")
	agent.free()

## The same give-way/queue/halt zeroing `_test_a_stopped_walker_keeps_its_view()` already reaches
## the view hold with also reaches the gait: `velocity()` is `heading() * _speed * WalkerStrategy._yield_factor()`,
## so a walker yielding reads zero regardless of the stride it was at.
func _test_a_stopped_walker_holds_gait_frame_a(t) -> void:
	var agent := _walker(t, Vector2.RIGHT)
	if agent == null:
		return
	var look := ViewRig.walker_look(agent)
	_stride_to(look, PI / 4.0)
	t.check(look.gait_frame() == 1, "moving, this phase draws frame b (sanity check)")
	_stop(agent)
	t.check(look.gait_frame() == 0,
			"a yielding walker holds frame a regardless of its own stride phase")
	agent.free()

## `AgentLook.draw_body()`'s walker branch picks `WalkerLook.BODY_BY_VIEW_B`/`TRIM_BY_VIEW_B` together off
## one `stepping` boolean, so the two tables have to carry exactly the same five views the ordinary
## frame-a tables do, the same invariant `_test_body_and_trim_can_never_disagree()` pins for frame a.
func _test_walker_gait_b_tables_agree_with_a(t) -> void:
	var body_views_b := WalkerLook.BODY_BY_VIEW_B.keys()
	var trim_views_b := WalkerLook.TRIM_BY_VIEW_B.keys()
	t.check(body_views_b.size() == WalkerLook.BODY_BY_VIEW.size()
			and trim_views_b.size() == WalkerLook.TRIM_BY_VIEW.size(),
			"the walker's gait-b family covers every view the gait-a family does")
	for view in WalkerLook.BODY_BY_VIEW.keys():
		t.check(WalkerLook.BODY_BY_VIEW_B.has(view),
				"view %s has a gait-b body to match its gait-a body" % view)
		t.check(WalkerLook.TRIM_BY_VIEW_B.has(view),
				"view %s has a gait-b trim to match its gait-a trim" % view)
		t.check(AtlasTable.baked().has_region(StringName(WalkerLook.BODY_BY_VIEW_B[view]))
				and AtlasTable.baked().has_region(StringName(WalkerLook.TRIM_BY_VIEW_B[view])),
				"both gait-b regions for %s are actually baked" % view)

func _test_walker_gait_b_tables_cover_every_sector(t) -> void:
	for sector in range(8):
		var view: String = WalkerLook.VIEW_BY_SECTOR[sector]
		t.check(WalkerLook.BODY_BY_VIEW_B.has(view) and WalkerLook.TRIM_BY_VIEW_B.has(view),
				"sector %d's view %s has a gait-b body and trim too" % [sector, view])
