extends RefCounted
## Nothing off screen is redrawn, and every cue is back on the frame it can be seen.
## *(velvet-marten, #700, the player: "Skipping redraws for of screen elements. Also we don't really
## change things with animation if it's of screen. If we have a bounding box that extends a little
## bit into of screen then it won't be noticable.")*
##
## `DrawnView` is the one box every gate asks. Each gate here is held to the cues' own promise: a
## caret or a badge that is owed is drawn on the frame its thing comes into view, never a frame late
## — so each one is walked in from off screen a step at a time, and the frame it asks for its redraw
## is checked against the first frame any of its drawing reaches the screen itself, measured from
## the drawing's own numbers rather than from the reach the gate asks with. Headless runs never call
## `_draw()`, so what is checked is that the redraw is asked for and that the caret it would draw is
## up; `_draw()` reads nothing the redraw does not.

const STEP := 1.0 / 60.0
## The design box, and the camera's zoom on it: the world a screen shows is half of it each way.
const SCREEN := Vector2(1280.0, 720.0)
const ZOOM := 2.0

func run(t) -> void:
	_test_the_box_is_the_screen_grown_by_the_margin(t)
	_test_a_hand_built_agent_with_no_screen_is_always_drawn(t)
	_test_a_car_reach_holds_everything_it_draws(t)
	_test_an_off_screen_car_is_not_redrawn_and_is_back_before_it_shows(t)
	_test_a_walker_is_redrawn_on_entry_even_with_an_unchanged_picture(t)
	_test_an_off_screen_event_skips_its_key_and_its_caret_is_back_before_it_shows(t)
	_test_a_wide_burning_front_redraws_while_any_of_it_shows(t)
	_test_the_edge_redraws_only_while_a_badge_is_up_or_coming_down(t)
	_test_a_hidden_arrow_redraws_once(t)

## A screen of its own for the gates to ask about: a `SubViewport` the size of the design box whose
## canvas shows the world from `top_left` at the game's zoom, so no other suite's camera moves it.
func _screen(t, top_left := Vector2.ZERO) -> SubViewport:
	var screen := SubViewport.new()
	screen.size = Vector2i(SCREEN)
	t.add_child(screen)
	_look_from(screen, top_left)
	return screen

func _look_from(screen: SubViewport, top_left: Vector2) -> void:
	screen.canvas_transform = Transform2D(0.0, Vector2.ONE * ZOOM, 0.0, -top_left * ZOOM)
	DrawnView.forget()

func _world_shown(top_left: Vector2) -> Rect2:
	return Rect2(top_left, SCREEN / ZOOM)

## The box is the world the canvas shows grown by the margin, read off the transform alone, so a
## zoom and the portrait presentation's quarter turn are the screen they are.
func _test_the_box_is_the_screen_grown_by_the_margin(t) -> void:
	var screen := _screen(t, Vector2(100.0, 50.0))
	var box := DrawnView.box_of(screen)
	var wanted := _world_shown(Vector2(100.0, 50.0)).grow(DrawnView.MARGIN)
	t.check(box.position.is_equal_approx(wanted.position) and box.size.is_equal_approx(wanted.size),
			"the box is the world shown, %s, grown by the margin (got %s)" % [wanted, box])
	# Turned a quarter about the screen's centre, as a portrait window presents it: the world shown
	# is the same box stood on its side, and the box holds all of it.
	var centre := SCREEN * 0.5
	screen.canvas_transform = Transform2D(PI * 0.5, Vector2.ONE * ZOOM, 0.0, centre) \
			* Transform2D(0.0, -centre / ZOOM)
	DrawnView.forget()
	var turned := DrawnView.box_of(screen)
	t.check(is_equal_approx(turned.size.x, SCREEN.y / ZOOM + DrawnView.MARGIN * 2.0)
			and is_equal_approx(turned.size.y, SCREEN.x / ZOOM + DrawnView.MARGIN * 2.0),
			"a quarter turn shows the same world on its side, and the box follows it (%s)" % turned)
	screen.free()
	DrawnView.forget()

## A rig that steps an agent by hand outside any tree keeps the gate's old answer: there is no screen
## for it to be off, so every change still asks for its redraw.
func _test_a_hand_built_agent_with_no_screen_is_always_drawn(t) -> void:
	var car := CrowdAgent.new()
	car.kind = CrowdAgent.Kind.CAR
	car.position = Vector2(-5000.0, -5000.0)
	t.check(car._end_the_frame(0.0),
			"an agent in no tree still redraws its first picture, wherever it stands")
	car.free()

## The reach the crowd asks with holds everything an agent's own drawing can cover: every view of a
## car at the anchor it is drawn at, its shadow, and its doubled caret at full swell, measured from
## `_draw_mark()`'s and `Sprites.draw_caret()`'s own arithmetic; and every view of a walker in both
## halves of its stride. A reach that left any of it out would let that part onto the screen
## before the gate redraws it.
func _test_a_car_reach_holds_everything_it_draws(t) -> void:
	var reach := CrowdAgent.DRAWN_REACH
	var car := CrowdAgent.new()
	car.kind = CrowdAgent.Kind.CAR
	for i in 16:
		var heading := Vector2.RIGHT.rotated(TAU * float(i) / 16.0)
		for view in CarLook.BODY_BY_VIEW:
			var anchor := CarLook.body_anchor(view, heading)
			for path in [CarLook.BODY_BY_VIEW[view], CarLook.TRIM_BY_VIEW[view],
					CarLook.WHEELS_BY_VIEW[view]]:
				var extent := Vector2(AtlasLibrary.native_size(StringName(path)))
				var drawn := Rect2(anchor - Vector2(extent.x * 0.5, extent.y), extent) \
						.grow(1.0 + EntityHalo.HALO_MARGIN)
				t.check(reach.encloses(drawn),
						"the reach holds a car's %s drawn at %s (%s)" % [path, heading, drawn])
	var shadow := CarStrategy.SHADOW_ALONG * 0.5 + 1.0
	t.check(reach.encloses(Rect2(-shadow, -shadow, shadow * 2.0, shadow * 2.0)),
			"and its shadow capsule turned any way")
	var width := CrowdAgent.MARK_WIDTH
	var at := Vector2(0.0, -(CrowdAgent.MARK_HEIGHT + 10.0))
	var upper := at - Vector2(0.0, width * 0.85)
	var caret := Rect2(upper + Vector2(-width, -width * 0.8), Vector2(width * 2.0, width * 1.3)) \
			.merge(Rect2(at + Vector2(-width, -width * 0.8), Vector2(width * 2.0, width * 1.3))) \
			.grow(1.0)
	t.check(reach.encloses(caret), "and its doubled caret at full swell (%s)" % caret)
	car.free()
	for view in WalkerLook.BODY_BY_VIEW:
		for paths: Dictionary in [WalkerLook.BODY_BY_VIEW, WalkerLook.BODY_BY_VIEW_B,
				WalkerLook.TRIM_BY_VIEW, WalkerLook.TRIM_BY_VIEW_B]:
			var extent := Vector2(AtlasLibrary.native_size(StringName(paths[view])))
			var drawn := Rect2(-extent.x * 0.5, -extent.y, extent.x, extent.y) \
					.grow(EntityHalo.HALO_MARGIN)
			t.check(reach.encloses(drawn), "the reach holds a walker's %s" % paths[view])

## **A car off screen is neither redrawn nor projected for its caret, and it is redrawn — red caret
## and all — no later than the first frame any of it can be seen.** A car driving in from the
## west with her standing in its lane ahead of it, so its caret is the doubled red the whole way.
func _test_an_off_screen_car_is_not_redrawn_and_is_back_before_it_shows(t) -> void:
	var screen := _screen(t)
	var shown := _world_shown(Vector2.ZERO)
	var car := CrowdAgent.new()
	car.kind = CrowdAgent.Kind.CAR
	car._speed = 100.0
	car.set_process(false)
	screen.add_child(car)
	# The crowd hands every agent it makes the screen; a rig that adds one to a tree hands it itself.
	car.view = CrowdView.new(screen)
	var x := -700.0
	var asked_since_off := false
	var first_seen_asked := false
	var seen := false
	var skipped := 0
	var projected_off_screen := false
	while x < 200.0 and not seen:
		car.position = Vector2(x, 180.0)
		car.set_player_at(car.position + Vector2(60.0, 0.0))
		car._clock += STEP
		var before := car._mark_strength_clock
		var asked := car._end_the_frame(0.0)
		var in_box := DrawnView.box_of(screen).intersects(
				Rect2(car.position + CrowdAgent.DRAWN_REACH.position, CrowdAgent.DRAWN_REACH.size))
		if not in_box:
			skipped += 0 if asked else 1
			projected_off_screen = projected_off_screen or car._mark_strength_clock != before
		asked_since_off = asked_since_off or asked
		# Where the car's own drawing reaches: its body about its feet and the caret above it.
		if shown.intersects(Rect2(car.position + Vector2(-41.0, -66.0), Vector2(82.0, 100.0))):
			seen = true
			first_seen_asked = asked_since_off
		x += 4.0
	t.check(skipped > 50, "off screen the car asked for no redraw on %d frames" % skipped)
	t.check(not projected_off_screen, "and its caret was never projected there")
	t.check(seen and first_seen_asked,
			"it asked for its redraw no later than the first frame any of it shows")
	t.check(car._caret_strength() == 2,
			"and the redraw it asked for draws the doubled red caret it is owed")
	screen.free()
	DrawnView.forget()

## A walker whose picture did not change while it was off screen — standing, its view and stride
## where they were — still redraws on its first frame back, since what it shows was not kept.
func _test_a_walker_is_redrawn_on_entry_even_with_an_unchanged_picture(t) -> void:
	var screen := _screen(t)
	var walker := CrowdAgent.new()
	walker.kind = CrowdAgent.Kind.WALKER
	walker._speed = 0.0
	walker.set_process(false)
	screen.add_child(walker)
	# The crowd hands every agent it makes the screen; a rig that adds one to a tree hands it itself.
	walker.view = CrowdView.new(screen)
	walker.position = Vector2(320.0, 180.0)
	walker._end_the_frame(0.0)
	t.check(not walker._end_the_frame(0.0),
			"on screen, a walker whose picture did not change asks for nothing")
	_look_from(screen, Vector2(2000.0, 0.0))
	t.check(not walker._end_the_frame(0.0), "off screen it asks for nothing either")
	_look_from(screen, Vector2.ZERO)
	t.check(walker._end_the_frame(0.0),
			"back on screen it redraws once, though nothing in its key moved")
	t.check(not walker._end_the_frame(0.0), "and then only on a change again")
	screen.free()
	DrawnView.forget()

## **An event off screen runs no key and no caret projection, and it is redrawn with the caret it is
## owed no later than the frame any of it can be seen.** A cyclist on course for her, so its caret
## is the doubled red, stands still while the screen pans onto it, the way it does when she walks
## towards it; what can be seen is `drawn_rect_now()`, the drawing's own extent, caret included.
func _test_an_off_screen_event_skips_its_key_and_its_caret_is_back_before_it_shows(t) -> void:
	var def := EventCatalogue.by_id("cyclist")
	t.check(def != null and def.hard_fail, "cyclist is a hard-fail row")
	if not def:
		return
	var screen := _screen(t, Vector2(-2000.0, 0.0))
	var cyclist := EventInstance.new()
	cyclist.setup(def, Vector2(320.0, 180.0),
			PackedVector2Array([Vector2(320.0, 180.0), Vector2(1320.0, 180.0)]))
	cyclist.set_process(false)
	screen.add_child(cyclist)
	cyclist.set_player_at(cyclist.global_position + Vector2(def.outer_radius, 0.0))
	var key_before := cyclist._picture
	t.check(not cyclist._redraw_if_the_picture_changed(), "off screen it asks for no redraw")
	t.check(cyclist._picture == key_before and cyclist._caret_strength_age == -1.0,
			"and works out neither its key nor its caret")
	var drawn := cyclist.drawn_rect_now()
	t.check(cyclist.wants_a_mark() and cyclist.mark_colour() == Palette.MARK_LETHAL,
			"the caret it is owed is the doubled red")
	var left := -2000.0
	var asked_since_off := false
	var first_seen_asked := false
	var seen := false
	while left < 320.0 and not seen:
		_look_from(screen, Vector2(left, 0.0))
		asked_since_off = cyclist._redraw_if_the_picture_changed() or asked_since_off
		if _world_shown(Vector2(left, 0.0)).intersects(
				Rect2(cyclist.global_position + drawn.position, drawn.size)):
			seen = true
			first_seen_asked = asked_since_off
		left += 4.0
	t.check(seen and first_seen_asked,
			"it asked for its redraw no later than the first frame any of it shows")
	t.check(cyclist.wants_a_mark(), "and that redraw carries its caret")
	# The same picture off screen and back: nothing in its key moved, and it redraws all the same,
	# since nothing kept what it shows current while it was away.
	_look_from(screen, Vector2.ZERO)
	cyclist._redraw_if_the_picture_changed()
	t.check(not cyclist._redraw_if_the_picture_changed(),
			"on screen and unchanged, it asks for nothing")
	_look_from(screen, Vector2(-2000.0, 0.0))
	cyclist._redraw_if_the_picture_changed()
	_look_from(screen, Vector2.ZERO)
	t.check(cyclist._redraw_if_the_picture_changed(),
			"back on screen with the same key, it redraws once")
	screen.free()
	DrawnView.forget()

## **A street fire burns along the whole front of its building, far past its own picture, and it is
## redrawn on every tick any of that front can be on the screen** — its flames flicker and its
## smoke billows, so a front whose far end showed while the fire's own point was still out of the
## box would stand frozen there. The front here is set by hand, 640px of it running east from just
## west of the fire's point, the width `_facade_runs_at()` gives a long building; the screen pans
## along it from the east, so the far end shows long before the point does. What can be seen is
## worked out from the flames' and plumes' own numbers (`_flames_across()`, `_smoke_across()`, the
## tallest flicker), not from the box the gate asks with.
func _test_a_wide_burning_front_redraws_while_any_of_it_shows(t) -> void:
	var def := EventCatalogue.by_id("burning_building")
	t.check(def != null and def.obstructs_radius <= 0.0, "burning_building is the street fire")
	if not def:
		return
	var screen := _screen(t, Vector2(2000.0, 0.0))
	var fire := EventInstance.new()
	fire.setup(def, Vector2(0.0, 180.0))
	fire.set_process(false)
	fire._fire_facade = PackedVector2Array([Vector2(-40.0, 600.0)])
	fire._fire_facade_found = true
	screen.add_child(fire)
	var drawn := Rect2()
	var any := false
	for flame in EventInstance._flames_across(fire._fire_facade):
		var tallest := (EventInstance._FIRE_HEIGHT + EventInstance._FIRE_HEIGHT_TALL) * 1.25
		var one := Rect2(flame.x - flame.y * 0.5, -tallest, flame.y, tallest)
		drawn = one if not any else drawn.merge(one)
		any = true
	for plume in EventInstance._smoke_across(fire._fire_facade):
		var top := -(EventInstance._FIRE_HEIGHT + EventInstance._FIRE_HEIGHT_TALL) \
				- EventInstance._SMOKE_SIZE.y
		drawn = drawn.merge(Rect2(plume.x - plume.y * 0.5, top, plume.y, EventInstance._SMOKE_SIZE.y))
	t.check(fire._drawn_reach().encloses(drawn) and fire.drawn_rect_now().encloses(drawn),
			"the reach and the drawn rect hold the whole front and its smoke (%s)" % drawn)
	var shown_unasked := 0
	var shown_point_outside := 0
	var left := 1200.0
	while left > -700.0:
		_look_from(screen, Vector2(left, 0.0))
		var asked := fire._redraw_if_the_picture_changed()
		var on_screen := _world_shown(Vector2(left, 0.0)).intersects(
				Rect2(fire.global_position + drawn.position, drawn.size))
		if on_screen and not asked:
			shown_unasked += 1
		var point := Rect2(fire.global_position + EventInstance.footprint_of(def).position,
				EventInstance.footprint_of(def).size)
		if on_screen and not DrawnView.box_of(screen).intersects(point):
			shown_point_outside += 1
		left -= 8.0
	t.check(shown_point_outside > 20,
			"the front showed on %d frames while the fire's own picture was out of the box"
			% shown_point_outside)
	t.check(shown_unasked == 0,
			"and every frame any of the front showed, the fire was redrawn (%d were not)"
			% shown_unasked)
	screen.free()
	DrawnView.forget()

## **The badge is drawn on the frame it goes up, redrawn every frame it is up, and redrawn once to
## come off** — and with none up and none drawn there is nothing to redraw.
func _test_the_edge_redraws_only_while_a_badge_is_up_or_coming_down(t) -> void:
	var manager := EventManager.new()
	t.add_child(manager)
	var standing := Node2D.new()
	t.add_child(standing)
	var edge := DangerEdge.new()
	t.add_child(edge)
	edge.setup(manager, standing)
	t.check(not edge._watch_the_edge(STEP), "nothing coming, nothing drawn: no redraw")

	var def := EventCatalogue.by_id("fire_truck")
	var engine := EventInstance.new()
	engine.setup(def, Vector2(1200.0, 0.0))
	engine.set_process(false)
	manager.add_child(engine)
	manager._instances.append(engine)
	var asked_when_up := false
	var went_up := false
	for i in 120:
		engine.global_position -= Vector2(def.speed * STEP, 0.0)
		var asked := edge._watch_the_edge(STEP)
		if not edge.model.coming.is_empty() and not went_up:
			went_up = true
			asked_when_up = asked
		if went_up:
			break
	t.check(went_up and asked_when_up, "the frame the badge goes up is the frame it is drawn")
	t.check(edge._watch_the_edge(STEP) and not edge.model.coming.is_empty(),
			"and it is redrawn every frame it stays up, the camera moving under it")

	manager._instances.erase(engine)
	t.check(edge._watch_the_edge(STEP), "the frame it comes down redraws once to take it off")
	t.check(not edge._watch_the_edge(STEP), "and then the empty edge is not redrawn again")
	edge.free()
	standing.free()
	manager.free()

## The arrow is hidden every frame it is not wanted; only the frame it goes from shown to hidden has
## anything to take off the screen.
func _test_a_hidden_arrow_redraws_once(t) -> void:
	var arrow := HomeArrow.new()
	t.check(not arrow.hide_arrow(), "an arrow already hidden is not redrawn to hide it again")
	arrow.show_toward(Vector2(100.0, 100.0))
	t.check(arrow.hide_arrow(), "the frame a shown arrow is hidden redraws to take it off")
	t.check(not arrow.hide_arrow(), "and every frame after that asks for nothing")
	arrow.free()
