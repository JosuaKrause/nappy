extends RefCounted
## M108, eight-direction entity graphics: binding live event people, animals, riders and vehicles
## to `EightDirection`. `tests/test_walker_views.gd` already pins the selector itself and the crowd
## walker's own wiring; this suite pins the event side of the same convention —
## `EventPictures.EIGHT_VIEW_BY_SECTOR`, `select_view()`, each family's own `_BY_VIEW` table and
## heading source, and — for the vehicle families at the bottom — `_draw_eight_view()`'s
## `side_faces_west` parameter, the one bit a family's own art rather than its geometry decides.
##
## Nothing here calls a `_draw_*` function directly — `Sprites.draw_standing()` and the raw
## `canvas.draw_*` calls inside them are only valid from an actual draw pass. A check about
## where a picture stands or which way it faces hands the instance a recording drawer
## (`tests/recording_event_drawer.gd`) through `EventSurroundings.drawing_through()`, as its
## manager's spawner hands one in, lets real frames draw it, and reads what the look told the
## drawer to draw; one about a selector asks the selector the look asks (`select_view()`, the
## `_BY_VIEW` tables), and one no picture answers (which view a heading selects, the lift of a
## stride) asks a look the suite makes round a fake event (`FakeEvent.look_for()`), set to what
## the real event answers. The rendered evidence sheets under
## `docs/evidence/m108-event-people-2026-09-11/` and
## `docs/evidence/m108-event-vehicles-2026-09-11/` are what a screenshot answers that a test
## cannot — see the **writing-tests** skill, "test what a screenshot cannot see, screenshot
## what a test cannot judge."
##
## It also holds what a live row drawn through the recording drawer stands against what its row
## obstructs: a barrier's end posts at the edge of its obstruction, and a whole scene's slices
## spanning it.

const STEP := 1.0 / 60.0
const DrawnEvent := preload("res://tests/drawn_event.gd")
const RecordingEventDrawer := preload("res://tests/recording_event_drawer.gd")

## `EightDirection`'s own sector order (0 E .. 7 NE), and the view/mirror `docs/GRAPHICS.md`'s
## mirror convention says each one draws — identical to `WalkerLook.VIEW_BY_SECTOR` and
## `tests/test_walker_views.gd`'s own `EXPECTED_VIEW`/`EXPECTED_MIRRORED`, since every family below
## shares the one table.
const EXPECTED_VIEW: Array[String] = [
	"side", "front_diagonal", "front", "front_diagonal", "side",
	"back_diagonal", "back", "back_diagonal",
]
const EXPECTED_MIRRORED: Array[bool] = [false, false, false, true, true, true, false, false]

## Every family's own five-view table, name to dictionary, so the completeness and distinctness
## checks below run once over the whole set rather than once per family by hand.
const FAMILY_DICTS := {
	"person": EventPictures.PERSON_BY_VIEW,
	"yeller": EventPictures.YELLER_BY_VIEW,
	"busker": EventPictures.BUSKER_BY_VIEW,
	"poster_crew": EventPictures.POSTER_CREW_BY_VIEW,
	"poster_crew_square": EventPictures.POSTER_CREW_SQUARE_BY_VIEW,
	"cafe_sitter": EventPictures.CAFE_SITTER_BY_VIEW,
	"van_victim": EventPictures.VAN_VICTIM_BY_VIEW,
	"protester": EventPictures.PROTESTER_BY_VIEW,
	"leaf_blower": EventPictures.LEAF_BLOWER_BY_VIEW,
	"robber_waiting": EventPictures.ROBBER_WAITING_BY_VIEW,
	"robber_lunging": EventPictures.ROBBER_LUNGING_BY_VIEW,
	"robber_alert": EventPictures.ROBBER_ALERT_BY_VIEW,
	"robber_alert_b": EventPictures.ROBBER_ALERT_BY_VIEW_B,
	"chatting_mother_walking": EventPictures.CHATTING_MOTHER_WALKING_BY_VIEW,
	"chatting_mother_talking": EventPictures.CHATTING_MOTHER_TALKING_BY_VIEW,
	"cat_crouched": EventPictures.CAT_CROUCHED_BY_VIEW,
	"cat_running": EventPictures.CAT_RUNNING_BY_VIEW,
	"dog": EventPictures.DOG_BY_VIEW,
	"charging_dog": EventPictures.CHARGING_DOG_BY_VIEW,
	"charging_dog_resting": EventPictures.CHARGING_DOG_RESTING_BY_VIEW,
	"charging_dog_alert": EventPictures.CHARGING_DOG_ALERT_BY_VIEW,
	"cyclist": EventPictures.CYCLIST_BY_VIEW,
	"pelican_cyclist": EventPictures.PELICAN_BY_VIEW,
	"pigeon": EventPictures.PIGEON_BY_VIEW,
	"pigeon_down": EventPictures.PIGEON_DOWN_BY_VIEW,
	"delivery_van": EventPictures.DELIVERY_VAN_BY_VIEW,
	"fire_engine": EventPictures.FIRE_ENGINE_BY_VIEW,
	"ice_cream_van": EventPictures.ICE_CREAM_VAN_BY_VIEW,
	"lorry": EventPictures.LORRY_BY_VIEW,
	"unmarked_van": EventPictures.UNMARKED_VAN_BY_VIEW,
	"army_truck": EventPictures.ARMY_TRUCK_BY_VIEW,
	"police_car": EventPictures.POLICE_CAR_BY_VIEW,
	"riot_van": EventPictures.RIOT_VAN_BY_VIEW,
	"mouse": EventPictures.MOUSE_BY_VIEW,
	"guard_standing": EventPictures.GUARD_STANDING_BY_VIEW,
	"guard_lunging": EventPictures.GUARD_LUNGING_BY_VIEW,
	"guard_alert": EventPictures.GUARD_ALERT_BY_VIEW,
	"policeman_waiting": EventPictures.POLICEMAN_WAITING_BY_VIEW,
	"policeman_alert": EventPictures.POLICEMAN_ALERT_BY_VIEW,
	"policeman_lunging": EventPictures.POLICEMAN_LUNGING_BY_VIEW,
}

## The animal/rider families whose `"side"` entry is required to be the exact pre-existing
## canonical constant rather than a second preload of the same picture — see
## `docs/GRAPHICS.md`'s instruction to replace a preload "only where the suffixed side ... is the
## same picture," and `docs/evidence/svg-vehicles-2026-09-10/facings.csv`, which marks every one of
## these "existing canonical source."
const ANIMAL_SIDE_REUSE := {
	"cat_crouched": EventPictures.CAT_CROUCHED,
	"cat_running": EventPictures.CAT_RUNNING,
	"dog": EventPictures.DOG,
	"charging_dog": EventPictures.CHARGING_DOG,
	"cyclist": EventPictures.CYCLIST,
	"pigeon": EventPictures.PIGEON,
	"pigeon_down": EventPictures.PIGEON_DOWN,
	"mouse": EventPictures.MOUSE,
}

## The vehicle families' own `"side"` entry, same reuse rule as `ANIMAL_SIDE_REUSE` above —
## `facings.csv` marks every one of these "existing canonical source" too, `riot_van` included.
const VEHICLE_SIDE_REUSE := {
	"delivery_van": EventPictures.DELIVERY_VAN,
	"fire_engine": EventPictures.FIRE_ENGINE,
	"ice_cream_van": EventPictures.ICE_CREAM_VAN,
	"lorry": EventPictures.LORRY,
	"unmarked_van": EventPictures.UNMARKED_VAN,
	"army_truck": EventPictures.ARMY_TRUCK,
	"police_car": EventPictures.POLICE_CAR,
	"riot_van": EventPictures.RIOT_VAN,
}

## Which vehicle families' `"side"` view is authored facing west rather than east — the exact
## `side_faces_west` argument `EventLook.draw_body()` passes to `_draw_eight_view()` for each,
## read back here so the selector test below can assert the mirror the same way the drawing does.
## `ice_cream_van`, `lorry` and `police_car` are the three genuinely east-authored families;
## `riot_van` joins `delivery_van`, `fire_engine`, `unmarked_van` and `army_truck` as west-authored
## — see `RIOT_VAN_BY_VIEW`'s own doc comment.
const VEHICLE_SIDE_FACES_WEST := {
	"delivery_van": true,
	"fire_engine": true,
	"ice_cream_van": false,
	"lorry": false,
	"unmarked_van": true,
	"army_truck": true,
	"police_car": false,
	"riot_van": true,
}

func run(t: TestRunner) -> void:
	_test_select_view_holds_and_mirrors(t)
	_test_select_view_zero_heading_holds(t)
	await _test_cafe_sitters_face_their_own_tables(t)
	_test_roadwork_barrier_has_an_upright_vertical_source(t)
	_test_roadblock_barrier_is_end_on_down_a_column(t)
	await _test_roadblock_guard_stands_clear_of_the_band(t)
	await _test_a_spread_covers_the_ground_its_body_closes(t)
	await _test_a_spread_cap_matches_what_it_obstructs(t)
	await _test_a_whole_scene_spans_its_obstruction(t)
	_test_family_dictionaries_are_complete(t)
	_test_people_views_are_five_distinct_pictures(t)
	_test_vehicle_views_are_five_distinct_pictures(t)
	_test_state_pairs_stay_visually_distinct(t)
	await _test_setup_resets_the_view_to_the_exact_siting(t)
	_test_robber_waiting_faces_her(t)
	_test_robber_waiting_falls_back_to_its_siting_with_no_player(t)
	_test_cat_state_predicate_selects_the_telegraph_posture(t)
	_test_chatting_mother_state_predicate_selects_the_conversation_posture(t)
	await _test_masked_man_is_drawn_lunging_from_the_tick_he_comes(t)
	await _test_the_waiting_dog_rests_stands_alert_and_gallops(t)
	await _test_the_day_3_dog_gallops_through_its_approach(t)
	await _test_the_robber_waits_walks_alert_and_lunges(t)
	await _test_the_roadblock_guard_raises_his_hand_at_his_post(t)
	await _test_the_door_guard_raises_his_hand_at_the_hut_and_charges_at_once(t)
	await _test_the_man_out_of_a_vehicle_raises_his_hand_then_charges(t)
	await _test_no_guard_who_arrives_charging_takes_the_alert(t)
	_test_vehicle_views_match_facings_csv_per_sector(t)
	_test_kerb_parked_vans_keep_their_axis_chosen_view(t)
	_test_reversing_lorry_only_ever_faces_the_side_view(t)
	_test_vehicle_views_are_grounded_at_the_canvas_bottom(t)
	_test_burst_water_main_draws_no_body_shadow(t)
	_test_a_scene_shaped_van_casts_its_shadow_under_its_wheels(t)
	_test_every_moving_vehicle_has_wheels_on_its_own_canvas(t)
	_test_a_moving_vehicle_bobs_on_its_wheels_and_a_stopped_one_sits_still(t)
	_test_a_walking_event_keeps_its_stride_bob(t)
	_test_a_vehicle_badge_draws_its_wheels(t)

func _heading_for_sector(sector: int) -> Vector2:
	return Vector2.from_angle(deg_to_rad(sector * 45.0))

# ------------------------------------------------------------------- the selector wiring ---

## `select_view()` is what every `_draw_*` below reads instead of repeating
## `EightDirection.update()` and the table lookup itself — this pins that wiring once, over all
## eight headings, rather than once per family that calls it.
func _test_select_view_holds_and_mirrors(t: TestRunner) -> void:
	var instance := FakeEvent.new()
	var look := instance.look_for(EventCatalogue.shipped().by_id("busker"))
	for sector in range(8):
		# Started from the opposite sector every time, so a pass here is never an accident of the
		# previous iteration's hold agreeing with this one.
		look.face(_heading_for_sector((sector + 4) % 8))
		var view := look.select_view(_heading_for_sector(sector))
		t.check(view == EXPECTED_VIEW[sector],
				"heading %d degrees selects the %s view (got %s)"
				% [sector * 45, EXPECTED_VIEW[sector], view])
		t.check(look.is_mirrored() == EXPECTED_MIRRORED[sector],
				"sector %d mirror flag matches the west convention" % sector)
	instance.free()

## The one behaviour worth pinning at the wiring level rather than trusting `EightDirection`'s own
## suite to cover by proxy: `select_view()` passes no idle floor of its own (every heading fed to
## it below is already a unit vector that is never actually zero), so an exactly-zero heading still
## holds through `EightDirection.update()`'s own default threshold — the same "stopped actor keeps
## its last facing" contract the walkers get, reached the same way `Stroller` reaches it.
func _test_select_view_zero_heading_holds(t: TestRunner) -> void:
	var instance := FakeEvent.new()
	var look := instance.look_for(EventCatalogue.shipped().by_id("busker"))
	look.face(Vector2.RIGHT)
	var view := look.select_view(Vector2.ZERO)
	t.check(view == "side" and not look.is_mirrored(),
			"an exactly zero heading holds whatever sector was last drawn")
	instance.free()

## Café sitters use their alternating chair offset to face their own table. The fixed -7px
## screen-depth lift `_draw_cafe()` stands a sitter by is not part of this bearing: horizontal
## frontages use the two side facings, and vertical frontages use the two upright front/back
## facings. A café drawn on either axis with a recording drawer handed in says which picture each
## table's sitter was drawn in and whether it was mirrored, and where the sitter and the table
## stand.
func _test_cafe_sitters_face_their_own_tables(t: TestRunner) -> void:
	var expected := {
		false: [[Vector2.RIGHT, "side", false], [Vector2.LEFT, "side", true]],
		true: [[Vector2.DOWN, "front", false], [Vector2.UP, "back", false]],
	}
	var sitters := {}
	for picture: String in EventPictures.CAFE_SITTER_BY_VIEW.values():
		sitters[picture] = true
	for picture: String in EventPictures.CAFE_SITTER_BY_VIEW_B.values():
		sitters[picture] = true
	for spread_vertical: bool in [false, true]:
		var instance: EventInstance = await DrawnEvent.stand(t, EventCatalogue.shipped().by_id("cafe_tables"),
				spread_vertical)
		var drawer: RecordingEventDrawer = DrawnEvent.drawer_of(instance)
		var axis := Vector2.DOWN if spread_vertical else Vector2.RIGHT
		# Each table's slice holds its sitter's own layers (`EventScenery`) and, over them, its
		# table on its front; the first two tables are a pair, the second the mirrored chair.
		var sitter_in := {}
		for entry in drawer.draws:
			if entry.kind == &"scenery" and sitters.has(entry.picture) \
					and is_instance_valid(entry.canvas):
				sitter_in[(entry.canvas as Node).get_parent()] = entry
		var tables: Array = []
		for canvas in drawer.canvases():
			for entry in drawer.shown_on(canvas):
				if entry.picture == EventPictures.CAFE_TABLE and sitter_in.has(canvas.get_parent()):
					tables.append([sitter_in[canvas.get_parent()], entry])
		tables.sort_custom(func(a: Array, b: Array) -> bool:
			return RecordingEventDrawer.foot_about(a[1], instance).dot(axis) \
					< RecordingEventDrawer.foot_about(b[1], instance).dot(axis))
		for alternate: bool in [false, true]:
			var what := "%s café chair %s" % ["vertical" if spread_vertical else "horizontal",
					"right" if alternate else "left"]
			var expectation: Array = expected[spread_vertical][int(alternate)]
			var pair: Array = tables[int(alternate)] if tables.size() > int(alternate) else [{}, {}]
			var sitter: Dictionary = pair[0]
			var table: Dictionary = pair[1]
			if sitter.is_empty():
				t.check(false, "%s: a sitter and a table were drawn at it" % what)
				continue
			# The chair is where the sitter stands before the lift up the screen.
			var chair := RecordingEventDrawer.foot_about(sitter, instance) - Vector2(0.0, -7.0)
			var toward := RecordingEventDrawer.foot_about(table, instance) - chair
			t.check((expectation[0] as Vector2).dot(toward) > 0.0,
					"%s points toward its table (the table %s from the chair)" % [what, toward])
			var view: String = expectation[1]
			var sitter_picture: String = sitter.picture
			t.check(sitter_picture == EventPictures.CAFE_SITTER_BY_VIEW[view]
					or sitter_picture == EventPictures.CAFE_SITTER_BY_VIEW_B[view],
					"%s uses the %s view (drew %s)" % [what, view, sitter_picture.get_file()])
			t.check(sitter.mirrored == expectation[2],
					"%s mirrors only its west-facing side view" % what)
		instance.free()

## A roadworks panel stays upright when an east-west street lays the spread down local Y. The
## directional source carries the red event-barrier palette in that projection; the closure's
## amber panel is a different object and is not substituted here.
func _test_roadwork_barrier_has_an_upright_vertical_source(t: TestRunner) -> void:
	var horizontal := EventPictures.BARRIER_SEGMENT
	var vertical := EventPictures.BARRIER_SEGMENT_VERTICAL
	t.check(EventPictures.roadwork_segment_texture(false) == horizontal,
			"north-south roadworks uses the broad panel source")
	t.check(EventPictures.roadwork_segment_texture(true) == vertical,
			"east-west roadworks uses the upright panel source")
	# The sizes come from the baked region table (`AtlasTable.baked().native_size()`, which answers with
	# nothing acquired and no texture loaded), since the panels are region names now rather than
	# textures. A region's size is the source picture's own size, so this is the same projection
	# question it always was.
	var across := EventPictures.native_size(horizontal)
	var upright := EventPictures.native_size(vertical)
	t.check(across.x >= across.y - 1.0,
			"the across panel is the broad projection")
	t.check(upright.y > upright.x,
			"the vertical panel is the upright projection")

## A roadblock stacked down a north-south column draws its own end-on picture rather than the
## broadside one repeated per segment *(2026-09-25: "the barrier is still the sideway view for
## each segment in vertical")*. It is picked by the spread's axis the way the roadworks barrier's
## is, and it is the roadblock's own picture, not the roadworks one's.
func _test_roadblock_barrier_is_end_on_down_a_column(t: TestRunner) -> void:
	var broadside := EventPictures.ROADBLOCK_SEGMENT
	var end_on := EventPictures.ROADBLOCK_SEGMENT_VERTICAL
	t.check(EventPictures.roadblock_segment_texture(false) == broadside,
			"a roadblock across a north-south street draws the broadside segment")
	t.check(EventPictures.roadblock_segment_texture(true) == end_on,
			"a roadblock stacked down an east-west street draws the end-on segment")
	t.check(end_on != EventPictures.roadwork_segment_texture(true),
			"and it is the roadblock's own end-on picture, not the roadworks barrier's")
	var upright := EventPictures.native_size(end_on)
	t.check(upright.y > upright.x,
			"the end-on segment is the upright projection (%s)" % upright)

## The guards stand beside their barrier, never over it *(2026-09-25: "also the guards are on top
## of the barrier?")*, one on each side (*"have one guard on each side?"*): on both street axes,
## each one's whole standing picture is outside the whole of the barrier's drawn picture, on his
## own side of it, facing out from it towards where she would come from. A roadblock drawn on
## either axis with a recording drawer handed in gives both: the band's segments and end posts on
## its slices, and the posted guards on its band.
func _test_roadblock_guard_stands_clear_of_the_band(t: TestRunner) -> void:
	var def := EventCatalogue.shipped().by_id("roadblock")
	for vertical: bool in [false, true]:
		var axis := "end-on" if vertical else "broadside"
		var instance: EventInstance = await DrawnEvent.stand(t, def, vertical)
		var band := _drawn_band(instance)
		t.check(band.size.x > 0.0 and band.size.y > 0.0,
				"%s, the barrier has a picture to stand clear of (%s)" % [axis, band])
		var guards: Array[Dictionary] = []
		for entry in DrawnEvent.drawer_of(instance).shown():
			if EventPictures.GUARD_STANDING_BY_VIEW.values().has(entry.picture):
				guards.append(entry)
		for side: int in [-1, 1]:
			var on_his_side: Array[Dictionary] = []
			for entry in guards:
				var foot := RecordingEventDrawer.foot_about(entry, instance)
				if signf(foot.x if vertical else foot.y) == signf(side):
					on_his_side.append(entry)
			t.check(on_his_side.size() == 1,
					"%s, side %d: one guard is drawn standing on that side of the band (%d)"
					% [axis, side, on_his_side.size()])
			if on_his_side.size() != 1:
				continue
			var guard := RecordingEventDrawer.rect_about(on_his_side[0], instance)
			t.check(not guard.intersects(band),
					"%s, side %d: the guard's picture %s is clear of the barrier's %s"
					% [axis, side, guard, band])
			# Facing out from it: the view and the mirror a heading pointing away from the band
			# picks for him.
			var feet := RecordingEventDrawer.foot_about(on_his_side[0], instance)
			var heading := EventFootprints.guard_post_heading(vertical, side)
			var sector := EightDirection.nearest(heading)
			var view: String = EventPictures.EIGHT_VIEW_BY_SECTOR[sector]
			var guard_picture: String = on_his_side[0].picture
			t.check(heading.dot(feet) > 0.0
					and guard_picture == EventPictures.GUARD_STANDING_BY_VIEW[view]
					and on_his_side[0].mirrored == EightDirection.is_mirrored(sector),
					"%s, side %d: facing out from it (%s, drawn %s%s)" % [axis, side, heading,
						guard_picture.get_file(), " mirrored" if on_his_side[0].mirrored else ""])
		instance.free()
	# The one who gives chase is the one on her side, across the band; level with its line, south.
	t.check(EventFootprints.guard_side_toward(false, Vector2(30.0, -200.0)) == -1
			and EventFootprints.guard_side_toward(false, Vector2(-30.0, 200.0)) == 1
			and EventFootprints.guard_side_toward(true, Vector2(-200.0, 30.0)) == -1
			and EventFootprints.guard_side_toward(true, Vector2(200.0, -30.0)) == 1,
			"the chaser is the guard on whichever side of the band she is, across it")
	t.check(EventFootprints.guard_side_toward(false, Vector2(170.0, 0.0)) == 1,
			"and level with the band's own line it is the camera-facing south")

## **The barrier's picture covers the ground its body closes, on both axes, and no more.**
## *(2026-09-25: "only the barrier doesn't actually reach the full width/height is that
## intentional?")* Along the run, the repeated segments reach from one end of the body to the
## other — the body's own reach along its spine, `obstructs_within()` — broadside across the picture
## and end-on up it, where a segment standing on its middle would put the whole column half a
## segment up the screen from its own ground. Asked of the roadblock and of the roadworks barrier,
## the two rows that draw a capped band through `_draw_spread()`, each drawn with a recording
## drawer handed in.
func _test_a_spread_covers_the_ground_its_body_closes(t: TestRunner) -> void:
	for id: String in ["roadblock", "construction"]:
		var def := EventCatalogue.shipped().by_id(id)
		for vertical: bool in [false, true]:
			var what := "%s %s" % [id, "end-on" if vertical else "broadside"]
			var picture := EventPictures.roadblock_segment_texture(vertical) if id == "roadblock" \
					else EventPictures.roadwork_segment_texture(vertical)
			var instance: EventInstance = await DrawnEvent.stand(t, def, vertical)
			var span := Rect2()
			var first := true
			for entry in DrawnEvent.drawer_of(instance).shown():
				if entry.picture != picture:
					continue
				var rect := RecordingEventDrawer.rect_about(entry, instance)
				span = rect if first else span.merge(rect)
				first = false
			instance.free()
			var from := span.position.y if vertical else span.position.x
			var to := span.end.y if vertical else span.end.x
			t.check(not first and is_equal_approx(from, -def.obstructs_within())
					and is_equal_approx(to, def.obstructs_within()),
					"%s: the segments run %.1f..%.1f along the run, the body's own %.0f..%.0f"
					% [what, from, to, -def.obstructs_within(), def.obstructs_within()])

## The union of every picture a drawn roadblock's band was drawn in, segments and end posts, about
## the event's origin.
static func _drawn_band(instance: EventInstance) -> Rect2:
	var vertical := instance.runs_vertically()
	var band_pictures := [EventPictures.roadblock_segment_texture(vertical),
			EventPictures.ROADBLOCK_END]
	var union := Rect2()
	var first := true
	for entry in DrawnEvent.drawer_of(instance).shown():
		if not band_pictures.has(entry.picture):
			continue
		var rect := RecordingEventDrawer.rect_about(entry, instance)
		union = rect if first else union.merge(rect)
		first = false
	return union

# ------------------------------------------------------------------- the tables ---

func _test_family_dictionaries_are_complete(t: TestRunner) -> void:
	for name: String in FAMILY_DICTS:
		var by_view: Dictionary = FAMILY_DICTS[name]
		for view in EXPECTED_VIEW:
			t.check(by_view.has(view) and by_view[view] != null,
					"%s has a resolving %s view" % [name, view])

## The people families' five views are freshly authored rather than reusing an old flat picture —
## `busker.svg` and `busker_side.svg` differ on disk, unlike the animal and vehicle families above —
## so a copy-paste that preloaded one file under two keys would otherwise pass unnoticed.
func _test_people_views_are_five_distinct_pictures(t: TestRunner) -> void:
	var people := FAMILY_DICTS.keys().filter(func(name: String) -> bool:
		return not ANIMAL_SIDE_REUSE.has(name) and not VEHICLE_SIDE_REUSE.has(name))
	for name: String in people:
		var by_view: Dictionary = FAMILY_DICTS[name]
		var textures := by_view.values()
		for i in textures.size():
			for j in range(i + 1, textures.size()):
				t.check(textures[i] != textures[j],
						"%s's own five views are five different pictures" % name)

## The vehicle families' front, back and two diagonals are freshly authored even though their side
## view reuses an existing canonical source — checked separately from the "people" set above so a
## copy-paste of, say, `DELIVERY_VAN_FRONT` under the `DELIVERY_VAN_BACK` key would not pass
## unnoticed either.
func _test_vehicle_views_are_five_distinct_pictures(t: TestRunner) -> void:
	for name: String in VEHICLE_SIDE_REUSE:
		var by_view: Dictionary = FAMILY_DICTS[name]
		var textures := by_view.values()
		for i in textures.size():
			for j in range(i + 1, textures.size()):
				t.check(textures[i] != textures[j],
						"%s's own five views are five different pictures" % name)

## Two states sharing a view name must never be the same asset, or the state a player is meant to
## read at a glance — crouched against running, waiting against lunging, strolling against talking,
## wings up against wings down — is invisible.
func _test_state_pairs_stay_visually_distinct(t: TestRunner) -> void:
	var pairs := [
		["cat_crouched", "cat_running"], ["robber_waiting", "robber_lunging"],
		["chatting_mother_walking", "chatting_mother_talking"], ["pigeon", "pigeon_down"],
		["guard_standing", "guard_lunging"],
		# Every charger's three stages, each distinct from its neighbours *(velvet-marten, #699:
		# "neutral (with neutral visuals), warning (...needs to be visually distinct), and then the
		# actual charging")*.
		["charging_dog_resting", "charging_dog_alert"], ["charging_dog_alert", "charging_dog"],
		["charging_dog_resting", "charging_dog"],
		["robber_waiting", "robber_alert"], ["robber_alert", "robber_lunging"],
		["robber_waiting", "robber_alert_b"], ["robber_alert_b", "robber_lunging"],
		["guard_standing", "guard_alert"], ["guard_alert", "guard_lunging"],
		["policeman_waiting", "policeman_alert"], ["policeman_alert", "policeman_lunging"],
	]
	for pair: Array in pairs:
		var a: Dictionary = FAMILY_DICTS[pair[0]]
		var b: Dictionary = FAMILY_DICTS[pair[1]]
		for view in EXPECTED_VIEW:
			t.check(a[view] != b[view],
					"%s and %s draw different pictures for the %s view" % [pair[0], pair[1], view])

# ------------------------------------------------------------------- fresh placement ---

## `setup()` resets `_view_sector` to the exact nearest sector for the instance's own siting —
## `EightDirection.nearest()`'s own "no prior-view hold on a fresh placement" rule — rather than
## leaving a stale hold from whatever the field's zero-value default happens to be.
func _test_setup_resets_the_view_to_the_exact_siting(t: TestRunner) -> void:
	var sited: Array[EventInstance] = []
	for sector in range(8):
		sited.append(DrawnEvent.build(t, EventCatalogue.shipped().by_id("busker"), false, null, null,
				Vector2.ZERO, _heading_for_sector(sector)))
	await DrawnEvent.frames(t)
	for sector in range(8):
		var instance := sited[sector]
		# He stands as layers of his own on the event (`EventScenery`), built for his view's first
		# frame and mirrored as the view is, so his strum swaps one arm and nothing else.
		var drawn_as := {}
		for entry in DrawnEvent.drawer_of(instance).draws:
			if entry.kind == &"scenery" and is_instance_valid(entry.canvas) \
					and (entry.canvas as Node).get_parent() == instance:
				drawn_as = entry
		var view := EXPECTED_VIEW[sector]
		t.check(not drawn_as.is_empty()
				and [EventPictures.BUSKER_BY_VIEW[view], EventPictures.BUSKER_BY_VIEW_B[view]]
						.has(drawn_as.picture)
				and drawn_as.mirrored == EXPECTED_MIRRORED[sector],
				"a fresh siting at %d degrees starts on sector %d, drawn as the %s view"
						% [sector * 45, sector, view])
		instance.free()

# ------------------------------------------------------------------- targeted facing ---

## "A stationary actor whose action has a target faces that target": the waiting robber has not
## noticed her yet (`is_waiting()` stays true — `EventPursuit` only turns `_heading` toward her once
## she is inside `EventDef.notice_within()`), but a man only watching the street is worth
## nothing next to a man watching *her*, so `robber_waiting_heading()` asks the event for the
## line to her (`sight_line_to_her()`).
func _test_robber_waiting_faces_her(t: TestRunner) -> void:
	var def := EventCatalogue.shipped().by_id("alley_robbery")
	var instance := FakeEvent.new()
	instance.waiting = true
	var look := instance.look_for(def)
	for sector in range(8):
		# The line to her runs toward each sector from just outside `EventDef.notice_within()`
		# (180px), the length a real waiting robber answers with her there and nothing built
		# between: the waiting posture's own facing, not the notice turning `_heading` for it.
		instance.line_to_her = _heading_for_sector(sector) * (def.notice_within() + 40.0)
		var heading := look.robber_waiting_heading()
		var view := look.select_view(heading)
		t.check(view == EXPECTED_VIEW[sector],
				"waiting toward sector %d faces the %s view (got %s)"
				% [sector, EXPECTED_VIEW[sector], view])
	instance.free()

func _test_robber_waiting_falls_back_to_its_siting_with_no_player(t: TestRunner) -> void:
	var def := EventCatalogue.shipped().by_id("alley_robbery")
	var instance := FakeEvent.new()
	instance.waiting = true
	instance.heading = _heading_for_sector(6)
	var look := instance.look_for(def)
	t.check(look.robber_waiting_heading() == instance.facing_now(),
			"with nothing to face, the waiting posture keeps the site's own authored facing")
	instance.free()

# ------------------------------------------------------------------- state predicates ---

func _test_cat_state_predicate_selects_the_telegraph_posture(t: TestRunner) -> void:
	var def := EventCatalogue.shipped().by_id("cat_dash")
	var instance := EventInstance.new()
	instance.setup(def, Vector2.ZERO)
	t.check(instance.is_telegraphing(), "a cat starts in its crouch")
	for i in int(round((def.telegraphs_for() + 0.05) / STEP)):
		instance.step(STEP)
	t.check(not instance.is_telegraphing(), "and is running once the telegraph ends")
	instance.free()

func _test_chatting_mother_state_predicate_selects_the_conversation_posture(t: TestRunner) -> void:
	var def := EventCatalogue.shipped().by_id("chatting_mother")
	var instance := EventInstance.new()
	instance.setup(def, Vector2.ZERO)
	t.check(not instance.is_chatting(), "she is only strolling until spoken to")
	instance.start_chat()
	t.check(instance.is_chatting(), "and talking for the length of the conversation")
	instance.free()

## **The masked man on the escape's stairs is drawn lunging from the tick he comes** *(minty-dolphin
## #852: "The stair guard can become a charger that is triggered by a location if necessary")*: a
## place on the stairwell sets him off and his warning is his badge before he exists
## (`SetOffWatch`), so he comes with his telegraph spent, running, and has no wait or notice to be
## drawn standing through. Created as `EventStreaming.set_off()` creates him.
func _test_masked_man_is_drawn_lunging_from_the_tick_he_comes(t: TestRunner) -> void:
	var def := EventCatalogue.shipped().by_id("masked_pursuer")
	var instance_where := WhereSheIs.nowhere()
	var instance := EventInstance.new()
	instance.setup(def, Vector2.ZERO, PackedVector2Array([Vector2.ZERO, Vector2(0.0, -600.0)]),
			Vector2.RIGHT, EventSurroundings.new().reading(EventCatalogue.shipped()).hearing(instance_where) \
				.drawing_through(DrawnEvent.recording(instance, RecordingEventDrawer.new())))
	instance.arrive_from_its_warning()
	instance.restore(EventSave.aged(EventSpawner.age_when_warned(def)))
	instance_where.tell(Vector2(0.0, -400.0))
	var lunging := true
	for i in int(round(1.0 / STEP)):
		instance.step(STEP)
		lunging = lunging and not instance.is_waiting() and not instance.is_telegraphing() \
				and await _drawn_from(t, instance, [EventPictures.GUARD_LUNGING_BY_VIEW])
	t.check(lunging, "from the tick he comes he is drawn lunging up his line")
	instance.free()

# ----------------------------------------------------------- every charger's three stages ---
# *(velvet-marten, #699: "entities that charge towards the player when the player gets too close need
# three stages: neutral (with neutral visuals), warning (...), and then the actual charging";
# polite-toad, #722: "a distinct alert and rest post for each charger that gets triggered by the
# player"; inbox #748: "robber can walk towards her but guards should lift their hand in warning",
# "nobody walks -- only the robber".)* Each test walks one charger through its stages and pins the
# pictures it is drawn with after a drawn frame (the charging dog's and the roadblock guard's through
# a recording drawer, and for the men on foot what a recording drawer is asked for), and whether it
# moves while it warns.

## Steps `instance` for `seconds` with her held at `her`.
func _hold(instance: EventInstance, where: WhereSheIs, her: Vector2, seconds: float) -> void:
	where.tell(her)
	for i in int(round(seconds / STEP)):
		instance.step(STEP)

## `def` standing at the origin in the tree, drawn through a recording drawer by the frames the caller
## lets pass (`_stood_pictures()`); the caller frees it.
func _drawn_at_the_origin(t: TestRunner, def: EventDef, where: WhereSheIs) -> EventInstance:
	return DrawnEvent.build(t, def, false, null, null, Vector2.ZERO, Vector2.RIGHT, where)

## The pictures `instance` is drawn with on its own canvas once drawn frames have passed: what its
## look asked its drawer to stand.
func _stood_pictures(t: TestRunner, instance: EventInstance) -> Array[String]:
	await DrawnEvent.frames(t)
	var found: Array[String] = []
	for entry in DrawnEvent.shown(instance):
		if entry.canvas == instance and entry.kind == &"stand":
			found.append(entry.picture)
	return found

## The pictures `instance` is drawn with on its own canvas once drawn frames have passed, for a
## look that paints them at an anchor (the checkpoint hut and its guard).
func _painted_pictures(t: TestRunner, instance: EventInstance) -> Array[String]:
	await DrawnEvent.frames(t)
	var found: Array[String] = []
	for entry in DrawnEvent.shown(instance):
		if entry.canvas == instance and entry.kind == &"paint":
			found.append(entry.picture)
	return found

## Whether `pictures` are some, and only, of the views in `by_view` and `also_by_view` (a picture
## table's own frames, such as the stride frame beside the standing one).
func _is_drawn_from(pictures: Array[String], by_view: Dictionary, also_by_view := {}) -> bool:
	return not pictures.is_empty() and pictures.all(func(picture: String) -> bool:
			return by_view.values().has(picture) or also_by_view.values().has(picture))

func _test_the_waiting_dog_rests_stands_alert_and_gallops(t: TestRunner) -> void:
	var def := EventCatalogue.shipped().by_id("charging_dog").for_day(Tuning.RUN_TAUGHT_DAY + 1)
	var instance_where := WhereSheIs.nowhere()
	var instance := _drawn_at_the_origin(t, def, instance_where)
	_hold(instance, instance_where, Vector2(def.notice_within() + 60.0, 0.0), 1.0)
	var pictures := await _stood_pictures(t, instance)
	t.check(instance.is_waiting() and _is_drawn_from(pictures, EventPictures.CHARGING_DOG_RESTING_BY_VIEW),
			"waiting for her, the dog sits, with no stride frame")
	# Inside its radius, where she stands through its warning.
	var standoff := PursuitSpec.standoff(def.chase_speed(), def.standoff_reach())
	var her := Vector2((def.notice_within() + standoff) * 0.5, 0.0)
	_hold(instance, instance_where, her, STEP)
	t.check(instance.is_standing_for_its_notice(), "it notices her and stands for its notice")
	t.check(instance.facing_now().is_equal_approx(her.normalized()), "turned to face her")
	var still := true
	var alert := true
	var warning_steps := int(round(def.pursuit().warns_for() / STEP)) - 3
	for i in warning_steps:
		instance.step(STEP)
		still = still and instance.global_position.is_equal_approx(Vector2.ZERO) \
				and not instance.gait_is_moving()
		# Drawn at the start, the middle and the end of its warning.
		if i == 0 or i * 2 == warning_steps or i == warning_steps - 1:
			alert = alert and _is_drawn_from(await _stood_pictures(t, instance),
					EventPictures.CHARGING_DOG_ALERT_BY_VIEW)
	t.check(alert, "its alert, a still picture, through its warning")
	t.check(still, "and it does not move toward her while it warns")
	# Back out of its radius it sits again, and warns again when she comes back.
	_hold(instance, instance_where, Vector2(def.notice_within() + 10.0, 0.0), STEP)
	pictures = await _stood_pictures(t, instance)
	t.check(instance.is_waiting() and _is_drawn_from(pictures, EventPictures.CHARGING_DOG_RESTING_BY_VIEW),
			"out of its radius again, it sits")
	_hold(instance, instance_where, her, STEP)
	t.check(_is_drawn_from(await _stood_pictures(t, instance), EventPictures.CHARGING_DOG_ALERT_BY_VIEW),
			"and back inside, it warns again")
	_hold(instance, instance_where, her, def.pursuit().warns_for() + 0.2)
	# Galloping it draws both stride frames, one after the other, and only those.
	var first_frame := false
	var second_frame := false
	var gallop := not instance.is_telegraphing()
	for i in 40:
		pictures = await _stood_pictures(t, instance)
		gallop = gallop and _is_drawn_from(pictures, EventPictures.CHARGING_DOG_BY_VIEW,
				EventPictures.CHARGING_DOG_BY_VIEW_B)
		first_frame = first_frame or _is_drawn_from(pictures, EventPictures.CHARGING_DOG_BY_VIEW)
		second_frame = second_frame or _is_drawn_from(pictures, EventPictures.CHARGING_DOG_BY_VIEW_B)
		_hold(instance, instance_where, her, 3.0 * STEP)
	t.check(gallop and first_frame and second_frame,
			"once its warning has run with her still inside it gallops, both frames")
	instance.free()

## **The day-3 dog's telegraph is its approach**, so it is drawn galloping at her for all of it and
## never stands: the same row handed to the director with no trigger to have waited behind.
func _test_the_day_3_dog_gallops_through_its_approach(t: TestRunner) -> void:
	var def := EventCatalogue.shipped().by_id("charging_dog")
	t.check(def.notice_within() <= 0.0, "on the teaching day the dog does not wait")
	var instance_where := WhereSheIs.nowhere()
	var instance := _drawn_at_the_origin(t, def, instance_where)
	_hold(instance, instance_where, Vector2(400.0, 0.0), 1.0)
	t.check(instance.is_telegraphing() and not instance.is_standing_for_its_notice(),
			"its approach is its telegraph, and it does not stand for it")
	t.check(_is_drawn_from(await _stood_pictures(t, instance), EventPictures.CHARGING_DOG_BY_VIEW,
			EventPictures.CHARGING_DOG_BY_VIEW_B), "drawn galloping")
	t.check(instance.global_position.x > 100.0, "and coming (%.0fpx in a second)"
			% instance.global_position.x)
	instance.free()

func _test_the_robber_waits_walks_alert_and_lunges(t: TestRunner) -> void:
	var def := EventCatalogue.shipped().by_id("alley_robbery")
	var instance_where := WhereSheIs.nowhere()
	var instance := EventInstance.new()
	instance.setup(def, Vector2.ZERO, PackedVector2Array(), Vector2.RIGHT,
			EventSurroundings.new().reading(EventCatalogue.shipped()).hearing(instance_where) \
				.drawing_through(DrawnEvent.recording(instance, RecordingEventDrawer.new())))
	_hold(instance, instance_where, Vector2(def.notice_within() + 40.0, 0.0), 0.5)
	t.check(instance.is_waiting() and await _drawn_from(t, instance, [EventPictures.ROBBER_WAITING_BY_VIEW]),
			"waiting, hood up and hands in his coat")
	var her := Vector2(def.notice_within() - 4.0, 0.0)
	_hold(instance, instance_where, her, STEP)
	t.check(instance.is_telegraphing() and not instance.is_standing_for_its_notice(),
			"he notices her, and he does not stand for it")
	t.check(await _drawn_from(t, instance, [EventPictures.ROBBER_ALERT_BY_VIEW]),
			"drawn in his alert, hands out of his coat, on its first frame before he has moved")
	# **His alert is a walk, two frames on his stride** (`gait_is_stepping()`): walking at her slowly
	# through his notice he shows both, and nothing but his alert, until he lunges.
	var alert_frames := {}
	var other := 0
	while instance.is_telegraphing():
		_hold(instance, instance_where, her, STEP)
		if not instance.is_telegraphing():
			break
		if await _drawn_from(t, instance, [EventPictures.ROBBER_ALERT_BY_VIEW]):
			alert_frames["a"] = true
		elif await _drawn_from(t, instance, [EventPictures.ROBBER_ALERT_BY_VIEW_B]):
			alert_frames["b"] = true
		else:
			other += 1
	t.check(instance.global_position.x > 30.0,
			"walking at her through his notice (%.1fpx)" % instance.global_position.x)
	t.check(alert_frames.size() == 2 and other == 0,
			"his alert walk shows both its frames (%s) and nothing else (%d frames)"
			% [", ".join(alert_frames.keys()), other])
	_hold(instance, instance_where, her, def.telegraphs_for())
	t.check(not instance.is_telegraphing()
			and await _drawn_from(t, instance, [EventPictures.ROBBER_LUNGING_BY_VIEW, EventPictures.ROBBER_LUNGING_BY_VIEW_B]),
			"once his slow walk has brought her inside his stand-off he lunges")
	instance.free()
	# **She steps back out of his radius while he walks: he stops where he is and waits** *(inbox
	# #764 in minty-lemur, the player: the robber walking slowly stops if she gets out of the radius)*, drawn
	# waiting, and warns again when she comes back in.
	var walker_where := WhereSheIs.nowhere()
	var walker := EventInstance.new()
	walker.setup(def, Vector2.ZERO, PackedVector2Array(), Vector2.RIGHT,
			EventSurroundings.new().reading(EventCatalogue.shipped()).hearing(walker_where) \
				.drawing_through(DrawnEvent.recording(walker, RecordingEventDrawer.new())))
	_hold(walker, walker_where, her, 0.5)
	var stopped_at := walker.global_position
	t.check(walker.is_telegraphing() and stopped_at.x > 10.0,
			"he has walked %.1fpx at her" % stopped_at.x)
	var out := stopped_at + Vector2(def.notice_within() + 4.0, 0.0)
	_hold(walker, walker_where, out, 1.0)
	t.check(walker.is_waiting() and await _drawn_from(t, walker, [EventPictures.ROBBER_WAITING_BY_VIEW]),
			"out of his radius he waits again, hood up")
	t.close_to(walker.global_position.distance_to(stopped_at), 0.0,
			"where he had walked to, not back at his post", 0.5)
	_hold(walker, walker_where, stopped_at + Vector2(def.notice_within() - 4.0, 0.0), STEP)
	t.check(walker.is_telegraphing() and await _drawn_from(t, walker, [EventPictures.ROBBER_ALERT_BY_VIEW]),
			"and back inside it he warns again")
	walker.free()
	# The sent robber arrives chasing, with no notice to be alert through.
	var sent_where := WhereSheIs.nowhere()
	var sent := EventInstance.new()
	sent.setup(EventCatalogue.shipped().by_id("robber_giving_chase"), Vector2.ZERO, PackedVector2Array(),
			Vector2.RIGHT,
			EventSurroundings.new().reading(EventCatalogue.shipped()).hearing(sent_where) \
				.drawing_through(DrawnEvent.recording(sent, RecordingEventDrawer.new())))
	_hold(sent, sent_where, Vector2(300.0, 0.0), STEP)
	t.check(not await _drawn_from(t, sent, [EventPictures.ROBBER_ALERT_BY_VIEW]),
			"the robber a task sends is drawn coming from his first frame")
	sent.free()

func _test_the_roadblock_guard_raises_his_hand_at_his_post(t: TestRunner) -> void:
	var hot := EventCatalogue.shipped().heated(EventCatalogue.shipped().by_id("roadblock"), EventDef.HEAT_HUNTS_LEVEL)
	var guard_where := WhereSheIs.nowhere()
	var guard := _drawn_at_the_origin(t, hot, guard_where)
	var her := Vector2(0.0, hot.notice_within() - 10.0)
	_hold(guard, guard_where, her, STEP)
	t.check(not guard.global_position.is_equal_approx(guard.body_position())
			and guard.is_standing_for_its_notice(),
			"the guard on her side has noticed her and stands for his notice")
	t.check(_is_drawn_from(await _stood_pictures(t, guard), EventPictures.GUARD_ALERT_BY_VIEW), "hand raised")
	var post := guard.global_position
	_hold(guard, guard_where, her, hot.pursuit().warns_for() - 0.2)
	t.check(guard.global_position.is_equal_approx(post)
			and _is_drawn_from(await _stood_pictures(t, guard), EventPictures.GUARD_ALERT_BY_VIEW),
			"at his post, hand raised, through his warning")
	# Out of his radius he waits at the band's centre again (that both posts are manned and the body
	# is under him is `tests/test_event_barrier_post.gd`'s).
	_hold(guard, guard_where, Vector2(0.0, hot.notice_within() + 10.0), STEP)
	t.check(guard.is_waiting()
			and guard.global_position.is_equal_approx(Vector2.ZERO),
			"out of his radius he waits at the band's centre again")
	_hold(guard, guard_where, her, STEP)
	t.check(guard.is_standing_for_its_notice()
			and _is_drawn_from(await _stood_pictures(t, guard), EventPictures.GUARD_ALERT_BY_VIEW),
			"and back inside it he raises his hand again")
	_hold(guard, guard_where, her, hot.pursuit().warns_for() + 0.2)
	t.check(not guard.is_telegraphing()
			and _is_drawn_from(await _stood_pictures(t, guard), EventPictures.GUARD_LUNGING_BY_VIEW),
			"then, his warning run with her still inside his radius, he lunges")
	guard.free()

func _test_the_door_guard_raises_his_hand_at_the_hut_and_charges_at_once(t: TestRunner) -> void:
	# The warning is the hut's guard's, drawn from her crossing of the door's line
	# (`EventInstance.is_its_guard_warning()`, raised by
	# `CheckpointController.warn_at_the_doors()`); the man set on her once it has run with her still across charges from his first frame
	# (`PursuitSpec.Start.CHARGES_AT_ONCE`).
	var def := EventCatalogue.shipped().by_id("door_guard")
	t.check(def.starts_by(PursuitSpec.Start.CHARGES_AT_ONCE) and is_zero_approx(def.telegraphs_for()),
			"the door guard owes no notice of his own")
	var guard_where := WhereSheIs.nowhere()
	var guard := EventInstance.new()
	guard.setup(def, Vector2(32.0, 80.0), PackedVector2Array(), Vector2.RIGHT,
			EventSurroundings.new().reading(EventCatalogue.shipped()).hearing(guard_where) \
				.drawing_through(DrawnEvent.recording(guard, RecordingEventDrawer.new())))
	_hold(guard, guard_where, Vector2(1.0, 0.0), STEP)
	t.check(not guard.is_telegraphing() and not guard.is_standing_for_its_notice()
			and await _drawn_from(t, guard, [EventPictures.GUARD_LUNGING_BY_VIEW]),
			"set on her, he lunges from his first frame")
	guard.free()
	var hut := _drawn_at_the_origin(t, EventCatalogue.shipped().by_id("checkpoint_hut"),
			WhereSheIs.nowhere())
	var alert: String = EventPictures.GUARD_ALERT_BY_VIEW["front"]
	var resting := await _painted_pictures(t, hut)
	t.check(resting.has(EventPictures.GUARD_STANDING) and not resting.has(alert),
			"the hut's guard stands with his hands down until a crossing warns her")
	hut.raise_its_guards_hand(true)
	var warning := await _painted_pictures(t, hut)
	t.check(warning.has(alert) and not warning.has(EventPictures.GUARD_STANDING),
			"and draws his raised hand to warn her once it does")
	hut.free()

## **The man a vehicle lets out raises his hand and stands still, then charges.** *(Inbox #764 in minty-lemur, the
## player: van guardsmen about to charge hold up their hands; events that spawn with the sole purpose
## of charging show an indicator that they are about to, with the same heads-up as off-screen
## chargers.)* Every copy `EventCatalogue.shipped().out_of_the_car()` makes — out of a patrol car or a hunting
## van, the policeman through day 8 and the guardsman from day 9 — stands where he got out in his
## alert (`policeman_alert_*` or `guard_alert_*`) for `Tuning.WARNING_ALONE_MAX` while she walks
## away, and then lunges.
func _test_the_man_out_of_a_vehicle_raises_his_hand_then_charges(t: TestRunner) -> void:
	var day_of := {"policeman_giving_chase": Tuning.REGION_WALL_FIRST_DAY - 1,
			"guardsman_giving_chase": Tuning.REGION_WALL_FIRST_DAY}
	for id: String in day_of.keys():
		for stops: bool in [true, false]:
			var def := EventCatalogue.shipped().out_of_the_car(DaySpec.for_day(day_of[id]), stops)
			var name := "%s out of %s" % [id, "a patrol car" if stops else "a hunting van"]
			t.check(def.pursuit().stands_for_its_notice() and def.starts_by(PursuitSpec.Start.SETS_OFF_BESIDE_HER)
					and is_equal_approx(def.telegraphs_for(), Tuning.WARNING_ALONE_MAX),
					"%s stands for a %.1fs heads-up" % [name, def.telegraphs_for()])
			var alert_pictures := EventPictures.POLICEMAN_ALERT_BY_VIEW \
					if def.picture() == EventDef.Look.POLICEMAN_GIVING_CHASE else EventPictures.GUARD_ALERT_BY_VIEW
			var man_where := WhereSheIs.nowhere()
			var man := EventInstance.new()
			man.setup(def, Vector2(32.0, 0.0), PackedVector2Array(), Vector2.RIGHT,
					EventSurroundings.new().reading(EventCatalogue.shipped()).hearing(man_where) \
						.drawing_through(DrawnEvent.recording(man, RecordingEventDrawer.new())))
			var her := Vector2(0.0, 0.0)
			var still := true
			var alert := true
			for i in int(round((def.telegraphs_for() - 0.05) / STEP)):
				her.x -= Tuning.WALK_SPEED * STEP
				_hold(man, man_where, her, STEP)
				still = still and man.global_position.is_equal_approx(Vector2(32.0, 0.0))
				alert = alert and await _drawn_from(t, man, [alert_pictures])
			t.check(alert, "%s holds his hand raised for the whole heads-up" % name)
			t.check(still, "and stands where he got out while she walks away")
			_hold(man, man_where, her, 0.1)
			t.check(not man.is_telegraphing() and not await _drawn_from(t, man, [alert_pictures]),
					"then he charges")
			man.free()

## Whether `instance`, drawn in a real frame through the recording drawer it was handed before
## `setup()`, as its manager's spawner hands the real one, stands a picture of one of `families`
## (the `EventPictures` view maps, each view to a picture): the instance is in the tree, asked to
## redraw, and what its look asked the drawer for in that draw is read off the drawer, as
## `tests/drawn_event.gd` does, without reading the choice out of the look.
func _drawn_from(t: TestRunner, instance: EventInstance, families: Array) -> bool:
	var drawer := DrawnEvent.drawer_of(instance)
	if not instance.is_inside_tree():
		t.add_child(instance)
	instance.queue_redraw()
	await t.get_tree().process_frame
	for entry in drawer.shown():
		if entry["kind"] != &"stand":
			continue
		for family: Dictionary in families:
			if entry["picture"] in family.values():
				return true
	return false

## **A man who arrives already charging never shows the warning**: the van's guard a task sends and
## the policeman or guardsman a torn poster sends come at her from their first frame, warned of by
## their screen-edge badge alone.
func _test_no_guard_who_arrives_charging_takes_the_alert(t: TestRunner) -> void:
	for id: String in ["van_guard_giving_chase", "policeman_giving_chase", "guardsman_giving_chase"]:
		var def := EventCatalogue.shipped().by_id(id)
		t.check(def.starts_by(PursuitSpec.Start.ARRIVES_CHASING) and not def.pursuit().stands_for_its_notice(),
				"'%s' arrives charging and does not stand for a notice" % id)
		var instance_where := WhereSheIs.nowhere()
		var instance := EventInstance.new()
		instance.setup(def, Vector2.ZERO, PackedVector2Array(), Vector2.RIGHT,
				EventSurroundings.new().reading(EventCatalogue.shipped()).hearing(instance_where) \
					.drawing_through(DrawnEvent.recording(instance, RecordingEventDrawer.new())))
		var alert := false
		for i in int(round(3.0 / STEP)):
			_hold(instance, instance_where, Vector2(0.0, 100.0), STEP)
			alert = alert or await _drawn_from(t, instance,
					[EventPictures.GUARD_ALERT_BY_VIEW, EventPictures.POLICEMAN_ALERT_BY_VIEW])
		t.check(not alert, "'%s' never draws an alert" % id)
		instance.free()

# --------------------------------------------------------------- M108's vehicle item ---
# `EventLook._draw_eight_view()`'s `side_faces_west` parameter, and the per-family binding in
# `draw_body()` that decides it — see that function's own doc comment and
# `docs/evidence/svg-vehicles-2026-09-10/facings.csv`.

## Which catalogue row exercises each vehicle family's own heading source: `fire_truck`,
## `military_convoy` and `police_patrol` are mobile and reach every sector in real play;
## `delivery_van`, `ice_cream_van`, `reversing_lorry` and `abduction` (while idling) never turn away
## from their own fixed siting, and neither does `night_raid`, hot or cold — but `setup()`'s `face`
## argument sets `_heading` and the starting `_view_sector` the same way regardless, so every sector
## is reachable here for the purpose of pinning the table, whether or not the row would ever be
## seen at it in play.
const VEHICLE_DEF_ID := {
	"delivery_van": "delivery_van",
	"fire_engine": "fire_truck",
	"ice_cream_van": "ice_cream_van",
	"lorry": "reversing_lorry",
	"unmarked_van": "abduction",
	"army_truck": "military_convoy",
	"police_car": "police_patrol",
	"riot_van": "night_raid",
}

## Each vehicle family's own mirror per sector (0 E .. 7 NE), transcribed directly from
## `facings.csv`'s own `mirror_x` column rather than re-derived from `EightDirection.is_mirrored()`
## — so a mistake in `_draw_eight_view()`'s `side_faces_west` inversion cannot cancel a mistake
## here. Every family matches `EXPECTED_MIRRORED` exactly except at sectors 0 (E) and 4 (W), which
## invert for the five whose `"side"` picture is authored facing west (`VEHICLE_SIDE_FACES_WEST`),
## `riot_van` among them.
const VEHICLE_MIRROR_BY_SECTOR := {
	"delivery_van": [true, false, false, true, false, true, false, false],
	"fire_engine": [true, false, false, true, false, true, false, false],
	"unmarked_van": [true, false, false, true, false, true, false, false],
	"army_truck": [true, false, false, true, false, true, false, false],
	"ice_cream_van": [false, false, false, true, true, true, false, false],
	"lorry": [false, false, false, true, true, true, false, false],
	"police_car": [false, false, false, true, true, true, false, false],
	"riot_van": [true, false, false, true, false, true, false, false],
}

## The whole binding, per family and per sector: the view `EIGHT_VIEW_BY_SECTOR` names, and the
## mirror `_draw_eight_view()` would actually draw with once `VEHICLE_SIDE_FACES_WEST[name]` is
## applied — checked against `VEHICLE_MIRROR_BY_SECTOR`'s own literal transcription of
## `facings.csv` rather than against the formula under test.
func _test_vehicle_views_match_facings_csv_per_sector(t: TestRunner) -> void:
	for name: String in VEHICLE_SIDE_REUSE:
		var side_faces_west: bool = VEHICLE_SIDE_FACES_WEST[name]
		var expected_mirror: Array = VEHICLE_MIRROR_BY_SECTOR[name]
		var instance := FakeEvent.new()
		var look := instance.look_for(EventCatalogue.shipped().by_id(VEHICLE_DEF_ID[name]))
		for sector in range(8):
			# Started from the opposite sector every time — the same discipline
			# `_test_select_view_holds_and_mirrors` uses — so a pass is never an accident of the
			# previous iteration's hold agreeing with this one.
			look.face(_heading_for_sector((sector + 4) % 8))
			var view := look.select_view(_heading_for_sector(sector))
			var mirror := look.is_mirrored()
			if view == "side" and side_faces_west:
				mirror = not mirror
			t.check(view == EXPECTED_VIEW[sector],
					"%s sector %d selects the %s view (got %s)"
					% [name, sector, EXPECTED_VIEW[sector], view])
			t.check(mirror == expected_mirror[sector],
					"%s sector %d mirrors %s per facings.csv (got %s)"
					% [name, sector, expected_mirror[sector], mirror])
		instance.free()

## `delivery_van` and `ice_cream_van` are always sited facing east — `AT_THE_KERB` never sets
## `EventPlan.faces()` away from its own default — so binding them onto the shared
## eight-view table must still draw exactly the `"side"` view for a fresh siting, the one view
## either row has ever shown.
func _test_kerb_parked_vans_keep_their_axis_chosen_view(t: TestRunner) -> void:
	for name: String in ["delivery_van", "ice_cream_van"]:
		var instance := FakeEvent.new()
		var look := instance.look_for(EventCatalogue.shipped().by_id(name))
		t.check(look.select_view(Vector2.ZERO) == "side",
				"%s's own default east facing still lands on the side view" % name)
		instance.free()

## `reversing_lorry` (`AGAINST_THE_BUILDING`) only ever faces due east or west —
## `RowGround._wants_this_side()` refuses any facing that is not purely horizontal — so its
## front, back and diagonal views are never actually reachable in play; binding it onto the shared
## table must not change that.
func _test_reversing_lorry_only_ever_faces_the_side_view(t: TestRunner) -> void:
	var def := EventCatalogue.shipped().by_id("reversing_lorry")
	for face: Vector2 in [Vector2.RIGHT, Vector2.LEFT]:
		var instance := FakeEvent.new()
		instance.heading = face
		var look := instance.look_for(def)
		t.check(look.select_view(Vector2.ZERO) == "side",
				"reversing_lorry facing %s still lands on the side view" % face)
		instance.free()

## Every front, back and diagonal view's own ground contact — the vehicle's wheels — sits within a
## few pixels of its own canvas's bottom edge, the same edge `Sprites.draw_standing()` places at the
## event's ground point (`_draw_eight_view()` always draws at local `Vector2.ZERO`, the same point
## `_draw_shape_shadow()` centres the row's body shape's own shadow on, with no per-view offset anywhere in
## between). A picture whose ink stopped well short of the bottom would draw the vehicle floating
## above its own shadow. The tolerance is generous on purpose — the fact worth pinning is "close to
## the edge," not any one picture's own last row of pixels; `docs/evidence/svg-vehicles-2026-09-10/
## README.md` puts every family's own tyre contact within 5px of it.
const FOOTPRINT_TOLERANCE_PX := 8.0

func _test_vehicle_views_are_grounded_at_the_canvas_bottom(t: TestRunner) -> void:
	# The pixels come off the baked page rather than out of the authoring SVG: the sources live
	# under `art/`, which the engine ignores, and the page is what the game actually draws.
	var page := AtlasLibrary.new().page_image(EventPictures.ATLAS_GROUP)
	t.check(page != null, "the baked events page reads back as an image")
	if page == null:
		return
	for name: String in VEHICLE_SIDE_REUSE:
		var by_view: Dictionary = FAMILY_DICTS[name]
		for view: String in ["front", "back", "front_diagonal", "back_diagonal"]:
			var picture: String = by_view[view]
			var image := page.get_region(AtlasTable.baked().region_rect(StringName(picture)))
			var bounds := image.get_used_rect()
			t.check(bounds.size.y > 0, "%s's %s view has some ink to measure" % [name, view])
			var ground := bounds.end.y
			# A vehicle that rolls on wheels of its own touches the ground with those: its body
			# rides a bob above them, so the wheels picture is the ground contact being measured.
			var wheels := StringName(picture + "_wheels")
			if AtlasTable.baked().has_region(wheels):
				var wheel_image := page.get_region(AtlasTable.baked().region_rect(wheels))
				ground = maxi(ground, wheel_image.get_used_rect().end.y)
			var gap := image.get_height() - ground
			t.check(gap <= FOOTPRINT_TOLERANCE_PX,
					"%s's %s view grounds within %dpx of its own canvas bottom (got %dpx)"
					% [name, view, FOOTPRINT_TOLERANCE_PX, gap])

## `burst_water_main`'s crater is sunk into the road rather than standing on it, so the player
## asked for no shadow under it — the row's look says whether a shadow goes under its body
## (`LookSpec.casts_a_shadow()`), the question `_draw_body_shadow()` reads, and this pins that
## answer the same way the rest of this file pins one rather than calling a `_draw_*` function
## directly. `fallen_tree` shares the row's single-body geometry (`docs/EVENTS.md`, "Seal
## pictures") and keeps the ordinary shadow, so that answer is the only difference between the two.
func _test_burst_water_main_draws_no_body_shadow(t: TestRunner) -> void:
	t.check(not EventCatalogue.shipped().by_id("burst_water_main").look().casts_a_shadow(),
			"burst_water_main opts out of the body shadow every other seal draws")
	t.check(EventCatalogue.shipped().by_id("fallen_tree").look().casts_a_shadow(),
			"fallen_tree, burst_water_main's same-geometry sibling, keeps the ordinary body shadow")

## **The riot van and the moving van cast one oval per wheel pair, under a body of their own**
## (minty-hedgehog 1): their ground shape is the scene round them (`EventVehicleLook.SCENE_SHAPED`,
## the night raid's disc holding its officers, the moving van's band under its ramp), wider than the
## van, so their shadow is laid under a body read off the picture they are drawn with. The riot van
## at every sector, and the moving van side on and end on, cast two ovals together no wider than the
## picture drawn for that view, where the night raid's scene is wider than the riot van.
func _test_a_scene_shaped_van_casts_its_shadow_under_its_wheels(t: TestRunner) -> void:
	var raid := EventCatalogue.shipped().by_id("night_raid")
	var raid_side := EventPictures.native_size(EventPictures.RIOT_VAN_BY_VIEW["side"]).x
	t.check(_outlines_bounds([raid.ground_shape().shadow_outline(Vector2.ZERO)]).size.x
			> raid_side, "the night raid's scene is wider than the riot van's side picture")
	for sector in range(8):
		var instance := FakeEvent.new()
		instance.heading = Vector2.from_angle(deg_to_rad(sector * 45.0))
		instance.shape = raid.ground_shape()
		var look := instance.look_for(raid)
		var drawn := EventPictures.native_size(
				EventPictures.RIOT_VAN_BY_VIEW[look.select_view(instance.heading)]).x
		var outlines := look.shadow_outlines(Vector2.ZERO)
		var width := _outlines_bounds(outlines).size.x
		t.check(outlines.size() == 2 and width <= drawn,
				"the riot van at sector %d casts two ovals no wider than its %.0fpx picture (%d, %.1fpx)"
				% [sector, drawn, outlines.size(), width])
		instance.free()
	var moving := EventCatalogue.shipped().by_id("moving_van")
	for side_on: bool in [true, false]:
		var instance := FakeEvent.new()
		instance.side_on = side_on
		instance.solid_direction = Vector2.RIGHT if side_on else Vector2.DOWN
		instance.shape = moving.ground_shape()
		var look := instance.look_for(moving)
		var picture := EventPictures.stationary_vehicle_texture(EventDef.Look.MOVING_VAN, side_on)
		var drawn := EventPictures.stationary_vehicle_extent(picture, side_on,
				moving.body().drawn_width()).x
		var outlines := look.shadow_outlines(Vector2.ZERO)
		var width := _outlines_bounds(outlines).size.x
		if not side_on:
			_check_the_end_on_van_stands_on_its_tyres(t, outlines, picture)
		t.check(outlines.size() == 2 and width <= drawn,
				"the moving van %s casts two ovals no wider than its %.0fpx picture (%d, %.1fpx)"
				% ["side on" if side_on else "end on", drawn, outlines.size(), width])
		instance.free()

## The moving van end on is stood on its picture's bottom row, the ramp's foot, `picture`'s height
## below its node, and its rear tyres end rows above it: the nearer oval's middle lies on the row
## its tyres' feet stand on, read off the picture's own source (the lowest edge of its dark tyre
## rectangles), and not the ramp's foot below it.
func _check_the_end_on_van_stands_on_its_tyres(t: TestRunner, outlines: Array[PackedVector2Array],
		picture: String) -> void:
	var source := FileAccess.get_file_as_string("res://art/events/moving_van_vertical.svg")
	var tyre_feet: Array[float] = []
	var tyre := RegEx.create_from_string(
			"<rect x=\"[0-9.]+\" y=\"([0-9.]+)\" width=\"[0-9.]+\" height=\"([0-9.]+)\" fill=\"#221f28\"")
	for found in tyre.search_all(source):
		tyre_feet.append(float(found.get_string(1)) + float(found.get_string(2)))
	t.check(tyre_feet.size() == 2, "the end-on moving van's source draws two rear tyres (%d)" % tyre_feet.size())
	if tyre_feet.size() != 2:
		return
	var picture_height := EventPictures.native_size(picture).y
	var tyre_line: float = float(tyre_feet.max()) - picture_height
	var nearer := -INF
	for outline in outlines:
		nearer = maxf(nearer, _outlines_bounds([outline]).get_center().y)
	t.check(absf(nearer - tyre_line) < 1.0,
			"the end-on moving van's nearer oval lies on the line its tyres stand on (%.1f against %.1f; the ramp's foot is at 0)"
			% [nearer, tyre_line])

## The box round every point of `outlines`.
func _outlines_bounds(outlines: Array[PackedVector2Array]) -> Rect2:
	var bounds := Rect2()
	var first := true
	for outline in outlines:
		for point in outline:
			if first:
				bounds = Rect2(point, Vector2.ZERO)
				first = false
			else:
				bounds = bounds.expand(point)
	return bounds

# ------------------------------------------------------------ the wheels ---

## **Every vehicle that moves rolls on a wheels picture of its own**, one per view, baked on the
## `events` page on exactly its body's canvas — the one size `Sprites.draw_standing()` bottom-centres
## both by — and listed with the look's own sources, so the atlas completeness check covers it. The
## ones drawn under their body name wheels that exist.
func _test_every_moving_vehicle_has_wheels_on_its_own_canvas(t: TestRunner) -> void:
	var looks := {
		EventDef.Look.POLICE_CAR: EventPictures.POLICE_CAR_BY_VIEW,
		EventDef.Look.FIRE_ENGINE: EventPictures.FIRE_ENGINE_BY_VIEW,
		EventDef.Look.UNMARKED_VAN: EventPictures.UNMARKED_VAN_BY_VIEW,
		EventDef.Look.RIOT_VAN: EventPictures.RIOT_VAN_BY_VIEW,
		EventDef.Look.ARMY_TRUCK: EventPictures.ARMY_TRUCK_BY_VIEW,
		EventDef.Look.LORRY: EventPictures.LORRY_BY_VIEW,
	}
	t.check(EventPictures.WHEELS_BY_LOOK.size() == looks.size(),
			"the moving vehicles and nothing else roll on wheels of their own (%d looks)"
			% EventPictures.WHEELS_BY_LOOK.size())
	var named := {}
	for look: EventDef.Look in looks.keys():
		t.check(EventPictures.WHEELS_BY_LOOK.has(look), "look %d has wheels" % look)
		var wheels_by_view: Dictionary = EventPictures.WHEELS_BY_LOOK.get(look, {})
		var body_by_view: Dictionary = looks[look]
		var sources := EventPictures.family_sources(look)
		for view: String in body_by_view.keys():
			var wheels := str(wheels_by_view.get(view, ""))
			var body := str(body_by_view[view])
			named[wheels] = true
			t.check(AtlasTable.baked().has_region(StringName(wheels)),
					"%s's wheels (%s) are baked" % [body, wheels])
			t.check(AtlasTable.baked().native_size(StringName(wheels))
					== AtlasTable.baked().native_size(StringName(body)),
					"%s's wheels share its canvas" % body)
			t.check(wheels in sources, "%s is among its look's own sources" % wheels)
	for wheels: String in EventPictures.WHEELS_BEHIND_THE_BODY:
		t.check(named.has(wheels), "%s, drawn under its body, is one of the wheels tables' own"
				% wheels)
	for parked: EventDef.Look in [EventDef.Look.DELIVERY_VAN, EventDef.Look.ICE_CREAM_VAN]:
		t.check(not EventPictures.WHEELS_BY_LOOK.has(parked),
				"a parked van (look %d) keeps its wheels in its one picture" % parked)

## **A moving vehicle's body rides about a pixel over its wheels, on a phase of ground covered,
## and a stopped one sits still.** A police patrol's look, round an event that covers ground
## each tick (striding, as a real patrol set up on open ground answers on every tick it drove),
## bobs within `WheelBob.HEIGHT` and reaches it, the lift is `WheelBob.lift()` of exactly the
## ground covered, and the redraw key moves with it; round the same event the tick it covers no
## ground (not striding, as a real one answers a tick it stood), the body is back down on its
## wheels.
func _test_a_moving_vehicle_bobs_on_its_wheels_and_a_stopped_one_sits_still(t: TestRunner) -> void:
	var def := EventCatalogue.shipped().by_id("police_patrol")
	var instance := FakeEvent.new()
	instance.travels = true
	instance.approaching_at = def.approach_speed()
	instance.route = PackedVector2Array([Vector2.ZERO, Vector2(2000.0, 0.0)])
	var look := instance.look_for(def)
	var lowest := 0.0
	var keys := {}
	for i in 240:
		instance.tick(STEP, instance.approach_speed() * STEP)
		instance.striding = true
		var bob := look.current_bob()
		t.check(bob <= 0.0 and bob >= -WheelBob.HEIGHT - 0.001,
				"tick %d's bob %.3f stays between the wheels and one height above them" % [i, bob])
		t.check(is_equal_approx(bob, WheelBob.lift(instance.path_travelled())),
				"tick %d's lift is the bob of the ground covered" % i)
		if look.redraw_if_the_picture_changed():
			keys[i] = true
		lowest = minf(lowest, bob)
	t.check(lowest < -0.9 * WheelBob.HEIGHT, "and its body reached the top of a rise (%.3f)" % lowest)
	t.check(lowest > -WheelBob.HEIGHT - 0.001,
			"a rise of about a pixel, not the walkers' own stride bob (%.3f)" % lowest)
	t.check(keys.size() > 2, "the redraw key moved with the body (%d heights)" % keys.size())
	# The tick it covers no ground.
	instance.tick(STEP, 0.0)
	instance.striding = false
	t.check(look.current_bob() == 0.0, "a vehicle that covered no ground sits on its wheels")
	instance.free()

## **Only the vehicles changed.** A dog walker has no wheels, and its bob is still the stride's own
## lift — taller than a vehicle's, since it is a step rather than a sway.
func _test_a_walking_event_keeps_its_stride_bob(t: TestRunner) -> void:
	var def := EventCatalogue.shipped().by_id("dog_walker")
	var instance := FakeEvent.new()
	instance.travels = true
	instance.approaching_at = def.approach_speed()
	instance.route = PackedVector2Array([Vector2.ZERO, Vector2(600.0, 0.0)])
	var look := instance.look_for(def)
	var lowest := 0.0
	for i in 120:
		instance.tick(STEP, instance.approach_speed() * STEP)
		lowest = minf(lowest, look.current_bob())
	t.check(not EventPictures.WHEELS_BY_LOOK.has(def.picture()), "a dog walker has no wheels")
	t.check(lowest < -WheelBob.HEIGHT,
			"its stride lifts it further than a vehicle's body rises (%.3f)" % lowest)
	instance.free()

## **The badge is the thing's own picture, wheels included**: `icon_for()` of a vehicle that rolls
## is its side body, and `icon_wheels_for()` is the side view's wheels the badge draws over it on
## the same canvas; every other look answers nothing, so its badge is one picture as it was.
func _test_a_vehicle_badge_draws_its_wheels(t: TestRunner) -> void:
	for look: EventDef.Look in EventPictures.WHEELS_BY_LOOK.keys():
		var wheels := EventPictures.icon_wheels_for(look)
		var body := EventPictures.icon_for(look)
		t.check(wheels == str((EventPictures.WHEELS_BY_LOOK[look] as Dictionary)["side"]),
				"look %d's badge draws its side view's wheels (%s)" % [look, wheels])
		t.check(AtlasTable.baked().native_size(StringName(wheels)) == AtlasTable.baked().native_size(
				StringName(body)), "and they fit the badge's own rectangle for %s" % body)
	t.check(EventPictures.icon_wheels_for(EventDef.Look.DELIVERY_VAN).is_empty(),
			"a parked van's badge is its one picture")
	t.check(EventPictures.icon_wheels_for(EventDef.Look.DOG_WALKER).is_empty(),
			"and so is everything that does not roll")

## **A spread's end cap is drawn at exactly the width it obstructs, not past it.**
## `SpreadLook._draw_spread`'s own docstring is the contract; the repeated segments already meet
## it, and the cap is the half that used to break it — centred at `±half`, `barrier_end.svg` (6px
## wide) hung 3px past each end of a `construction` barrier's 64px obstruction. A `construction`
## barrier is drawn broadside and end-on with a recording drawer handed in, and the end posts it
## stands are read off what it was told to draw: where each post's feet are, against the real
## asset size and the real `obstructs_within()`, and in which order each slice draws its post and
## its segment.
func _test_a_spread_cap_matches_what_it_obstructs(t: TestRunner) -> void:
	var def := EventCatalogue.shipped().by_id("construction")
	var half := maxf(11.0, def.obstructs_within())
	var cap_size := EventPictures.native_size(EventPictures.BARRIER_END)
	t.check(cap_size.y > cap_size.x * 2.0,
			"the post is an upright picture (%s), so its height and width are different questions"
			% cap_size)
	for vertical: bool in [false, true]:
		var axis := "end-on" if vertical else "broadside"
		var along := Vector2.DOWN if vertical else Vector2.RIGHT
		var instance: EventInstance = await DrawnEvent.stand(t, def, vertical)
		var drawer: RecordingEventDrawer = DrawnEvent.drawer_of(instance)
		var segment := EventPictures.roadwork_segment_texture(vertical)
		# Each slice's draws in its own order, the slices far end first.
		var slices: Array = []
		for canvas in drawer.canvases():
			slices.append(drawer.shown_on(canvas))
		slices.sort_custom(func(a: Array, b: Array) -> bool:
			return _along_of(a, segment, instance, along) < _along_of(b, segment, instance, along))
		var posts: Array[float] = []
		for drawn: Array in slices:
			for entry: Dictionary in drawn:
				if entry.picture == EventPictures.BARRIER_END:
					posts.append(RecordingEventDrawer.foot_about(entry, instance).dot(along))
		posts.sort()
		t.check(posts.size() == 2 and is_equal_approx(posts[0] - cap_size.x * 0.5, -half)
				and is_equal_approx(posts[1] + cap_size.x * 0.5, half),
				"%s, each post's outer edge (%s, %.1f wide) lands on the %.1fpx obstruction, not past it"
				% [axis, posts, cap_size.x, half])
		t.check(posts.size() == 2 and not is_equal_approx(posts[1], half),
				"%s, and it is not simply centred at ±half (%s)" % [axis, posts])
		var first: Array = slices[0]
		var last: Array = slices[slices.size() - 1]
		var before := _posts_drawn(first, segment, true, instance)
		var after := _posts_drawn(last, segment, false, instance)
		if vertical:
			# End-on, the extent along the run is the post's picture height; what it covers of the
			# run is still its width. The near post's feet stand within that width of the barrier's
			# near end — inside the last segment's own slice of ground, which ends at the end of the
			# body — rather than half a post's height in toward the middle.
			var last_segment := _entry_of(last, segment)
			var last_slice_starts := RecordingEventDrawer.rect_about(last_segment, instance) \
					.position.y if not last_segment.is_empty() else INF
			var near := posts[posts.size() - 1] if not posts.is_empty() else 0.0
			t.check(half - near <= cap_size.x and near > last_slice_starts,
					"end-on, the near post stands at the barrier's end (%.1f of %.1f), inside the last"
					% [near, half] + " segment's slice (from %.1f)" % last_slice_starts)
			# A post sorts with its end slice, so draw order within the slice is its only depth.
			# The side drawn behind the board has to be the far end, up the screen, and the near
			# end is the only one drawn over it.
			t.check(before.size() == 1 and before[0].dot(along) < 0.0 and after.size() == 1
					and after[0].dot(along) > 0.0,
					"end-on, the far post is drawn behind the board (%s) and only the near one over it (%s)"
					% [before, after])
		else:
			t.check(before.is_empty() and after.size() == 2,
					"broadside, both posts are drawn over the board (before %s, after %s)"
					% [before, after])
		instance.free()

## Where along the run the slice that drew `drawn` stands: its segment's feet.
static func _along_of(drawn: Array, segment: String, instance: EventInstance,
		along: Vector2) -> float:
	var entry := _entry_of(drawn, segment)
	return RecordingEventDrawer.foot_about(entry, instance).dot(along) if not entry.is_empty() \
			else INF

## The first of `drawn` showing `picture`, or an empty dictionary.
static func _entry_of(drawn: Array, picture: String) -> Dictionary:
	for entry: Dictionary in drawn:
		if entry.picture == picture:
			return entry
	return {}

## The feet, about the event's origin, of the end posts a slice drew before its segment (`behind`)
## or after it.
static func _posts_drawn(drawn: Array, segment: String, behind: bool,
		instance: EventInstance) -> Array[Vector2]:
	var feet: Array[Vector2] = []
	var segment_seen := false
	for entry: Dictionary in drawn:
		if entry.picture == segment:
			segment_seen = true
		elif entry.picture == EventPictures.BARRIER_END and segment_seen != behind:
			feet.append(RecordingEventDrawer.foot_about(entry, instance))
	return feet

## **A whole-scene hard seal spans its obstruction at the ground point.** A `fallen_tree` drawn
## on either axis with a recording drawer handed in: every slice cuts its band out of the one
## whole picture (`EventPictures.wide_scene_texture()`), and that picture spans the row's own
## obstruction along its run.
func _test_a_whole_scene_spans_its_obstruction(t: TestRunner) -> void:
	var tree := EventCatalogue.shipped().by_id("fallen_tree")
	var half := maxf(11.0, tree.obstructs_within())
	for is_vertical: bool in [false, true]:
		var texture := EventPictures.wide_scene_texture(EventDef.Look.FALLEN_TREE, is_vertical)
		var instance: EventInstance = await DrawnEvent.stand(t, tree, is_vertical)
		var drawer: RecordingEventDrawer = DrawnEvent.drawer_of(instance)
		var wholes: Array[Rect2] = []
		for entry in drawer.shown():
			if entry.kind == &"band" and entry.picture == texture:
				wholes.append(RecordingEventDrawer.rect_about(entry, instance))
		var spans := wholes.size() > 1
		for drawn in wholes:
			var from := drawn.position.y if is_vertical else drawn.position.x
			var to := drawn.end.y if is_vertical else drawn.end.x
			spans = spans and is_equal_approx(from, -half) and is_equal_approx(to, half)
		t.check(spans, "'%s' %s body spans the obstruction from -%.0f to %.0f in each of its %d slices"
				% [texture.get_file(), "vertical" if is_vertical else "horizontal", half, half,
					wholes.size()])
		instance.free()
