extends RefCounted
## The eight-sector heading selector (`EightDirection`) as the crowd car's own caller.
##
## `tests/test_walker_views.gd` already pins the selector's own boundary/hold behaviour and the
## walker's wiring; this suite pins the equivalent wiring for a car: which view and mirror each
## sector draws, that body and trim can never disagree, that a stopped car keeps its last view,
## that a fresh placement needs no reset call, and — the part a walker has no equivalent of — that
## the drawn picture's own ground contact agrees with the strike box at every sector, cardinal and
## diagonal alike, since a car's picture is bound to a rotating strike box a walker's point shape
## never has to agree with.

const EXPECTED_VIEW: Array[String] = [
	"side", "front_diagonal", "front", "front_diagonal", "side",
	"back_diagonal", "back", "back_diagonal",
]
const EXPECTED_MIRRORED: Array[bool] = [false, false, false, true, true, true, false, false]

func run(t) -> void:
	_test_car_view_by_sector_matches_the_walker_convention(t)
	_test_body_and_trim_can_never_disagree(t)
	_test_cardinal_headings_select_the_expected_view(t)
	_test_a_turn_sweeps_through_the_diagonal_views(t)
	_test_a_stopped_car_keeps_its_view(t)
	_test_a_fresh_heading_clears_the_previous_hold_in_one_step(t)
	_test_every_sector_picture_agrees_with_the_strike_box(t)
	_test_the_halo_redraws_the_same_body(t)
	_test_unpaired_car_views_still_fall_back_to_svg(t)

func _car(t) -> CrowdAgent:
	var agent := CrowdAgent.new()
	agent.kind = CrowdAgent.Kind.CAR
	return agent

## `CrowdAgent.CAR_VIEW_BY_SECTOR` is authored identically to `WALKER_VIEW_BY_SECTOR` — the same
## five projections, the same west-mirror convention — and this is what stops the two silently
## drifting apart if one is ever hand-edited without the other.
func _test_car_view_by_sector_matches_the_walker_convention(t) -> void:
	for sector in range(8):
		t.check(CrowdAgent.CAR_VIEW_BY_SECTOR[sector] == EXPECTED_VIEW[sector],
				"sector %d draws the %s view" % [sector, EXPECTED_VIEW[sector]])
		t.check(EightDirection.is_mirrored(sector) == EXPECTED_MIRRORED[sector],
				"sector %d mirror matches the west-mirror convention" % sector)

## `_draw_body()` looks the view up once and indexes both dictionaries with it, but this pins the
## invariant structurally too: nothing can add a body without its trim, or the two could draw two
## different cars' worth of paint and glass.
func _test_body_and_trim_can_never_disagree(t) -> void:
	var body_views := CrowdAgent.CAR_BODY_BY_VIEW.keys()
	var trim_views := CrowdAgent.CAR_TRIM_BY_VIEW.keys()
	t.check(body_views.size() == trim_views.size() and body_views.size() == 5,
			"the car family has exactly five authored views, body and trim alike")
	for view in body_views:
		t.check(CrowdAgent.CAR_TRIM_BY_VIEW.has(view),
				"every body view %s has a matching trim view" % view)
		t.check(CrowdAgent.CAR_BODY_BY_VIEW[view] != null and CrowdAgent.CAR_TRIM_BY_VIEW[view] != null,
				"both textures for %s actually resolve" % view)
	for sector in range(8):
		t.check(body_views.has(CrowdAgent.CAR_VIEW_BY_SECTOR[sector]),
				"sector %d names a view the tables actually carry" % sector)

## The four cardinal/side sectors a car reaches without ever being on an arc: no `_turn` running,
## `_vertical`/`_direction` set the way `_choose_lane()` leaves them.
func _test_cardinal_headings_select_the_expected_view(t) -> void:
	var agent := _car(t)
	# [vertical, direction] per sector, cardinal ones only (0 E, 2 S, 4 W, 6 N) — the diagonals are
	# never a lane axis and are covered by the turn test below instead.
	var cardinal := {0: [false, 1.0], 2: [true, 1.0], 4: [false, -1.0], 6: [true, -1.0]}
	for sector in cardinal.keys():
		var state: Array = cardinal[sector]
		agent._vertical = state[0]
		agent._direction = state[1]
		agent._speed = 130.0
		agent._turn = null
		# Started from the opposite sector every time, so the assertion below never passes because
		# the previous iteration's hold happened to already agree.
		agent._car_view = (sector + 4) % 8
		var frame := agent._frame()
		t.check(frame == sector, "heading %d degrees selects sector %d (got %d)"
				% [sector * 45, sector, frame])
		t.check(agent._flipped() == EXPECTED_MIRRORED[sector],
				"sector %d mirror flag matches the west-mirror convention" % sector)
	agent.free()

## A synthetic `CarTurn` whose tangent is exactly `sector`'s own 45-degree-multiple centre, built
## directly from `CarTurn.heading_at()`'s formula (`start_angle`, `spin`) rather than by planning a
## real arc through a `CityMap` a focused view-selection rig has no business building. `travelled`
## stays zero throughout, so `heading_at(0)` is just `Vector2(-sin(start_angle), cos(start_angle))
## * spin` — solved once per diagonal sector below.
func _turn_facing(sector: int) -> CarTurn:
	var turn := CarTurn.new()
	turn.radius = 16.0
	turn.spin = 1.0
	# SE=1 -> -45deg, NE=7 -> -135deg (=225deg), SW=3 -> 45deg, NW=5 -> 135deg — each solved so
	# Vector2(-sin(start_angle), cos(start_angle)) lands exactly on that sector's own heading.
	var start_angle_by_sector := {1: -45.0, 3: 45.0, 5: 135.0, 7: -135.0}
	turn.start_angle = deg_to_rad(start_angle_by_sector[sector])
	turn.travelled = 0.0
	return turn

## **Mid-turn the sector runs through the diagonal** — the property a walker has nothing
## equivalent to, since a walker's lane is always cardinal and only its cross-lane steering ever
## goes diagonal. A car's own `heading()` reads `_turn.heading_at()` once `_turn_run_up <= 0.0`, so
## a car partway round an arc is exactly this state.
func _test_a_turn_sweeps_through_the_diagonal_views(t) -> void:
	var agent := _car(t)
	for sector in [1, 3, 5, 7]:
		agent._turn = _turn_facing(sector)
		agent._turn_run_up = 0.0
		agent._speed = Tuning.CAR_TURN_SPEED
		agent._car_view = (sector + 4) % 8
		var heading := agent.heading()
		t.check(is_equal_approx(rad_to_deg(heading.angle()) + 360.0 if heading.angle() < 0.0 \
				else rad_to_deg(heading.angle()), float(sector) * 45.0),
				"the synthetic turn's own tangent lands on sector %d's centre angle" % sector)
		var frame := agent._frame()
		t.check(frame == sector, "mid-turn heading selects diagonal sector %d (got %d)"
				% [sector, frame])
		t.check(CrowdAgent.CAR_VIEW_BY_SECTOR[frame] in ["front_diagonal", "back_diagonal"],
				"sector %d draws one of the two diagonal views" % sector)
	agent.free()

## A car braked to a full stop (a light, a gate, a give-way) has `_speed == 0.0`, so `velocity()`
## is the zero vector and `EightDirection.update()`'s own idle threshold holds whatever was drawn
## before rather than reading a facing out of a heading that no longer means one.
func _test_a_stopped_car_keeps_its_view(t) -> void:
	var agent := _car(t)
	agent._vertical = false
	agent._direction = 1.0
	agent._speed = 130.0
	agent._turn = null
	agent._car_view = 6  # start from the opposite sector so the frame below cannot pass by luck
	var moving_frame := agent._frame()
	t.check(moving_frame == 0, "driving east settles on the east view first")

	agent._speed = 0.0
	t.check(agent.velocity() == Vector2.ZERO, "a stopped car's own velocity is exactly zero")
	var stopped_frame := agent._frame()
	t.check(stopped_frame == moving_frame,
			"a stopped car keeps the view it was last drawn with (%d, still %d)"
			% [moving_frame, stopped_frame])
	agent.free()

## `setup()` and `_recycle()` both call `_choose_lane()`, which clears `_turn` and leaves the car
## exactly on a lane axis with a rolled speed — a sector centre 45 degrees clear of its neighbours,
## twice the hold's own reach — so no reset call into `_car_view` is needed for the same reason
## `_update_walker_view()`'s own doc gives for the walker: the ordinary update on the very next
## frame already replaces whatever was drawn before.
func _test_a_fresh_heading_clears_the_previous_hold_in_one_step(t) -> void:
	var agent := _car(t)
	agent._vertical = false
	agent._direction = 1.0
	agent._speed = 130.0
	agent._car_view = 0
	t.check(agent._frame() == 0, "settled on east before the placement")

	# A fresh `_choose_lane()` result: a new axis and direction, no turn running.
	agent._vertical = true
	agent._direction = -1.0
	t.check(agent._frame() == 6,
			"the new north heading already wins over the stale east view (got %d)" % agent._frame())
	agent.free()

## The pin the M110 footprint test made for the old two-view end/side family, generalised to all
## five authored views through every one of `EightDirection`'s eight sectors: the strike box
## (`Tuning.CAR_STRIKE_HALF_LENGTH`/`CAR_STRIKE_HALF_WIDTH`, centred on the node and rotated onto
## the heading) and the drawn picture's own footprint agree at every sector, not only the two the
## old family drew. Sampled the way `Sprites.draw_standing` itself builds the rect, rather than by
## rasterising a frame.
func _test_every_sector_picture_agrees_with_the_strike_box(t) -> void:
	var agent := _car(t)
	for sector in range(8):
		var view: String = CrowdAgent.CAR_VIEW_BY_SECTOR[sector]
		var anchor := agent._car_body_anchor(view)
		var extent: Vector2 = CrowdAgent.CAR_BODY_BY_VIEW[view].get_size()
		var drawn := Rect2(anchor - Vector2(extent.x * 0.5, extent.y), extent)
		if view == "side":
			# The along-track axis is screen-horizontal for a side view, already centred by
			# `Sprites.draw_standing`'s own width handling — nothing south of the node to check.
			t.check(anchor == Vector2.ZERO, "sector %d's side anchor is undisturbed" % sector)
			continue
		# The node always falls inside the drawn footprint rather than sitting at its own edge —
		# `Sprites.draw_standing` builds a rect that runs from `anchor.y - extent.y` to `anchor.y`.
		t.check(drawn.position.y < 0.0 and drawn.end.y > 0.0,
				"sector %d's node falls inside its own drawn footprint (%.1f, %.1f)"
				% [sector, drawn.position.y, drawn.end.y])
		if view in ["front", "back"]:
			t.check(is_equal_approx(anchor.y, Tuning.CAR_STRIKE_HALF_LENGTH),
					"sector %d's front/back anchor sits the strike box's own half-length south" % sector)
		else:
			# A diagonal heading's own strike-box corner, rotated onto the screen's south axis —
			# `(HALF_LENGTH * |heading.y| + HALF_WIDTH * |heading.x|)`, which is `(L+W)/sqrt(2)` at
			# exactly 45 degrees — plus the 2px the diagonal canvas leaves between its alpha content
			# and its own edge, the same margin `CAR_DIAGONAL_ANCHOR_Y`'s own doc states.
			var heading := Vector2.from_angle(deg_to_rad(sector * 45.0))
			var south_reach := Tuning.CAR_STRIKE_HALF_LENGTH * absf(heading.y) \
					+ Tuning.CAR_STRIKE_HALF_WIDTH * absf(heading.x)
			t.check(is_equal_approx(anchor.y, south_reach + 2.0),
					("sector %d's diagonal anchor sits the rotated strike box's own corner, plus the "
					+ "canvas's own alpha margin, south of the node (%.2f)") % [sector, anchor.y])
	agent.free()

## `EntityHalo` traces whichever silhouette `_draw_body()` currently draws, once per ring offset —
## `set_halo_strength()` builds it with that exact bound method, so per-view halo geometry follows
## the ordinary picture automatically rather than needing a second lookup of its own.
func _test_the_halo_redraws_the_same_body(t) -> void:
	var agent := _car(t)
	agent.set_halo_strength(1.0, Color.RED)
	t.check(agent._halo != null, "a positive strength builds the halo lazily")
	t.check(agent._halo._draw_body == agent._draw_body,
			"the halo redraws exactly this agent's own `_draw_body`, so a per-sector picture change "
			+ "is a per-sector halo change with nothing else to wire up")
	# Freed with the halo still attached rather than through `set_halo_strength(0.0, ...)`: with no
	# `_process()` frame ever run to raise `_alpha` off zero, `EntityHalo.is_faded_out()` would read
	# true immediately and queue the halo's own `free()` — which `agent.free()` a line later would
	# race, since it frees the still-attached child synchronously first.
	agent.free()

func _test_unpaired_car_views_still_fall_back_to_svg(t) -> void:
	var diagonal: Texture2D = CrowdAgent.CAR_BODY_BY_VIEW["front_diagonal"]
	TextureResolver.reset_for_tests(true)
	t.check(TextureResolver.resolve(diagonal) == diagonal,
			"explicit SVG mode keeps the authored car diagonal SVG")
	TextureResolver.reset_for_tests(false)
	t.check(TextureResolver.resolve(diagonal) == diagonal,
			"no PNG transfer exists yet, so default mode falls back to the same car SVG")
	TextureResolver.reset_for_tests(DevFlags.svg_requested())
