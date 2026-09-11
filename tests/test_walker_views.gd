extends RefCounted
## The eight-sector heading selector (`EightDirection`) and its walker caller (`CrowdAgent`).
##
## `tests/test_stroller.gd` already pins the selector's own boundary/hold behaviour through the
## rig that used to own it; this suite pins the same behaviour through the shared class directly,
## plus the walker-specific wiring: which view and mirror each sector draws, that body and trim
## can never disagree about which view they are, that a stopped walker keeps its last facing, and
## that a fresh placement's own heading clears whatever was drawn before in one step.

## How fast the along and cross components below are set, chosen so a diagonal sector's two
## components are equal and its heading lands exactly on that sector's own 45°-multiple centre —
## `CrowdAgent.STEER_SPEED`, the rate the cross term actually runs at while steering.
const SPEED := 90.0

## One `[vertical, direction, lane_centre]` triple per sector, `0` (east) to `7` (north-east),
## that makes `CrowdAgent._walker_heading()` land exactly on that sector's own centre angle with
## the agent sitting at the world origin: `_lane_centre` alone opens the cross-lane gap
## (`_cross()` reads `position`, held at zero throughout), and `_speed`/`_vertical`/`_direction`
## supply the along-lane component `velocity()` reads.
const SECTOR_STATE: Array = [
	[false, 1.0, 0.0],     # 0 E
	[true, 1.0, SPEED],    # 1 SE
	[true, 1.0, 0.0],      # 2 S
	[true, 1.0, -SPEED],   # 3 SW
	[false, -1.0, 0.0],    # 4 W
	[true, -1.0, -SPEED],  # 5 NW
	[true, -1.0, 0.0],     # 6 N
	[true, -1.0, SPEED],   # 7 NE
]
const EXPECTED_VIEW: Array[String] = [
	"side", "front_diagonal", "front", "front_diagonal", "side",
	"back_diagonal", "back", "back_diagonal",
]
const EXPECTED_MIRRORED: Array[bool] = [false, false, false, true, true, true, false, false]

func run(t) -> void:
	_test_selector_nearest_covers_all_eight(t)
	_test_selector_boundary_hold(t)
	_test_selector_wrap_boundary_holds(t)
	_test_selector_idle_threshold_retains(t)
	_test_selector_mirrors(t)
	_test_walker_headings_select_the_expected_view(t)
	_test_body_and_trim_can_never_disagree(t)
	_test_a_stopped_walker_keeps_its_view(t)
	_test_a_fresh_heading_clears_the_previous_hold_in_one_step(t)
	_test_unpaired_walker_views_still_fall_back_to_svg(t)

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

func _test_selector_mirrors(t) -> void:
	for sector in range(8):
		t.check(EightDirection.is_mirrored(sector) == EXPECTED_MIRRORED[sector],
				"sector %d mirror matches the west-mirror convention" % sector)

# --------------------------------------------------------------------- walker ---

func _walker(t) -> CrowdAgent:
	var agent := CrowdAgent.new()
	agent.kind = CrowdAgent.Kind.WALKER
	return agent

## Sets the state `_walker_heading()` reads so it lands exactly on `sector`'s own centre angle —
## see `SECTOR_STATE`'s own doc.
func _face_sector(agent: CrowdAgent, sector: int) -> void:
	var state: Array = SECTOR_STATE[sector]
	agent.position = Vector2.ZERO
	agent._vertical = state[0]
	agent._direction = state[1]
	agent._speed = SPEED
	agent._lane_centre = state[2]
	agent._detour = 0.0
	agent._yield_left = 0.0

func _test_walker_headings_select_the_expected_view(t) -> void:
	var agent := _walker(t)
	for sector in range(8):
		_face_sector(agent, sector)
		# Started from the opposite sector every time, so the assertion below is never passing
		# because the previous iteration's hold happened to already agree.
		agent._walker_view = (sector + 4) % 8
		var frame := agent._frame()
		t.check(frame == sector,
				"heading %d degrees selects sector %d (got %d)" % [sector * 45, sector, frame])
		var view: String = CrowdAgent.WALKER_VIEW_BY_SECTOR[frame]
		t.check(view == EXPECTED_VIEW[sector],
				"sector %d draws the %s view" % [sector, EXPECTED_VIEW[sector]])
		t.check(agent._flipped() == EXPECTED_MIRRORED[sector],
				"sector %d mirror flag matches the west-mirror convention" % sector)
	agent.free()

## `_draw_body()` looks the view up once and indexes both dictionaries with it, but this pins the
## invariant structurally too: nothing can add a body without its trim, or the two would be able
## to draw two different walkers' worth of coat and hands.
func _test_body_and_trim_can_never_disagree(t) -> void:
	var body_views := CrowdAgent.WALKER_BODY_BY_VIEW.keys()
	var trim_views := CrowdAgent.WALKER_TRIM_BY_VIEW.keys()
	t.check(body_views.size() == trim_views.size() and body_views.size() == 5,
			"the walker family has exactly five authored views, body and trim alike")
	for view in body_views:
		t.check(CrowdAgent.WALKER_TRIM_BY_VIEW.has(view),
				"every body view %s has a matching trim view" % view)
		t.check(CrowdAgent.WALKER_BODY_BY_VIEW[view] != null
				and CrowdAgent.WALKER_TRIM_BY_VIEW[view] != null,
				"both textures for %s actually resolve" % view)
	for sector in range(8):
		t.check(body_views.has(CrowdAgent.WALKER_VIEW_BY_SECTOR[sector]),
				"sector %d names a view the tables actually carry" % sector)

## A give-way, a queue or a halt all reach the walker the same way: `_yield_factor()` zeroing
## `velocity()` while it has already arrived at its lane centre, which is exactly the "at rest"
## `_walker_heading()` returns `Vector2.ZERO` for.
func _test_a_stopped_walker_keeps_its_view(t) -> void:
	var agent := _walker(t)
	_face_sector(agent, 0)
	agent._walker_view = 6  # start from the opposite sector so the frame below cannot pass by luck
	var moving_frame := agent._frame()
	t.check(moving_frame == 0, "walking east settles on the east view first")

	# Stopped: no cross-lane gap, and the along term reads zero through the same yield the crowd
	# actually stops a walker with — not by lowering `_speed` itself, which nothing else does.
	agent._yield_left = 1.0
	agent._yield_hurry = false
	t.check(agent._walker_heading() == Vector2.ZERO, "a yielding walker's own heading is zero")
	var stopped_frame := agent._frame()
	t.check(stopped_frame == moving_frame,
			"a stopped walker keeps the view it was last drawn with (%d, still %d)"
			% [moving_frame, stopped_frame])
	agent.free()

## `setup()` and `_recycle()` are both owned by the concurrent lane-turning work on this file (see
## `_update_walker_view()`'s own doc), so this pins the property that stands in for a call into
## either of them: both leave a walker's own heading exactly on a sector centre, 45 degrees clear
## of its neighbours — twice the hold's own 27.5 degree reach — so whatever sector was drawn
## before a placement or a recycle is always replaced on the very next frame, the same "no
## prior-view hold" guarantee `Stroller.reset_at()` gives a new day.
func _test_a_fresh_heading_clears_the_previous_hold_in_one_step(t) -> void:
	var agent := _walker(t)
	_face_sector(agent, 1)  # south-east, the kind of diagonal only real steering ever produces
	agent._walker_view = 1
	t.check(agent._frame() == 1, "settled on southeast before the placement")

	# A fresh placement/recycle: a new lane and direction, no detour or yield left running, sitting
	# exactly on its own lane centre — `_choose_lane()` and `_set_cross(_lane_centre)`'s own result,
	# reproduced here directly since building the `CityMap`/`CrowdField` `_recycle()` needs is out
	# of scope for a focused view-selection rig.
	_face_sector(agent, 6)  # north, an adjacent-ish sector to the stale one above
	t.check(agent._frame() == 6,
			"the new north heading already wins over the stale southeast view (got %d)"
			% agent._frame())
	agent.free()

func _test_unpaired_walker_views_still_fall_back_to_svg(t) -> void:
	var diagonal: Texture2D = CrowdAgent.WALKER_BODY_BY_VIEW["front_diagonal"]
	TextureResolver.reset_for_tests(true)
	t.check(TextureResolver.resolve(diagonal) == diagonal,
			"explicit SVG mode keeps the authored walker diagonal SVG")
	TextureResolver.reset_for_tests(false)
	t.check(TextureResolver.resolve(diagonal) == diagonal,
			"no PNG transfer exists yet, so default mode falls back to the same walker SVG")
	TextureResolver.reset_for_tests(DevFlags.svg_requested())
