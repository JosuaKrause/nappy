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
	_test_the_registration_is_continuous_across_a_sector_boundary(t)
	_test_the_halo_redraws_the_same_body(t)
	_test_the_rim_is_re_traced_under_a_steady_glow(t)
	_test_the_rim_and_the_picture_share_one_footprint(t)
	_test_the_redraw_gate_carries_the_live_anchor(t)
	_test_wheels_share_the_body_canvas(t)
	_test_a_moving_car_bobs_and_a_stopped_car_sits_still(t)
	_test_the_bob_is_driven_by_ground_covered(t)
	_test_the_halo_rides_the_bob(t)
	_test_the_redraw_gate_follows_the_bob(t)

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
## different cars' worth of paint and glass. And it pins the tint split: body and trim have to be
## two distinct baked regions, or tinting the body (`_draw_body()`'s own `colour` argument) would
## tint the trim drawn over it as well.
func _test_body_and_trim_can_never_disagree(t) -> void:
	var body_views := CrowdAgent.CAR_BODY_BY_VIEW.keys()
	var trim_views := CrowdAgent.CAR_TRIM_BY_VIEW.keys()
	t.check(body_views.size() == trim_views.size() and body_views.size() == 5,
			"the car family has exactly five authored views, body and trim alike")
	for view in body_views:
		t.check(CrowdAgent.CAR_TRIM_BY_VIEW.has(view),
				"every body view %s has a matching trim view" % view)
		var body_region := StringName(CrowdAgent.CAR_BODY_BY_VIEW[view])
		var trim_region := StringName(CrowdAgent.CAR_TRIM_BY_VIEW[view])
		t.check(AtlasLibrary.has_region(body_region) and AtlasLibrary.has_region(trim_region),
				"both regions for %s are actually baked" % view)
		t.check(body_region != trim_region,
				"body and trim for %s are two separate regions, so tinting one leaves the other" % view)
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
##
## **One rule for all five views**, stated over the heading: the drawn content's bottom edge is the
## car's nearest ground contact and lands on the strike box's own southernmost point. The side view
## is in it on the same terms as the rest — an east-facing car's box reaches
## `CAR_STRIKE_HALF_WIDTH` south of the node and its picture's wheels belong there, not on the node.
func _test_every_sector_picture_agrees_with_the_strike_box(t) -> void:
	var agent := _car(t)
	for sector in range(8):
		var view: String = CrowdAgent.CAR_VIEW_BY_SECTOR[sector]
		var heading := Vector2.from_angle(deg_to_rad(sector * 45.0))
		var anchor := agent._car_body_anchor(view, heading)
		var extent := Vector2(AtlasLibrary.native_size(
				StringName(CrowdAgent.CAR_BODY_BY_VIEW[view])))
		var drawn := Rect2(anchor - Vector2(extent.x * 0.5, extent.y), extent)
		# The node always falls inside the drawn footprint rather than sitting at its own edge —
		# `Sprites.draw_standing` builds a rect that runs from `anchor.y - extent.y` to `anchor.y`.
		t.check(drawn.position.y < 0.0 and drawn.end.y > 0.0,
				"sector %d's node falls inside its own drawn footprint (%.1f, %.1f)"
				% [sector, drawn.position.y, drawn.end.y])
		# The rotated strike box's own southernmost point — `HALF_LENGTH * |heading.y| + HALF_WIDTH
		# * |heading.x|`, which is 26 along a vertical lane, 14 along a horizontal one and
		# `(L+W)/sqrt(2)` at exactly 45 degrees — plus whatever empty canvas that view leaves below
		# its own alpha content, so it is the drawn corner that lands on the box rather than the edge.
		var south_reach := Tuning.CAR_STRIKE_HALF_LENGTH * absf(heading.y) \
				+ Tuning.CAR_STRIKE_HALF_WIDTH * absf(heading.x)
		var margin: float = CrowdAgent.CAR_CANVAS_BOTTOM_MARGIN[view]
		t.check(is_equal_approx(anchor.y, south_reach + margin),
				("sector %d's %s anchor sits the rotated strike box's own south point, plus that "
				+ "canvas's own alpha margin, south of the node (%.2f)") % [sector, view, anchor.y])
		t.check(is_equal_approx(drawn.end.y - margin, south_reach),
				"so sector %d's drawn content lands exactly on the box's south point" % sector)
		if view == "side":
			# The along-track axis is screen-horizontal for a side view, centred by
			# `Sprites.draw_standing`'s own width handling — pinned so a correction added to the
			# anchor's x, which none of the five views needs, is a red test rather than a slid car.
			t.check(is_equal_approx(anchor.x, 0.0),
					"sector %d's side view keeps its along-track centre on the node" % sector)
	agent.free()

## **The registration does not jump at a sector boundary, because it is read off the live heading
## rather than off the view the heading was quantised to.** A car on an arc crosses a boundary every
## 45 degrees; with a per-view anchor the picture moved by the whole difference between two views'
## ground lines in the frame the texture swapped, which is the player's "while turning the car might
## get weirdly offset". Sampled either side of all eight boundaries, one hundredth of a degree apart:
## whatever the texture does, the ground line may not move further than the strike box's own south
## point moved over the same hundredth of a degree.
func _test_the_registration_is_continuous_across_a_sector_boundary(t) -> void:
	var agent := _car(t)
	var step := 0.01
	for boundary in range(8):
		var angle := 22.5 + 45.0 * float(boundary)
		var ground := []
		for side in [-step, step]:
			var heading := Vector2.from_angle(deg_to_rad(angle + side))
			var sector := EightDirection.nearest(heading)
			var view: String = CrowdAgent.CAR_VIEW_BY_SECTOR[sector]
			var anchor := agent._car_body_anchor(view, heading)
			ground.append(anchor.y - float(CrowdAgent.CAR_CANVAS_BOTTOM_MARGIN[view]))
		var moved: float = absf(ground[1] - ground[0])
		t.check(moved < 0.5,
				("crossing the %.1f degree boundary moves the drawn ground line by %.3fpx, which is "
				+ "the boundary's own share of the box's rotation rather than a jump")
				% [angle, moved])
	agent.free()

## **A steady glow is not a steady body, and the rim has to follow the body.** The rim is traced by
## re-running the owner's own `_draw_body()` (pinned by the test above), and `_draw()` is retained —
## so a rim that is only re-traced while a channel is easing keeps whatever silhouette the owner had
## when the glow settled. That is the player's "a turning car will have the original halo while
## turning". Headless never calls `_draw()`, so what is asserted here is the state the drawing reads
## — the same division `tests/test_checkpoints.gd` draws for the checkpoint hut's own suppression.
func _test_the_rim_is_re_traced_under_a_steady_glow(t) -> void:
	var agent := _car(t)
	agent.set_halo_strength(ExcitementHalo.MAX_ALPHA, Palette.HALO_STRONG)
	var halo: EntityHalo = agent._halo
	var step := 1.0 / 60.0
	for i in int(round(EntityHalo.FADE_IN_SECONDS / step)) + 2:
		halo._process(step)
	t.check(halo.has_settled(),
			"the glow has finished easing — the exact state a rim used to stop re-tracing in")
	t.check(halo.is_showing(),
			"and it is still drawn, which is what makes `_process()` ask for another trace anyway")

	# And the silhouette genuinely changes underneath it: the same car, one sector on.
	agent._vertical = false
	agent._direction = 1.0
	agent._speed = 130.0
	agent._turn = null
	agent._car_view = 4
	var standing := _silhouette(agent)
	agent._turn = _turn_facing(1)
	agent._turn_run_up = 0.0
	agent._speed = Tuning.CAR_TURN_SPEED
	var turning := _silhouette(agent)
	t.check(standing != turning,
			("a car that has turned onto an arc draws a different picture at a different anchor "
			+ "(%s against %s), so a rim traced before the turn is the wrong rim")
			% [standing, turning])
	# Freed with the halo still attached, for the reason `_test_the_halo_redraws_the_same_body()`
	# states: driving the fade-out to zero here would queue the child's own `free()` into a race
	# with `agent.free()`. `tests/test_halo.gd` holds the far end of the fade on a standalone rim.
	agent.free()

## Everything about the rim `EntityHalo` would trace for this car right now — the texture pair it
## looks up, whether it is mirrored, and where it is anchored. `_draw_body()` reads exactly these
## three and nothing else, so two different answers here are two different silhouettes.
func _silhouette(agent: CrowdAgent) -> Array:
	var view: String = CrowdAgent.CAR_VIEW_BY_SECTOR[agent._frame()]
	return [view, agent._flipped(), agent._car_body_anchor(view, agent.heading())]

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

## The picture `_draw_body()` would actually put on the canvas for one view and heading: the body's
## rect merged with the trim's and the wheels', each built the way `Sprites.draw_standing()` builds
## it — the baked region's own native size, which is the authored SVG's size in every bake,
## bottom-centred on `_car_body_anchor()`'s answer. At rest, which is where these cars stand: the
## three layers share one anchor until the body rides a bob.
func _drawn_picture(agent: CrowdAgent, view: String, heading: Vector2) -> Rect2:
	var anchor := agent._car_body_anchor(view, heading)
	var drawn := Rect2()
	var merged := false
	for path in [CrowdAgent.CAR_BODY_BY_VIEW[view], CrowdAgent.CAR_TRIM_BY_VIEW[view],
			CrowdAgent.CAR_WHEELS_BY_VIEW[view]]:
		var extent := Vector2(AtlasLibrary.native_size(StringName(path)))
		var layer := Rect2(anchor - Vector2(extent.x * 0.5, extent.y), extent)
		drawn = drawn.merge(layer) if merged else layer
		merged = true
	return drawn

## And what the rim traced around it covers: the same picture re-drawn at every one of
## `EntityHalo.trace_offsets()`'s own ring positions, which is what `_on_draw()` does per offset.
## A car standing still has no bob (`CrowdAgent._body_bob()` is zero at zero speed), so the ring
## is the plain circle.
func _traced_rim(agent: CrowdAgent, view: String, heading: Vector2) -> Rect2:
	var picture := _drawn_picture(agent, view, heading)
	var rim := Rect2()
	var merged := false
	for offset in EntityHalo.trace_offsets(agent._body_bob()):
		var copy := Rect2(picture.position + offset, picture.size)
		rim = rim.merge(copy) if merged else copy
		merged = true
	return rim

## **The rim is the picture and nothing else, so the two can only ever be concentric.** The defect
## this is the pin for was reported as a car sitting south of its own halo, and the first thing that
## had to be ruled out was a rim with a registration of its own — so this asserts the relationship
## rather than either position: whatever `_car_body_anchor()` answers and whichever native size the
## baked region reports, the traced rim is the drawn picture grown by `EntityHalo.HALO_MARGIN` on
## every side, at every sector.
##
## **One presentation mode**, unlike before this milestone: the bake fixes SVG or PNG once for the
## whole tree, so there is no longer a second mode to agree with at runtime — `--svg` now bakes a
## different `crowd.png`, which `tests/test_atlas_library.gd`'s parity check compares pixel for
## pixel against today's picture in whichever mode the tree was baked in.
##
## Mirroring is deliberately not a variable here: `Sprites.mirrored_transform()` reflects about the
## anchor, which a rect centred on that anchor's own x is symmetric under, so the *bounds* are the
## same either way. `tests/test_halo.gd` holds the mirrored ring itself.
func _test_the_rim_and_the_picture_share_one_footprint(t) -> void:
	var agent := _car(t)
	var margin := EntityHalo.HALO_MARGIN
	for sector in range(8):
		var view: String = CrowdAgent.CAR_VIEW_BY_SECTOR[sector]
		var heading := Vector2.from_angle(deg_to_rad(sector * 45.0))
		var picture := _drawn_picture(agent, view, heading)
		var rim := _traced_rim(agent, view, heading)
		t.check(rim.get_center().is_equal_approx(picture.get_center()),
				("sector %d's rim is centred on its own picture (%s against %s)"
				% [sector, rim.get_center(), picture.get_center()]))
		t.check(rim.size.is_equal_approx(picture.size + Vector2.ONE * margin * 2.0),
				("sector %d's rim stands %.0fpx out from the picture on every side (%s against %s)"
				% [sector, margin, rim.size, picture.size]))
	agent.free()

## A synthetic `CarTurn` whose tangent at zero travelled is exactly `degrees` clockwise from east,
## for sweeping a heading through a sector rather than landing on its centre. `heading_at(0)` is
## `Vector2(-sin(start_angle), cos(start_angle))` at `spin` 1, which is `Vector2.from_angle()` of
## `start_angle + 90°`.
func _turn_at(degrees: float) -> CarTurn:
	var turn := CarTurn.new()
	turn.radius = 16.0
	turn.spin = 1.0
	turn.start_angle = deg_to_rad(degrees - 90.0)
	turn.travelled = 0.0
	return turn

## **A redraw gate is a promise about everything the drawing reads.** `_draw()` is retained and
## moving a `Node2D` does not invalidate its draw list, so `_redraw_if_the_picture_changed()` is
## what decides when a car's picture is rebuilt — and a car's picture is not only its sector and its
## mirror: `_car_body_anchor()` registers it off the **live** heading and `_draw_shape_shadow()`
## sweeps the capsule along the same one. Keyed on the quantised half alone, a car that has come
## round an arc keeps the anchor it had at the last sector boundary, up to 22.5 degrees back, and
## keeps it for the rest of its run in that lane because nothing quantised ever changes again — its
## picture sits south of its own strike box while `EntityHalo`, which re-traces every frame, draws
## the rim where the car belongs. That is the player's "a car ... offset by a few pixel south and
## the halo is at the regular position".
##
## So the property is stated over the drawing rather than over the key: **wherever the anchor moves
## by as much as half a pixel, the gate must have asked for a redraw.** Headless never calls
## `_draw()`, so what is read back is the state the gate leaves behind — the same division
## `_test_the_rim_is_re_traced_under_a_steady_glow()` above already makes.
func _test_the_redraw_gate_carries_the_live_anchor(t) -> void:
	var agent := _car(t)
	agent._speed = Tuning.CAR_TURN_SPEED
	var previous_anchor := INF
	var previous_key := []
	var previous_picture := Vector3i(-1, -1, -1)
	var moves := 0
	var moves_inside_one_view := 0
	for sample in range(10):
		var degrees := float(sample) * 5.0
		agent._turn = _turn_at(degrees)
		agent._turn_run_up = 0.0
		var view: String = CrowdAgent.CAR_VIEW_BY_SECTOR[agent._frame()]
		var anchor := agent._car_body_anchor(view, agent.heading()).y
		agent._redraw_if_the_picture_changed()
		var key := [agent._picture, agent._drawn_heading]
		if previous_anchor != INF and absf(anchor - previous_anchor) >= 0.5:
			moves += 1
			if agent._picture == previous_picture:
				moves_inside_one_view += 1
			t.check(key != previous_key,
					("the ground line moved %.2fpx at %.1f degrees, so the gate has to have asked "
					+ "for a redraw") % [absf(anchor - previous_anchor), degrees])
		previous_anchor = anchor
		previous_key = key
		previous_picture = agent._picture
	t.check(moves > 0, "there were headings whose drawn ground line actually moved (%d)" % moves)
	# The guard that stops this passing on the strength of the sector boundaries alone, which the
	# quantised half of the key already catches: what is being held is the arc *between* them.
	t.check(moves_inside_one_view > 0,
			("and %d of them moved it without changing the sector, the mirror or the gait — the "
			+ "case a key made only of those three cannot see") % moves_inside_one_view)

	# And the landing itself, which is the shape that shipped: a car finishing a turn into an
	# east-west lane draws the same view, unmirrored, at both headings — so the sector, the mirror
	# and the gait are identical and only the anchor has moved.
	# Already showing the side view, which is where a car really is at twenty degrees: the sector
	# flipped at the boundary a couple of degrees back and the rest of the arc changes nothing about
	# it. Set rather than swept in, because the sweep above left the hold on the diagonal.
	agent._car_view = 0
	agent._turn = _turn_at(20.0)
	agent._turn_run_up = 0.0
	var turning_view: String = CrowdAgent.CAR_VIEW_BY_SECTOR[agent._frame()]
	var turning := agent._car_body_anchor(turning_view, agent.heading()).y
	agent._redraw_if_the_picture_changed()
	var mid_turn := [agent._picture, agent._drawn_heading]
	agent._turn = null
	agent._vertical = false
	agent._direction = 1.0
	var landed_view: String = CrowdAgent.CAR_VIEW_BY_SECTOR[agent._frame()]
	var landed := agent._car_body_anchor(landed_view, agent.heading()).y
	agent._redraw_if_the_picture_changed()
	t.check(landed_view == turning_view and agent._picture == mid_turn[0],
			"the car draws the same %s view either side of the landing, so nothing quantised changed"
			% landed_view)
	t.check(absf(landed - turning) > 1.0,
			"but its ground line moved %.2fpx between the two" % absf(landed - turning))
	t.check([agent._picture, agent._drawn_heading] != mid_turn,
			"so the gate asked for the redraw that puts the picture back under its own rim")
	agent.free()

# ------------------------------------------------------------------ the bob ---

## **The wheels are the third layer of the same picture**, so they can only register where the body
## does: every view has one, baked as a region of its own, on exactly the body's canvas — the one
## size `Sprites.draw_standing()` bottom-centres all three layers by. A wheels picture of another
## size would stand its tyres somewhere under the car other than where they were drawn.
func _test_wheels_share_the_body_canvas(t) -> void:
	t.check(CrowdAgent.CAR_WHEELS_BY_VIEW.keys().size() == CrowdAgent.CAR_BODY_BY_VIEW.keys().size(),
			"every body view has a wheels view and nothing else does")
	for view in CrowdAgent.CAR_BODY_BY_VIEW.keys():
		t.check(CrowdAgent.CAR_WHEELS_BY_VIEW.has(view), "the %s view has wheels" % view)
		var wheels := StringName(CrowdAgent.CAR_WHEELS_BY_VIEW[view])
		var body := StringName(CrowdAgent.CAR_BODY_BY_VIEW[view])
		var trim := StringName(CrowdAgent.CAR_TRIM_BY_VIEW[view])
		t.check(AtlasLibrary.has_region(wheels), "the %s wheels are baked" % view)
		t.check(wheels != body and wheels != trim,
				"the %s wheels are a region of their own, so the tint never reaches them" % view)
		t.check(AtlasLibrary.native_size(wheels) == AtlasLibrary.native_size(body),
				"the %s wheels share the body's canvas (%s against %s)"
				% [view, AtlasLibrary.native_size(wheels), AtlasLibrary.native_size(body)])

## A car in a lane, driven one tick at a time at a cruising speed. Its lane is east-west, which
## `heading()` answers exactly, so nothing but the bob can change about its picture.
func _cruising_car(t, speed: float) -> CrowdAgent:
	var agent := _car(t)
	agent._vertical = false
	agent._direction = 1.0
	agent._speed = speed
	agent._turn = null
	return agent

## **A moving car's body rises and falls about a pixel, and a stopped one sits still.** Driven for
## more than one wavelength of ground, its bob spans the whole of `WheelBob.HEIGHT` and never leaves
## it; brought to a stop at the top of a rise, it is back on its wheels at once, and ticks that
## cover no ground move nothing.
func _test_a_moving_car_bobs_and_a_stopped_car_sits_still(t) -> void:
	var agent := _cruising_car(t, Tuning.CAR_SPEED.x)
	var step := 1.0 / 60.0
	var lowest := 0.0
	var highest := -INF
	var ticks := int(ceil(1.5 * WheelBob.WAVELENGTH / (Tuning.CAR_SPEED.x * step)))
	var highest_travelled := 0.0
	for i in ticks:
		agent._advance_car_bob(step)
		var bob := agent._body_bob()
		t.check(bob <= 0.0 and bob >= -WheelBob.HEIGHT - 0.001,
				"tick %d's bob %.3f stays between the wheels and one height above them" % [i, bob])
		if bob < lowest:
			lowest = bob
			highest_travelled = agent._car_travelled
		highest = maxf(highest, bob)
	t.check(lowest < -0.9 * WheelBob.HEIGHT,
			"a cruising car's body reaches the top of its rise (%.3f)" % lowest)
	t.check(highest > -0.1 * WheelBob.HEIGHT,
			"and comes back down onto its wheels (%.3f)" % highest)
	# Stopped at the top of the rise: the phase stays where it was, the body does not.
	agent._car_travelled = highest_travelled
	agent._speed = 0.0
	t.check(agent._body_bob() == 0.0, "a stopped car sits on its wheels (%.3f)" % agent._body_bob())
	agent._advance_car_bob(step)
	t.check(is_equal_approx(agent._car_travelled, highest_travelled),
			"and a tick that covers no ground does not move its phase")
	agent.free()

## **The bob is a function of ground covered, not of time**: a slow car and a fast one that have
## covered the same distance are at the same point of it, and the fast one gets there sooner.
func _test_the_bob_is_driven_by_ground_covered(t) -> void:
	var slow := _cruising_car(t, Tuning.CAR_SPEED.x)
	var fast := _cruising_car(t, Tuning.CAR_SPEED.y)
	var distance := WheelBob.WAVELENGTH * 0.4
	slow._advance_car_bob(distance / Tuning.CAR_SPEED.x)
	fast._advance_car_bob(distance / Tuning.CAR_SPEED.y)
	t.check(is_equal_approx(slow._body_bob(), fast._body_bob()),
			"two cars that covered %.0fpx ride the same lift (%.3f and %.3f)"
			% [distance, slow._body_bob(), fast._body_bob()])
	t.check(not is_zero_approx(slow._body_bob()), "and it was a lift worth comparing")
	slow.free()
	fast.free()

## **The halo traces the bob through `bob()`**: the rim is built with the car's own `_body_bob`, and
## the ring `EntityHalo` traces is lifted by exactly what the body is lifted by, so a rising car's
## rim rises with it rather than sliding off it.
func _test_the_halo_rides_the_bob(t) -> void:
	var agent := _cruising_car(t, Tuning.CAR_SPEED.x)
	agent._advance_car_bob(WheelBob.WAVELENGTH * 0.5 / Tuning.CAR_SPEED.x)
	agent.set_halo_strength(1.0, Color.RED)
	t.check(agent._halo._bob == agent._body_bob,
			"the halo reads this car's own bob rather than a flat zero")
	var bob := agent._body_bob()
	t.check(bob < -0.5 * WheelBob.HEIGHT, "the car is well up its rise (%.3f)" % bob)
	var flat := EntityHalo.trace_offsets(0.0)
	var lifted := EntityHalo.trace_offsets(agent._halo._bob.call())
	var rides := flat.size() == lifted.size()
	for i in flat.size():
		rides = rides and lifted[i].is_equal_approx(flat[i] + Vector2(0.0, bob))
	t.check(rides, "every offset of the ring is lifted by the body's own %.3fpx" % bob)
	agent.free()

## **A redraw gate is a promise about everything the drawing reads**, and a moving car's drawing now
## reads its bob. Driven down a lane, where nothing else about its picture changes, the key's third
## term is the quantised bob on every tick and it moves as the body does; stopped, it never moves.
func _test_the_redraw_gate_follows_the_bob(t) -> void:
	var agent := _cruising_car(t, Tuning.CAR_SPEED.x)
	var step := 1.0 / 60.0
	agent._redraw_if_the_picture_changed()
	var keys := {}
	var ticks := int(ceil(WheelBob.WAVELENGTH / (Tuning.CAR_SPEED.x * step)))
	for i in ticks:
		agent._advance_car_bob(step)
		agent._redraw_if_the_picture_changed()
		t.check(agent._picture.z == roundi(agent._body_bob() * CrowdAgent.CAR_BOB_STEPS_PER_PX),
				"tick %d's key carries the bob it would draw" % i)
		keys[agent._picture] = true
	t.check(keys.size() > 2,
			"a car driving one wavelength asks for a redraw at several heights (%d keys)"
			% keys.size())
	agent._speed = 0.0
	agent._redraw_if_the_picture_changed()
	var parked := agent._picture
	for i in 30:
		agent._advance_car_bob(step)
		agent._redraw_if_the_picture_changed()
	t.check(agent._picture == parked and parked.z == 0,
			"a stopped car's key rests at zero and stays there")
	agent.free()
