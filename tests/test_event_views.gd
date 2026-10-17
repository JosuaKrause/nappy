extends RefCounted
## M108, eight-direction entity graphics: binding live event people, animals, riders and vehicles
## to `EightDirection`. `tests/test_walker_views.gd` already pins the selector itself and the crowd
## walker's own wiring; this suite pins the event side of the same convention —
## `EventInstance.EIGHT_VIEW_BY_SECTOR`, `_select_view()`, each family's own `_BY_VIEW` table and
## heading source, and — for the vehicle families at the bottom — `_draw_eight_view()`'s
## `side_faces_west` parameter, the one bit a family's own art rather than its geometry decides.
##
## Consistent with every other suite in this file, nothing here calls a `_draw_*` function
## directly — `Sprites.draw_standing()` and the raw `canvas.draw_*` calls inside them are only
## valid from an actual draw pass, which is why `_protester_texture()` and `_cap_offset()` are the
## existing model: a `_draw_*` function reads a small, directly testable query, and this suite pins
## the query rather than the drawing. The rendered evidence sheets under
## `docs/evidence/m108-event-people-2026-09-11/` and `docs/evidence/m108-event-vehicles-2026-09-11/`
## are what a screenshot answers that a test cannot — see the **verify** skill, "test what a
## screenshot cannot see, screenshot what a test cannot judge."

const STEP := 1.0 / 60.0

## `EightDirection`'s own sector order (0 E .. 7 NE), and the view/mirror `docs/GRAPHICS.md`'s
## mirror convention says each one draws — identical to `CrowdAgent.WALKER_VIEW_BY_SECTOR` and
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
	"person": EventInstance.PERSON_BY_VIEW,
	"yeller": EventInstance.YELLER_BY_VIEW,
	"busker": EventInstance.BUSKER_BY_VIEW,
	"poster_crew": EventInstance.POSTER_CREW_BY_VIEW,
	"poster_crew_square": EventInstance.POSTER_CREW_SQUARE_BY_VIEW,
	"cafe_sitter": EventInstance.CAFE_SITTER_BY_VIEW,
	"van_victim": EventInstance.VAN_VICTIM_BY_VIEW,
	"protester": EventInstance.PROTESTER_BY_VIEW,
	"leaf_blower": EventInstance.LEAF_BLOWER_BY_VIEW,
	"robber_waiting": EventInstance.ROBBER_WAITING_BY_VIEW,
	"robber_lunging": EventInstance.ROBBER_LUNGING_BY_VIEW,
	"robber_alert": EventInstance.ROBBER_ALERT_BY_VIEW,
	"robber_alert_b": EventInstance.ROBBER_ALERT_BY_VIEW_B,
	"chatting_mother_walking": EventInstance.CHATTING_MOTHER_WALKING_BY_VIEW,
	"chatting_mother_talking": EventInstance.CHATTING_MOTHER_TALKING_BY_VIEW,
	"cat_crouched": EventInstance.CAT_CROUCHED_BY_VIEW,
	"cat_running": EventInstance.CAT_RUNNING_BY_VIEW,
	"dog": EventInstance.DOG_BY_VIEW,
	"charging_dog": EventInstance.CHARGING_DOG_BY_VIEW,
	"charging_dog_resting": EventInstance.CHARGING_DOG_RESTING_BY_VIEW,
	"charging_dog_alert": EventInstance.CHARGING_DOG_ALERT_BY_VIEW,
	"cyclist": EventInstance.CYCLIST_BY_VIEW,
	"pelican_cyclist": EventInstance.PELICAN_BY_VIEW,
	"pigeon": EventInstance.PIGEON_BY_VIEW,
	"pigeon_down": EventInstance.PIGEON_DOWN_BY_VIEW,
	"delivery_van": EventInstance.DELIVERY_VAN_BY_VIEW,
	"fire_engine": EventInstance.FIRE_ENGINE_BY_VIEW,
	"ice_cream_van": EventInstance.ICE_CREAM_VAN_BY_VIEW,
	"lorry": EventInstance.LORRY_BY_VIEW,
	"unmarked_van": EventInstance.UNMARKED_VAN_BY_VIEW,
	"army_truck": EventInstance.ARMY_TRUCK_BY_VIEW,
	"police_car": EventInstance.POLICE_CAR_BY_VIEW,
	"riot_van": EventInstance.RIOT_VAN_BY_VIEW,
	"mouse": EventInstance.MOUSE_BY_VIEW,
	"guard_standing": EventInstance.GUARD_STANDING_BY_VIEW,
	"guard_lunging": EventInstance.GUARD_LUNGING_BY_VIEW,
	"guard_alert": EventInstance.GUARD_ALERT_BY_VIEW,
	"policeman_waiting": EventInstance.POLICEMAN_WAITING_BY_VIEW,
	"policeman_alert": EventInstance.POLICEMAN_ALERT_BY_VIEW,
	"policeman_lunging": EventInstance.POLICEMAN_LUNGING_BY_VIEW,
}

## The animal/rider families whose `"side"` entry is required to be the exact pre-existing
## canonical constant rather than a second preload of the same picture — see
## `docs/GRAPHICS.md`'s instruction to replace a preload "only where the suffixed side ... is the
## same picture," and `docs/evidence/svg-vehicles-2026-09-10/facings.csv`, which marks every one of
## these "existing canonical source."
const ANIMAL_SIDE_REUSE := {
	"cat_crouched": EventInstance.CAT_CROUCHED,
	"cat_running": EventInstance.CAT_RUNNING,
	"dog": EventInstance.DOG,
	"charging_dog": EventInstance.CHARGING_DOG,
	"cyclist": EventInstance.CYCLIST,
	"pigeon": EventInstance.PIGEON,
	"pigeon_down": EventInstance.PIGEON_DOWN,
	"mouse": EventInstance.MOUSE,
}

## The vehicle families' own `"side"` entry, same reuse rule as `ANIMAL_SIDE_REUSE` above —
## `facings.csv` marks every one of these "existing canonical source" too, `riot_van` included.
const VEHICLE_SIDE_REUSE := {
	"delivery_van": EventInstance.DELIVERY_VAN,
	"fire_engine": EventInstance.FIRE_ENGINE,
	"ice_cream_van": EventInstance.ICE_CREAM_VAN,
	"lorry": EventInstance.LORRY,
	"unmarked_van": EventInstance.UNMARKED_VAN,
	"army_truck": EventInstance.ARMY_TRUCK,
	"police_car": EventInstance.POLICE_CAR,
	"riot_van": EventInstance.RIOT_VAN,
}

## Which vehicle families' `"side"` view is authored facing west rather than east — the exact
## `side_faces_west` argument `EventInstance._draw_body()` passes to `_draw_eight_view()` for each,
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

func run(t) -> void:
	_test_eight_view_by_sector_matches_convention(t)
	_test_select_view_holds_and_mirrors(t)
	_test_select_view_zero_heading_holds(t)
	_test_cafe_sitters_face_their_own_tables(t)
	_test_roadwork_barrier_has_an_upright_vertical_source(t)
	_test_roadblock_barrier_is_end_on_down_a_column(t)
	_test_roadblock_guard_stands_clear_of_the_band(t)
	_test_a_spread_covers_the_ground_its_body_closes(t)
	_test_roadwork_barrier_follows_alley_axis(t)
	_test_family_dictionaries_are_complete(t)
	_test_animal_side_view_reuses_the_canonical_source(t)
	_test_vehicle_side_view_reuses_the_canonical_source(t)
	_test_people_views_are_five_distinct_pictures(t)
	_test_vehicle_views_are_five_distinct_pictures(t)
	_test_state_pairs_stay_visually_distinct(t)
	_test_setup_resets_the_view_to_the_exact_siting(t)
	_test_robber_waiting_faces_her(t)
	_test_robber_waiting_falls_back_to_its_siting_with_no_player(t)
	_test_robber_lunging_faces_her_through_the_chase(t)
	_test_cat_state_predicate_selects_the_telegraph_posture(t)
	_test_chatting_mother_state_predicate_selects_the_conversation_posture(t)
	_test_masked_man_is_drawn_standing_until_he_goes(t)
	_test_the_waiting_dog_rests_stands_alert_and_gallops(t)
	_test_the_day_3_dog_gallops_through_its_approach(t)
	_test_the_robber_waits_walks_alert_and_lunges(t)
	_test_the_roadblock_guard_raises_his_hand_at_his_post(t)
	_test_the_door_guard_raises_his_hand_where_he_stepped_out(t)
	_test_the_man_out_of_a_vehicle_raises_his_hand_then_charges(t)
	_test_no_guard_who_arrives_charging_takes_the_alert(t)
	_test_vehicle_views_match_facings_csv_per_sector(t)
	_test_riot_van_reproduces_its_octant_table_with_the_corrected_side_mirror(t)
	_test_kerb_parked_vans_keep_their_axis_chosen_view(t)
	_test_reversing_lorry_only_ever_faces_the_side_view(t)
	_test_vehicle_views_are_grounded_at_the_canvas_bottom(t)
	_test_burst_water_main_draws_no_body_shadow(t)
	_test_every_moving_vehicle_has_wheels_on_its_own_canvas(t)
	_test_a_moving_vehicle_bobs_on_its_wheels_and_a_stopped_one_sits_still(t)
	_test_a_walking_event_keeps_its_stride_bob(t)
	_test_a_vehicle_badge_draws_its_wheels(t)

func _heading_for_sector(sector: int) -> Vector2:
	return Vector2.from_angle(deg_to_rad(sector * 45.0))

# ------------------------------------------------------------------- the selector wiring ---

func _test_eight_view_by_sector_matches_convention(t) -> void:
	for sector in range(8):
		t.check(EventInstance.EIGHT_VIEW_BY_SECTOR[sector] == EXPECTED_VIEW[sector],
				"sector %d names the %s view" % [sector, EXPECTED_VIEW[sector]])
		t.check(EightDirection.is_mirrored(sector) == EXPECTED_MIRRORED[sector],
				"sector %d mirrors according to the west convention" % sector)

## `_select_view()` is what every `_draw_*` below reads instead of repeating
## `EightDirection.update()` and the table lookup itself — this pins that wiring once, over all
## eight headings, rather than once per family that calls it.
func _test_select_view_holds_and_mirrors(t) -> void:
	var instance := EventInstance.new()
	instance.setup(EventCatalogue.by_id("busker"), Vector2.ZERO)
	for sector in range(8):
		# Started from the opposite sector every time, so a pass here is never an accident of the
		# previous iteration's hold agreeing with this one.
		instance._view_sector = (sector + 4) % 8
		var view := instance._select_view(_heading_for_sector(sector))
		t.check(view == EXPECTED_VIEW[sector],
				"heading %d degrees selects the %s view (got %s)"
				% [sector * 45, EXPECTED_VIEW[sector], view])
		t.check(EightDirection.is_mirrored(instance._view_sector) == EXPECTED_MIRRORED[sector],
				"sector %d mirror flag matches the west convention" % sector)
	instance.free()

## The one behaviour worth pinning at the wiring level rather than trusting `EightDirection`'s own
## suite to cover by proxy: `_select_view()` passes no idle floor of its own (every heading fed to
## it below is already a unit vector that is never actually zero), so an exactly-zero heading still
## holds through `EightDirection.update()`'s own default threshold — the same "stopped actor keeps
## its last facing" contract the walkers get, reached the same way `Stroller` reaches it.
func _test_select_view_zero_heading_holds(t) -> void:
	var instance := EventInstance.new()
	instance.setup(EventCatalogue.by_id("busker"), Vector2.ZERO)
	instance._view_sector = 0
	var view := instance._select_view(Vector2.ZERO)
	t.check(view == "side" and instance._view_sector == 0,
			"an exactly zero heading holds whatever sector was last drawn")
	instance.free()

## Café sitters use their alternating chair offset to face their own table. The fixed -7px
## screen-depth lift used by `_draw_cafe()` is not part of this bearing: horizontal frontages use
## the two side facings, and vertical frontages use the two upright front/back facings.
func _test_cafe_sitters_face_their_own_tables(t) -> void:
	var expected := {
		false: [[Vector2.RIGHT, "side", false], [Vector2.LEFT, "side", true]],
		true: [[Vector2.DOWN, "front", false], [Vector2.UP, "back", false]],
	}
	for spread_vertical in [false, true]:
		for alternate in [false, true]:
			var heading: Vector2 = EventInstance._cafe_seat_heading(spread_vertical, alternate)
			var sector := EightDirection.nearest(heading)
			var expectation: Array = expected[spread_vertical][int(alternate)]
			t.check(heading == expectation[0],
					"%s café chair %s points toward its table" % ["vertical" if spread_vertical else "horizontal",
						"right" if alternate else "left"])
			t.check(EventInstance.EIGHT_VIEW_BY_SECTOR[sector] == expectation[1],
					"%s café chair %s uses the %s view"
					% ["vertical" if spread_vertical else "horizontal",
						"right" if alternate else "left", expectation[1]])
			t.check(EightDirection.is_mirrored(sector) == expectation[2],
					"%s café chair %s mirrors only its west-facing side view"
					% ["vertical" if spread_vertical else "horizontal",
						"right" if alternate else "left"])

## A roadworks panel stays upright when an east-west street lays the spread down local Y. The
## directional source carries the red event-barrier palette in that projection; the closure's
## amber panel is a different object and is not substituted here.
func _test_roadwork_barrier_has_an_upright_vertical_source(t) -> void:
	var horizontal := EventInstance.BARRIER_SEGMENT
	var vertical := EventInstance.BARRIER_SEGMENT_VERTICAL
	t.check(EventInstance._roadwork_segment_texture(false) == horizontal,
			"north-south roadworks uses the broad panel source")
	t.check(EventInstance._roadwork_segment_texture(true) == vertical,
			"east-west roadworks uses the upright panel source")
	# The sizes come from the baked region table (`AtlasLibrary.native_size()`, which answers with
	# nothing acquired and no texture loaded), since the panels are region names now rather than
	# textures. A region's size is the source picture's own size, so this is the same projection
	# question it always was.
	var across := EventInstance._native_size(horizontal)
	var upright := EventInstance._native_size(vertical)
	t.check(across.x >= across.y - 1.0,
			"the across panel is the broad projection")
	t.check(upright.y > upright.x,
			"the vertical panel is the upright projection")

## A roadblock stacked down a north-south column draws its own end-on picture rather than the
## broadside one repeated per segment *(2026-09-25: "the barrier is still the sideway view for
## each segment in vertical")*. It is picked by the spread's axis the way the roadworks barrier's
## is, and it is the roadblock's own picture, not the roadworks one's.
func _test_roadblock_barrier_is_end_on_down_a_column(t) -> void:
	var broadside := EventInstance.ROADBLOCK_SEGMENT
	var end_on := EventInstance.ROADBLOCK_SEGMENT_VERTICAL
	t.check(EventInstance._roadblock_segment_texture(false) == broadside,
			"a roadblock across a north-south street draws the broadside segment")
	t.check(EventInstance._roadblock_segment_texture(true) == end_on,
			"a roadblock stacked down an east-west street draws the end-on segment")
	t.check(end_on != EventInstance._roadwork_segment_texture(true),
			"and it is the roadblock's own end-on picture, not the roadworks barrier's")
	var upright := EventInstance._native_size(end_on)
	t.check(upright.y > upright.x,
			"the end-on segment is the upright projection (%s)" % upright)

## The guards stand beside their barrier, never over it *(2026-09-25: "also the guards are on top
## of the barrier?")*, one on each side (*"have one guard on each side?"*): on both street axes,
## each one's whole standing picture is outside the whole of the barrier's drawn picture, on his
## own side of it, facing out from it towards where she would come from.
func _test_roadblock_guard_stands_clear_of_the_band(t) -> void:
	var def := EventCatalogue.by_id("roadblock")
	var half := maxf(11.0, def.obstructs_radius)
	var guard_size := EventInstance._native_size(EventInstance.GUARD_STANDING_BY_VIEW["front"])
	for vertical: bool in [false, true]:
		var axis := "end-on" if vertical else "broadside"
		var band := _roadblock_band_rect(vertical, half)
		t.check(band.size.x > 0.0 and band.size.y > 0.0,
				"%s, the barrier has a picture to stand clear of (%s)" % [axis, band])
		for side: int in [-1, 1]:
			var feet := EventInstance._guard_post_offset(vertical, side)
			var guard := Rect2(feet - Vector2(guard_size.x * 0.5, guard_size.y), guard_size)
			t.check(not guard.intersects(band),
					"%s, side %d: the guard's picture %s is clear of the barrier's %s"
					% [axis, side, guard, band])
			var across := feet.x if vertical else feet.y
			t.check(signf(across) == signf(side),
					"%s, side %d: he stands on that side of the band (%s)" % [axis, side, feet])
			var heading := EventInstance._guard_post_heading(vertical, side)
			t.check(heading.dot(feet) > 0.0,
					"%s, side %d: facing out from it (%s)" % [axis, side, heading])
	# The one who gives chase is the one on her side, across the band; level with its line, south.
	t.check(EventInstance._guard_side_toward(false, Vector2(30.0, -200.0)) == -1
			and EventInstance._guard_side_toward(false, Vector2(-30.0, 200.0)) == 1
			and EventInstance._guard_side_toward(true, Vector2(-200.0, 30.0)) == -1
			and EventInstance._guard_side_toward(true, Vector2(200.0, -30.0)) == 1,
			"the chaser is the guard on whichever side of the band she is, across it")
	t.check(EventInstance._guard_side_toward(false, Vector2(170.0, 0.0)) == 1,
			"and level with the band's own line it is the camera-facing south")

## **The barrier's picture covers the ground its body closes, on both axes, and no more.**
## *(2026-09-25: "only the barrier doesn't actually reach the full width/height is that
## intentional?")* Along the run, the repeated segments reach from one end of the body to the
## other — the body's own reach along its spine, `obstructs_radius` — broadside across the picture
## and end-on up it, where a segment standing on its middle would put the whole column half a
## segment up the screen from its own ground. Asked of the roadblock and of the roadworks barrier,
## the two rows that draw a capped band through `_draw_spread()`.
func _test_a_spread_covers_the_ground_its_body_closes(t) -> void:
	for id: String in ["roadblock", "construction"]:
		var def := EventCatalogue.by_id(id)
		var half := maxf(11.0, def.obstructs_radius)
		for vertical: bool in [false, true]:
			var what := "%s %s" % [id, "end-on" if vertical else "broadside"]
			var picture := EventInstance._roadblock_segment_texture(vertical) if id == "roadblock" \
					else EventInstance._roadwork_segment_texture(vertical)
			var span := Rect2()
			var first := true
			for rect in _spread_segment_rects(picture, vertical, half):
				span = rect if first else span.merge(rect)
				first = false
			var from := span.position.y if vertical else span.position.x
			var to := span.end.y if vertical else span.end.x
			t.check(is_equal_approx(from, -def.obstructs_radius)
					and is_equal_approx(to, def.obstructs_radius),
					"%s: the segments run %.1f..%.1f along the run, the body's own %.0f..%.0f"
					% [what, from, to, -def.obstructs_radius, def.obstructs_radius])

## The union of every rect `EventInstance._draw_spread()` draws a roadblock's band into, segments
## and end posts, in the band's own local space — the same slice and cap arithmetic that function
## uses, through the same `_spread_slice_feet()`, `_cap_offset()` and `_cap_along()` it calls.
func _roadblock_band_rect(vertical: bool, half: float) -> Rect2:
	return _spread_rect(EventInstance._roadblock_segment_texture(vertical),
			EventInstance.ROADBLOCK_END, vertical, half)

## The union of every rect `EventInstance._draw_spread()` draws `segment_picture` into, capped by
## `cap_picture` at both ends unless it is empty, over a run of `-half` to `half`.
func _spread_rect(segment_picture: String, cap_picture: String, vertical: bool,
		half: float) -> Rect2:
	var rects := _spread_segment_rects(segment_picture, vertical, half)
	if not cap_picture.is_empty():
		var cap := EventInstance._native_size(cap_picture)
		for side: float in [-1.0, 1.0]:
			var along := EventInstance._cap_offset(half, EventInstance._cap_along(cap), side)
			var feet := Vector2(0.0, along) if vertical else Vector2(along, 0.0)
			rects.append(Rect2(feet - Vector2(cap.x * 0.5, cap.y), cap))
	var union := rects[0]
	for rect in rects:
		union = union.merge(rect)
	return union

## The rect each repeated segment of a spread is drawn into, the way `_draw_spread()` draws them.
func _spread_segment_rects(segment_picture: String, vertical: bool, half: float) -> Array[Rect2]:
	var segment := EventInstance._native_size(segment_picture)
	var along_natural := segment.y if vertical else segment.x
	var thickness := segment.x if vertical else segment.y
	var segments := maxi(1, ceili(half * 2.0 / along_natural))
	var width := half * 2.0 / segments
	var rects: Array[Rect2] = []
	for i in segments:
		var along := EventInstance._spread_slice_feet(vertical, half, width, i)
		var feet := Vector2(0.0, along) if vertical else Vector2(along, 0.0)
		var size := Vector2(thickness, width) if vertical else Vector2(width, thickness)
		rects.append(Rect2(feet - Vector2(size.x * 0.5, size.y), size))
	return rects

## Alley mouths have no corridor band for `_spread_is_vertical()` to read. Their own rectangle
## supplies the axis instead: a horizontal alley is sealed by a vertical spread across its short
## side, while a vertical alley keeps the default horizontal spread.
func _test_roadwork_barrier_follows_alley_axis(t) -> void:
	var map := CityMap.new()
	map.alley_rects.append(Rect2i(Vector2i(10, 10), Vector2i(6, 2)))
	map.alley_rects.append(Rect2i(Vector2i(20, 20), Vector2i(2, 6)))
	t.check(EventInstance._spread_is_vertical(map, map.tile_to_world(Vector2i(12, 11))),
			"a horizontal alley gets a vertical barrier spread across its mouth")
	t.check(not EventInstance._spread_is_vertical(map, map.tile_to_world(Vector2i(20, 22))),
			"a vertical alley keeps a horizontal barrier spread across its mouth")

# ------------------------------------------------------------------- the tables ---

func _test_family_dictionaries_are_complete(t) -> void:
	for name in FAMILY_DICTS:
		var by_view: Dictionary = FAMILY_DICTS[name]
		t.check(by_view.size() == 5, "%s carries exactly five authored views" % name)
		for view in EXPECTED_VIEW:
			t.check(by_view.has(view) and by_view[view] != null,
					"%s has a resolving %s view" % [name, view])

func _test_animal_side_view_reuses_the_canonical_source(t) -> void:
	for name in ANIMAL_SIDE_REUSE:
		var by_view: Dictionary = FAMILY_DICTS[name]
		t.check(by_view["side"] == ANIMAL_SIDE_REUSE[name],
				"%s's side view is the same picture as its existing canonical source" % name)

func _test_vehicle_side_view_reuses_the_canonical_source(t) -> void:
	for name in VEHICLE_SIDE_REUSE:
		var by_view: Dictionary = FAMILY_DICTS[name]
		t.check(by_view["side"] == VEHICLE_SIDE_REUSE[name],
				"%s's side view is the same picture as its existing canonical source" % name)

## The people families' five views are freshly authored rather than reusing an old flat picture —
## `busker.svg` and `busker_side.svg` differ on disk, unlike the animal and vehicle families above —
## so a copy-paste that preloaded one file under two keys would otherwise pass unnoticed.
func _test_people_views_are_five_distinct_pictures(t) -> void:
	var people := FAMILY_DICTS.keys().filter(func(name: String) -> bool:
		return not ANIMAL_SIDE_REUSE.has(name) and not VEHICLE_SIDE_REUSE.has(name))
	for name in people:
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
func _test_vehicle_views_are_five_distinct_pictures(t) -> void:
	for name in VEHICLE_SIDE_REUSE:
		var by_view: Dictionary = FAMILY_DICTS[name]
		var textures := by_view.values()
		for i in textures.size():
			for j in range(i + 1, textures.size()):
				t.check(textures[i] != textures[j],
						"%s's own five views are five different pictures" % name)

## Two states sharing a view name must never be the same asset, or the state a player is meant to
## read at a glance — crouched against running, waiting against lunging, strolling against talking,
## wings up against wings down — is invisible.
func _test_state_pairs_stay_visually_distinct(t) -> void:
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
	for pair in pairs:
		var a: Dictionary = FAMILY_DICTS[pair[0]]
		var b: Dictionary = FAMILY_DICTS[pair[1]]
		for view in EXPECTED_VIEW:
			t.check(a[view] != b[view],
					"%s and %s draw different pictures for the %s view" % [pair[0], pair[1], view])

# ------------------------------------------------------------------- fresh placement ---

## `setup()` resets `_view_sector` to the exact nearest sector for the instance's own siting —
## `EightDirection.nearest()`'s own "no prior-view hold on a fresh placement" rule — rather than
## leaving a stale hold from whatever the field's zero-value default happens to be.
func _test_setup_resets_the_view_to_the_exact_siting(t) -> void:
	var instance := EventInstance.new()
	for sector in range(8):
		instance.setup(EventCatalogue.by_id("busker"), Vector2.ZERO, PackedVector2Array(),
				_heading_for_sector(sector))
		t.check(instance._view_sector == sector,
				"a fresh siting at %d degrees starts on sector %d directly (got %d)"
				% [sector * 45, sector, instance._view_sector])
	instance.free()

# ------------------------------------------------------------------- targeted facing ---

## "A stationary actor whose action has a target faces that target": the waiting robber has not
## noticed her yet (`is_waiting()` stays true — `_chase()` only turns `_heading` toward her once
## she is inside `pursues_within`), but a man only watching the street is worth nothing next to a
## man watching *her*, so `_robber_waiting_heading()` reads `player_at` directly.
func _test_robber_waiting_faces_her(t) -> void:
	var def := EventCatalogue.by_id("alley_robbery")
	var instance := EventInstance.new()
	instance.setup(def, Vector2.ZERO)
	t.check(instance.is_waiting(), "nobody has come near him yet")
	for sector in range(8):
		# Well outside `pursues_within` (180px), so he never actually notices her — this is the
		# waiting posture's own facing, not the notice turning `_heading` for it.
		instance.player_at = _heading_for_sector(sector) * (def.pursues_within + 40.0)
		var heading := instance._robber_waiting_heading()
		t.check(instance.is_waiting(), "still only waiting at sector %d" % sector)
		var view := instance._select_view(heading)
		t.check(view == EXPECTED_VIEW[sector],
				"waiting toward sector %d faces the %s view (got %s)"
				% [sector, EXPECTED_VIEW[sector], view])
	instance.free()

func _test_robber_waiting_falls_back_to_its_siting_with_no_player(t) -> void:
	var def := EventCatalogue.by_id("alley_robbery")
	var instance := EventInstance.new()
	instance.setup(def, Vector2.ZERO, PackedVector2Array(), _heading_for_sector(6))
	t.check(instance.player_at == Vector2.INF, "a data-level rig has no player position at all")
	t.check(instance._robber_waiting_heading() == instance._heading,
			"with nothing to face, the waiting posture keeps the site's own authored facing")
	instance.free()

## Once he has noticed her, `_chase()` keeps `_heading` pointed at her for the whole of the
## telegraph and the chase — "a lunging robber faces its lunge" is this, already true through the
## existing pursuit code, and this test is what proves the drawing actually reads it.
func _test_robber_lunging_faces_her_through_the_chase(t) -> void:
	var def := EventCatalogue.by_id("alley_robbery")
	var instance := EventInstance.new()
	instance.setup(def, Vector2.ZERO)
	# Southeast of him and inside `pursues_within`, so one `_chase()` step notices her and turns to
	# face her.
	var her := _heading_for_sector(1) * (def.pursues_within - 10.0)
	instance.player_at = her
	instance._process(STEP)
	t.check(not instance.is_waiting(), "he has noticed her")
	var expected := (her - instance.global_position).normalized()
	t.check(instance._heading.is_equal_approx(expected), "he turned to face her exactly")
	var view := instance._select_view(instance._heading)
	t.check(view == "front_diagonal", "facing southeast draws the front_diagonal view (got %s)"
			% view)
	instance.free()

# ------------------------------------------------------------------- state predicates ---

func _test_cat_state_predicate_selects_the_telegraph_posture(t) -> void:
	var def := EventCatalogue.by_id("cat_dash")
	var instance := EventInstance.new()
	instance.setup(def, Vector2.ZERO)
	t.check(instance.is_telegraphing(), "a cat starts in its crouch")
	for i in int(round((def.telegraph_time + 0.05) / STEP)):
		instance._process(STEP)
	t.check(not instance.is_telegraphing(), "and is running once the telegraph ends")
	instance.free()

func _test_chatting_mother_state_predicate_selects_the_conversation_posture(t) -> void:
	var def := EventCatalogue.by_id("chatting_mother")
	var instance := EventInstance.new()
	instance.setup(def, Vector2.ZERO)
	t.check(not instance.is_chatting(), "she is only strolling until spoken to")
	instance.start_chat()
	t.check(instance.is_chatting(), "and talking for the length of the conversation")
	instance.free()

## The masked man on the escape's stairs stands while he waits for her, stands with his hand raised
## through his notice *(inbox #764, the player: an event that does not spawn already charging always
## needs a warning)*, and is drawn lunging (`masked_pursuer_pictures()`) only once the notice is over
## and he runs his line.
func _test_masked_man_is_drawn_standing_until_he_goes(t) -> void:
	var def := EventCatalogue.by_id("masked_pursuer")
	var instance := EventInstance.new()
	instance.setup(def, Vector2.ZERO)
	t.check(instance.is_waiting() and instance._stands_still_now()
			and instance.masked_pursuer_pictures() == EventInstance.GUARD_STANDING_BY_VIEW,
			"waiting at the foot of the shaft he is drawn standing")
	# Inside `pursues_within` (900px) along a clear line: one step notices her.
	instance.player_at = Vector2(0.0, def.pursues_within - 100.0)
	instance._process(STEP)
	t.check(not instance.is_waiting() and instance.is_telegraphing(), "he has noticed her")
	var alert := true
	for i in int(round((def.telegraph_time - 0.05) / STEP)):
		alert = alert and instance._stands_still_now() \
				and instance.masked_pursuer_pictures() == EventInstance.GUARD_ALERT_BY_VIEW
		instance._process(STEP)
	t.check(alert, "and spends the whole notice standing with his hand raised")
	for i in int(round(0.1 / STEP)):
		instance._process(STEP)
	t.check(not instance.is_telegraphing() and not instance._stands_still_now()
			and instance.masked_pursuer_pictures() == EventInstance.GUARD_LUNGING_BY_VIEW,
			"once the notice is over he is drawn lunging")
	instance.free()

# ----------------------------------------------------------- every charger's three stages ---
# *(velvet-marten, #699: "entities that charge towards the player when the player gets too close need
# three stages: neutral (with neutral visuals), warning (...), and then the actual charging";
# polite-toad, #722: "a distinct alert and rest post for each charger that gets triggered by the
# player"; inbox #748: "robber can walk towards her but guards should lift their hand in warning",
# "nobody walks -- only the robber".)* Each test walks one charger through its stages and pins the
# picture query its `_draw_*` reads (`charging_dog_pictures()`, `robber_pictures()`,
# `chaser_pictures()`, `masked_pursuer_pictures()`), and whether it moves while it warns.

## Steps `instance` for `seconds` with her held at `her`.
func _hold(instance: EventInstance, her: Vector2, seconds: float) -> void:
	instance.player_at = her
	for i in int(round(seconds / STEP)):
		instance._process(STEP)

func _test_the_waiting_dog_rests_stands_alert_and_gallops(t) -> void:
	var def := EventScheduler._for_day(EventCatalogue.by_id("charging_dog"),
			Tuning.RUN_TAUGHT_DAY + 1)
	var instance := EventInstance.new()
	instance.setup(def, Vector2.ZERO)
	_hold(instance, Vector2(def.pursues_within + 60.0, 0.0), 1.0)
	var pictures := instance.charging_dog_pictures()
	t.check(instance.is_waiting() and pictures[0] == EventInstance.CHARGING_DOG_RESTING_BY_VIEW
			and pictures[1].is_empty(), "waiting for her, the dog sits, with no stride frame")
	# Inside its trigger and outside its stand-off, where she stands for longer than its telegraph.
	var standoff := Tuning.pursuit_standoff(def.pursue_speed, def.standoff_reach())
	var her := Vector2((def.pursues_within + standoff) * 0.5, 0.0)
	_hold(instance, her, STEP)
	t.check(instance.is_standing_for_its_notice(), "it notices her and stands for its notice")
	t.check(instance._heading.is_equal_approx(her.normalized()), "turned to face her")
	var still := true
	var alert := true
	for i in int(round((def.telegraph_time + 3.0) / STEP)):
		instance._process(STEP)
		still = still and instance.global_position.is_equal_approx(Vector2.ZERO) \
				and not instance._gait_stepping()
		pictures = instance.charging_dog_pictures()
		alert = alert and pictures[0] == EventInstance.CHARGING_DOG_ALERT_BY_VIEW \
				and pictures[1].is_empty()
	t.check(alert, "its alert, a still picture, for as long as she stays in its radius")
	t.check(still, "and it does not move toward her while it warns")
	# Back out of its radius it sits again, and warns again when she comes back.
	_hold(instance, Vector2(def.pursues_within + 10.0, 0.0), STEP)
	pictures = instance.charging_dog_pictures()
	t.check(instance.is_waiting() and pictures[0] == EventInstance.CHARGING_DOG_RESTING_BY_VIEW,
			"out of its radius again, it sits")
	_hold(instance, her, STEP)
	t.check(instance.charging_dog_pictures()[0] == EventInstance.CHARGING_DOG_ALERT_BY_VIEW,
			"and back inside, it warns again")
	_hold(instance, Vector2(standoff - 2.0, 0.0), 0.2)
	pictures = instance.charging_dog_pictures()
	t.check(not instance.is_telegraphing() and pictures[0] == EventInstance.CHARGING_DOG_BY_VIEW
			and pictures[1] == EventInstance.CHARGING_DOG_BY_VIEW_B,
			"once she crosses its stand-off it gallops, both frames")
	instance.free()

## **The day-3 dog's telegraph is its approach**, so it is drawn galloping at her for all of it and
## never stands: the same row handed to the director with no trigger to have waited behind.
func _test_the_day_3_dog_gallops_through_its_approach(t) -> void:
	var def := EventCatalogue.by_id("charging_dog")
	t.check(def.pursues_within <= 0.0, "on the teaching day the dog does not wait")
	var instance := EventInstance.new()
	instance.setup(def, Vector2.ZERO)
	_hold(instance, Vector2(400.0, 0.0), 1.0)
	t.check(instance.is_telegraphing() and not instance.is_standing_for_its_notice(),
			"its approach is its telegraph, and it does not stand for it")
	t.check(instance.charging_dog_pictures()[0] == EventInstance.CHARGING_DOG_BY_VIEW,
			"drawn galloping")
	t.check(instance.global_position.x > 100.0, "and coming (%.0fpx in a second)"
			% instance.global_position.x)
	instance.free()

func _test_the_robber_waits_walks_alert_and_lunges(t) -> void:
	var def := EventCatalogue.by_id("alley_robbery")
	var instance := EventInstance.new()
	instance.setup(def, Vector2.ZERO)
	_hold(instance, Vector2(def.pursues_within + 40.0, 0.0), 0.5)
	t.check(instance.is_waiting() and instance.robber_pictures() == EventInstance.ROBBER_WAITING_BY_VIEW,
			"waiting, hood up and hands in his coat")
	var her := Vector2(def.pursues_within - 4.0, 0.0)
	_hold(instance, her, STEP)
	t.check(instance.is_telegraphing() and not instance.is_standing_for_its_notice(),
			"he notices her, and he does not stand for it")
	t.check(instance.robber_pictures() == EventInstance.ROBBER_ALERT_BY_VIEW,
			"drawn in his alert, hands out of his coat, on its first frame before he has moved")
	# **His alert is a walk, two frames on his stride** (`_gait_stepping()`): walking at her slowly
	# through his notice he shows both, and nothing but his alert, until he lunges.
	var alert_frames := {}
	var other := 0
	while instance.is_telegraphing():
		_hold(instance, her, STEP)
		if not instance.is_telegraphing():
			break
		var pictures := instance.robber_pictures()
		if pictures == EventInstance.ROBBER_ALERT_BY_VIEW:
			alert_frames["a"] = true
		elif pictures == EventInstance.ROBBER_ALERT_BY_VIEW_B:
			alert_frames["b"] = true
		else:
			other += 1
	t.check(instance.global_position.x > 30.0,
			"walking at her through his notice (%.1fpx)" % instance.global_position.x)
	t.check(alert_frames.size() == 2 and other == 0,
			"his alert walk shows both its frames (%s) and nothing else (%d frames)"
			% [", ".join(alert_frames.keys()), other])
	_hold(instance, her, def.telegraph_time)
	t.check(not instance.is_telegraphing()
			and instance.robber_pictures() in [EventInstance.ROBBER_LUNGING_BY_VIEW,
					EventInstance.ROBBER_LUNGING_BY_VIEW_B],
			"once his slow walk has brought her inside his stand-off he lunges")
	instance.free()
	# **She steps back out of his radius while he walks: he stops where he is and waits** *(inbox
	# #764, the player: the robber walking slowly stops if she gets out of the radius)*, drawn
	# waiting, and warns again when she comes back in.
	var walker := EventInstance.new()
	walker.setup(def, Vector2.ZERO)
	_hold(walker, her, 0.5)
	var stopped_at := walker.global_position
	t.check(walker.is_telegraphing() and stopped_at.x > 10.0,
			"he has walked %.1fpx at her" % stopped_at.x)
	var out := stopped_at + Vector2(def.pursues_within + 4.0, 0.0)
	_hold(walker, out, 1.0)
	t.check(walker.is_waiting() and walker.robber_pictures() == EventInstance.ROBBER_WAITING_BY_VIEW,
			"out of his radius he waits again, hood up")
	t.close_to(walker.global_position.distance_to(stopped_at), 0.0,
			"where he had walked to, not back at his post", 0.5)
	_hold(walker, stopped_at + Vector2(def.pursues_within - 4.0, 0.0), STEP)
	t.check(walker.is_telegraphing() and walker.robber_pictures() == EventInstance.ROBBER_ALERT_BY_VIEW,
			"and back inside it he warns again")
	walker.free()
	# The sent robber arrives chasing, with no notice to be alert through.
	var sent := EventInstance.new()
	sent.setup(EventCatalogue.by_id("robber_giving_chase"), Vector2.ZERO)
	_hold(sent, Vector2(300.0, 0.0), STEP)
	t.check(sent.robber_pictures() != EventInstance.ROBBER_ALERT_BY_VIEW,
			"the robber a task sends is drawn coming from his first frame")
	sent.free()

func _test_the_roadblock_guard_raises_his_hand_at_his_post(t) -> void:
	var hot := EventCatalogue.heated(EventCatalogue.by_id("roadblock"), Tuning.HEAT_HUNTS_LEVEL)
	var guard := EventInstance.new()
	guard.setup(hot, Vector2.ZERO)
	t.add_child(guard)
	guard.set_process(false)
	guard._attach_the_band()
	var her := Vector2(0.0, hot.pursues_within - 10.0)
	_hold(guard, her, STEP)
	t.check(guard.chaser_side() != 0 and guard.is_standing_for_its_notice(),
			"the guard on her side has noticed her and stands for his notice")
	t.check(guard.chaser_pictures() == EventInstance.GUARD_ALERT_BY_VIEW, "hand raised")
	var post := guard.global_position
	_hold(guard, her, hot.telegraph_time + 3.0)
	t.check(guard.global_position.is_equal_approx(post)
			and guard.chaser_pictures() == EventInstance.GUARD_ALERT_BY_VIEW,
			"at his post, hand raised, for as long as she stays in his radius")
	# Out of his radius he is back at the band, and both guards stand at their posts again.
	_hold(guard, Vector2(0.0, hot.pursues_within + 10.0), STEP)
	t.check(guard.is_waiting() and guard.chaser_side() == 0 and not guard.has_left_its_body_behind()
			and guard.global_position.is_equal_approx(Vector2.ZERO),
			"out of his radius he stands at the band again, its body under him")
	_hold(guard, her, STEP)
	t.check(guard.is_standing_for_its_notice()
			and guard.chaser_pictures() == EventInstance.GUARD_ALERT_BY_VIEW,
			"and back inside it he raises his hand again")
	var standoff := Tuning.pursuit_standoff(hot.pursue_speed, hot.standoff_reach())
	_hold(guard, guard.global_position + Vector2(0.0, standoff - 2.0), 0.1)
	t.check(not guard.is_telegraphing()
			and guard.chaser_pictures() == EventInstance.GUARD_LUNGING_BY_VIEW,
			"then she crosses his stand-off and he lunges")
	guard.free()

func _test_the_door_guard_raises_his_hand_where_he_stepped_out(t) -> void:
	var def := EventCatalogue.by_id("door_guard")
	var guard := EventInstance.new()
	guard.setup(def, Vector2(32.0, 48.0))
	# She walks away from him through his notice: once she is past his stand-off a pursuer that
	# sets off beside her would follow; standing for his notice, he does not.
	var her := Vector2(1.0, 0.0)
	var still := true
	var alert := true
	for i in int(round((def.telegraph_time - 0.1) / STEP)):
		her.x += Tuning.WALK_SPEED * STEP
		_hold(guard, her, STEP)
		still = still and guard.global_position.is_equal_approx(Vector2(32.0, 48.0))
		alert = alert and guard.masked_pursuer_pictures() == EventInstance.GUARD_ALERT_BY_VIEW
	t.check(alert, "the door guard holds his hand raised for his whole notice")
	t.check(still, "and stands where he stepped out while she walks away")
	_hold(guard, her, 0.2)
	t.check(not guard.is_telegraphing()
			and guard.masked_pursuer_pictures() == EventInstance.GUARD_LUNGING_BY_VIEW,
			"then he lunges")
	guard.free()

## **The man a vehicle lets out raises his hand and stands still, then charges.** *(Inbox #764, the
## player: van guardsmen about to charge hold up their hands; events that spawn with the sole purpose
## of charging show an indicator that they are about to, with the same heads-up as off-screen
## chargers.)* Every copy `EventCatalogue.out_of_the_car()` makes — out of a patrol car or a hunting
## van, the policeman through day 8 and the guardsman from day 9 — stands where he got out in his
## alert (`policeman_alert_*` or `guard_alert_*`) for `Tuning.WARNING_ALONE_MAX` while she walks
## away, and then lunges.
func _test_the_man_out_of_a_vehicle_raises_his_hand_then_charges(t) -> void:
	var day_of := {"policeman_giving_chase": EventCatalogue.guardsmen_from_day() - 1,
			"guardsman_giving_chase": EventCatalogue.guardsmen_from_day()}
	for id: String in day_of.keys():
		for stops: bool in [true, false]:
			var def := EventCatalogue.out_of_the_car(day_of[id], stops)
			var name := "%s out of %s" % [id, "a patrol car" if stops else "a hunting van"]
			t.check(def.stands_for_its_notice and def.sets_off_beside_her
					and is_equal_approx(def.telegraph_time, Tuning.WARNING_ALONE_MAX),
					"%s stands for a %.1fs heads-up" % [name, def.telegraph_time])
			var alert_pictures := EventInstance.POLICEMAN_ALERT_BY_VIEW \
					if def.look == EventDef.Look.POLICEMAN_GIVING_CHASE else EventInstance.GUARD_ALERT_BY_VIEW
			var man := EventInstance.new()
			man.setup(def, Vector2(32.0, 0.0))
			var her := Vector2(0.0, 0.0)
			var still := true
			var alert := true
			for i in int(round((def.telegraph_time - 0.05) / STEP)):
				her.x -= Tuning.WALK_SPEED * STEP
				_hold(man, her, STEP)
				still = still and man.global_position.is_equal_approx(Vector2(32.0, 0.0))
				alert = alert and _pictures_of(man) == alert_pictures
			t.check(alert, "%s holds his hand raised for the whole heads-up" % name)
			t.check(still, "and stands where he got out while she walks away")
			_hold(man, her, 0.1)
			t.check(not man.is_telegraphing() and _pictures_of(man) != alert_pictures,
					"then he charges")
			man.free()

## The guard-drawn or policeman's picture a man on foot is drawn with this frame.
func _pictures_of(man: EventInstance) -> Dictionary:
	if man.def.look == EventDef.Look.POLICEMAN_GIVING_CHASE:
		return man.policeman_pictures()
	return man.masked_pursuer_pictures()

## **A man who arrives already charging never shows the warning**: the van's guard a task sends and
## the policeman or guardsman a torn poster sends come at her from their first frame, warned of by
## their screen-edge badge alone.
func _test_no_guard_who_arrives_charging_takes_the_alert(t) -> void:
	for id: String in ["van_guard_giving_chase", "policeman_giving_chase", "guardsman_giving_chase"]:
		var def := EventCatalogue.by_id(id)
		t.check(def.arrives_chasing and not def.stands_for_its_notice,
				"'%s' arrives charging and does not stand for a notice" % id)
		var instance := EventInstance.new()
		instance.setup(def, Vector2.ZERO)
		var alert := false
		for i in int(round(3.0 / STEP)):
			_hold(instance, Vector2(0.0, 100.0), STEP)
			var pictures := _pictures_of(instance)
			alert = alert or pictures == EventInstance.GUARD_ALERT_BY_VIEW \
					or pictures == EventInstance.POLICEMAN_ALERT_BY_VIEW
		t.check(not alert, "'%s' never draws an alert" % id)
		instance.free()

# --------------------------------------------------------------- M108's vehicle item ---
# `EventInstance._draw_eight_view()`'s `side_faces_west` parameter, and the per-family binding in
# `_draw_body()` that decides it — see that function's own doc comment and
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
func _test_vehicle_views_match_facings_csv_per_sector(t) -> void:
	for name in VEHICLE_SIDE_REUSE:
		var side_faces_west: bool = VEHICLE_SIDE_FACES_WEST[name]
		var expected_mirror: Array = VEHICLE_MIRROR_BY_SECTOR[name]
		var instance := EventInstance.new()
		instance.setup(EventCatalogue.by_id(VEHICLE_DEF_ID[name]), Vector2.ZERO)
		for sector in range(8):
			# Started from the opposite sector every time — the same discipline
			# `_test_select_view_holds_and_mirrors` uses — so a pass is never an accident of the
			# previous iteration's hold agreeing with this one.
			instance._view_sector = (sector + 4) % 8
			var view := instance._select_view(_heading_for_sector(sector))
			var mirror := EightDirection.is_mirrored(instance._view_sector)
			if view == "side" and side_faces_west:
				mirror = not mirror
			t.check(view == EXPECTED_VIEW[sector],
					"%s sector %d selects the %s view (got %s)"
					% [name, sector, EXPECTED_VIEW[sector], view])
			t.check(mirror == expected_mirror[sector],
					"%s sector %d mirrors %s per facings.csv (got %s)"
					% [name, sector, expected_mirror[sector], mirror])
		instance.free()

## M56's original hand-written `match` in `_draw_riot_van()`, transcribed as literal data
## independent of `EXPECTED_VIEW`/`EIGHT_VIEW_BY_SECTOR` above, so a later change to either of those
## shared tables cannot silently change what the night raid's van draws without this test noticing.
## The texture per sector is exactly what the hand-written match once picked; the mirror at
## sectors 0 (E) and 4 (W) is corrected from it, since `riot_van.svg` is authored facing west
## (`facings.csv`) and the hand-written match had those two sectors backwards — every other sector
## draws a front/back/diagonal view, which `side_faces_west` never touches, so it is pinned exactly
## as the original match had it.
const RIOT_VAN_OCTANT_TEXTURE := [
	EventInstance.RIOT_VAN, EventInstance.RIOT_VAN_FRONT_DIAGONAL, EventInstance.RIOT_VAN_FRONT,
	EventInstance.RIOT_VAN_FRONT_DIAGONAL, EventInstance.RIOT_VAN,
	EventInstance.RIOT_VAN_BACK_DIAGONAL, EventInstance.RIOT_VAN_BACK,
	EventInstance.RIOT_VAN_BACK_DIAGONAL,
]
const RIOT_VAN_OCTANT_MIRROR: Array[bool] = [true, false, false, true, false, true, false, false]

func _test_riot_van_reproduces_its_octant_table_with_the_corrected_side_mirror(t) -> void:
	var instance := EventInstance.new()
	instance.setup(EventCatalogue.by_id("night_raid"), Vector2.ZERO)
	for sector in range(8):
		instance._view_sector = (sector + 4) % 8
		var view := instance._select_view(_heading_for_sector(sector))
		var mirror := EightDirection.is_mirrored(instance._view_sector)
		if view == "side":
			mirror = not mirror
		t.check(EventInstance.RIOT_VAN_BY_VIEW[view] == RIOT_VAN_OCTANT_TEXTURE[sector],
				"sector %d draws the same texture the hand-written match once did" % sector)
		t.check(mirror == RIOT_VAN_OCTANT_MIRROR[sector],
				"sector %d mirrors per facings.csv, corrected from the hand-written match" % sector)
	instance.free()

## `delivery_van` and `ice_cream_van` are always sited facing east — `AT_THE_KERB` never sets
## `EventScheduler.Planned.facing` away from its own default — so binding them onto the shared
## eight-view table must still draw exactly the `"side"` view for a fresh siting, the one view
## either row has ever shown.
func _test_kerb_parked_vans_keep_their_axis_chosen_view(t) -> void:
	for name in ["delivery_van", "ice_cream_van"]:
		var instance := EventInstance.new()
		instance.setup(EventCatalogue.by_id(name), Vector2.ZERO)
		t.check(EventInstance.EIGHT_VIEW_BY_SECTOR[instance._view_sector] == "side",
				"%s's own default east facing still lands on the side view" % name)
		instance.free()

## `reversing_lorry` (`AGAINST_THE_BUILDING`) only ever faces due east or west —
## `EventScheduler._wants_this_side` refuses any facing that is not purely horizontal — so its
## front, back and diagonal views are never actually reachable in play; binding it onto the shared
## table must not change that.
func _test_reversing_lorry_only_ever_faces_the_side_view(t) -> void:
	var def := EventCatalogue.by_id("reversing_lorry")
	for face in [Vector2.RIGHT, Vector2.LEFT]:
		var instance := EventInstance.new()
		instance.setup(def, Vector2.ZERO, PackedVector2Array(), face)
		t.check(EventInstance.EIGHT_VIEW_BY_SECTOR[instance._view_sector] == "side",
				"reversing_lorry facing %s still lands on the side view" % face)
		instance.free()

## Every front, back and diagonal view's own ground contact — the vehicle's wheels — sits within a
## few pixels of its own canvas's bottom edge, the same edge `Sprites.draw_standing()` places at the
## event's ground point (`_draw_eight_view()` always draws at local `Vector2.ZERO`, the same point
## `_draw_shape_shadow()` centres `def.shape`'s own shadow on, with no per-view offset anywhere in
## between). A picture whose ink stopped well short of the bottom would draw the vehicle floating
## above its own shadow. The tolerance is generous on purpose — the fact worth pinning is "close to
## the edge," not any one picture's own last row of pixels; `docs/evidence/svg-vehicles-2026-09-10/
## README.md` puts every family's own tyre contact within 5px of it.
const FOOTPRINT_TOLERANCE_PX := 8.0

func _test_vehicle_views_are_grounded_at_the_canvas_bottom(t) -> void:
	# The pixels come off the baked page rather than out of the authoring SVG: the sources live
	# under `art/`, which the engine ignores, and the page is what the game actually draws.
	var page := AtlasLibrary.page_image(EventInstance.ATLAS_GROUP)
	t.check(page != null, "the baked events page reads back as an image")
	if page == null:
		return
	for name in VEHICLE_SIDE_REUSE:
		var by_view: Dictionary = FAMILY_DICTS[name]
		for view in ["front", "back", "front_diagonal", "back_diagonal"]:
			var picture: String = by_view[view]
			var image := page.get_region(AtlasLibrary.region_rect(StringName(picture)))
			var bounds := image.get_used_rect()
			t.check(bounds.size.y > 0, "%s's %s view has some ink to measure" % [name, view])
			var ground := bounds.end.y
			# A vehicle that rolls on wheels of its own touches the ground with those: its body
			# rides a bob above them, so the wheels picture is the ground contact being measured.
			var wheels := StringName(picture + "_wheels")
			if AtlasLibrary.has_region(wheels):
				var wheel_image := page.get_region(AtlasLibrary.region_rect(wheels))
				ground = maxi(ground, wheel_image.get_used_rect().end.y)
			var gap := image.get_height() - ground
			t.check(gap <= FOOTPRINT_TOLERANCE_PX,
					"%s's %s view grounds within %dpx of its own canvas bottom (got %dpx)"
					% [name, view, FOOTPRINT_TOLERANCE_PX, gap])

## `burst_water_main`'s crater is sunk into the road rather than standing on it, so the player
## asked for no shadow under it — `EventDef.draws_body_shadow` is the query `_draw_body_shadow()`
## reads, and this pins the query the same way the rest of this file pins one rather than calling
## a `_draw_*` function directly. `fallen_tree` shares the row's single-body geometry
## (`docs/EVENTS.md`, "Seal pictures") and keeps the ordinary shadow, so the flag is the only
## difference between the two.
func _test_burst_water_main_draws_no_body_shadow(t) -> void:
	t.check(not EventCatalogue.by_id("burst_water_main").draws_body_shadow,
			"burst_water_main opts out of the body shadow every other seal draws")
	t.check(EventCatalogue.by_id("fallen_tree").draws_body_shadow,
			"fallen_tree, burst_water_main's same-geometry sibling, keeps the ordinary body shadow")

# ------------------------------------------------------------ the wheels ---

## **Every vehicle that moves rolls on a wheels picture of its own**, one per view, baked on the
## `events` page on exactly its body's canvas — the one size `Sprites.draw_standing()` bottom-centres
## both by — and listed with the look's own sources, so the atlas completeness check covers it. The
## ones drawn under their body name wheels that exist.
func _test_every_moving_vehicle_has_wheels_on_its_own_canvas(t) -> void:
	var looks := {
		EventDef.Look.POLICE_CAR: EventInstance.POLICE_CAR_BY_VIEW,
		EventDef.Look.FIRE_ENGINE: EventInstance.FIRE_ENGINE_BY_VIEW,
		EventDef.Look.UNMARKED_VAN: EventInstance.UNMARKED_VAN_BY_VIEW,
		EventDef.Look.RIOT_VAN: EventInstance.RIOT_VAN_BY_VIEW,
		EventDef.Look.ARMY_TRUCK: EventInstance.ARMY_TRUCK_BY_VIEW,
		EventDef.Look.LORRY: EventInstance.LORRY_BY_VIEW,
	}
	t.check(EventInstance.WHEELS_BY_LOOK.size() == looks.size(),
			"the moving vehicles and nothing else roll on wheels of their own (%d looks)"
			% EventInstance.WHEELS_BY_LOOK.size())
	var named := {}
	for look: EventDef.Look in looks.keys():
		t.check(EventInstance.WHEELS_BY_LOOK.has(look), "look %d has wheels" % look)
		var wheels_by_view: Dictionary = EventInstance.WHEELS_BY_LOOK.get(look, {})
		var body_by_view: Dictionary = looks[look]
		var sources := EventInstance.family_sources(look)
		for view: String in body_by_view.keys():
			var wheels := str(wheels_by_view.get(view, ""))
			var body := str(body_by_view[view])
			named[wheels] = true
			t.check(AtlasLibrary.has_region(StringName(wheels)),
					"%s's wheels (%s) are baked" % [body, wheels])
			t.check(AtlasLibrary.native_size(StringName(wheels))
					== AtlasLibrary.native_size(StringName(body)),
					"%s's wheels share its canvas" % body)
			t.check(wheels in sources, "%s is among its look's own sources" % wheels)
	for wheels: String in EventInstance.WHEELS_BEHIND_THE_BODY:
		t.check(named.has(wheels), "%s, drawn under its body, is one of the wheels tables' own"
				% wheels)
	for parked in [EventDef.Look.DELIVERY_VAN, EventDef.Look.ICE_CREAM_VAN]:
		t.check(not EventInstance.WHEELS_BY_LOOK.has(parked),
				"a parked van (look %d) keeps its wheels in its one picture" % parked)

## **A moving vehicle's body rides about a pixel over its wheels, on a phase of ground covered, and
## a stopped one sits still.** A police patrol driven along a straight route bobs within
## `WheelBob.HEIGHT` and reaches it, the lift is `WheelBob.lift()` of exactly the ground it has
## covered, and the redraw key moves with it; the tick it covers no ground its body is back down.
func _test_a_moving_vehicle_bobs_on_its_wheels_and_a_stopped_one_sits_still(t) -> void:
	var route := PackedVector2Array([Vector2.ZERO, Vector2(2000.0, 0.0)])
	var instance := EventInstance.new()
	instance.setup(EventCatalogue.by_id("police_patrol"), Vector2.ZERO, route, Vector2.RIGHT)
	var lowest := 0.0
	var moved_ticks := 0
	var keys := {}
	for i in 240:
		instance._process(STEP)
		var bob := instance._current_bob()
		t.check(bob <= 0.0 and bob >= -WheelBob.HEIGHT - 0.001,
				"tick %d's bob %.3f stays between the wheels and one height above them" % [i, bob])
		if instance._gait_moving:
			moved_ticks += 1
			t.check(is_equal_approx(bob, WheelBob.lift(instance._path_travelled)),
					"tick %d's lift is the bob of the ground covered" % i)
		keys[instance._picture_key().z] = true
		lowest = minf(lowest, bob)
	t.check(moved_ticks > 0, "the patrol actually drove (%d ticks)" % moved_ticks)
	t.check(lowest < -0.9 * WheelBob.HEIGHT, "and its body reached the top of a rise (%.3f)" % lowest)
	t.check(lowest > -WheelBob.HEIGHT - 0.001,
			"a rise of about a pixel, not the walkers' own stride bob (%.3f)" % lowest)
	t.check(keys.size() > 2, "the redraw key moved with the body (%d heights)" % keys.size())
	instance._gait_moving = false
	t.check(instance._current_bob() == 0.0, "a vehicle that covered no ground sits on its wheels")
	instance.free()

## **Only the vehicles changed.** A dog walker has no wheels, and its bob is still the stride's own
## lift — taller than a vehicle's, since it is a step rather than a sway.
func _test_a_walking_event_keeps_its_stride_bob(t) -> void:
	var route := PackedVector2Array([Vector2.ZERO, Vector2(600.0, 0.0)])
	var instance := EventInstance.new()
	instance.setup(EventCatalogue.by_id("dog_walker"), Vector2.ZERO, route, Vector2.RIGHT)
	var lowest := 0.0
	for i in 120:
		instance._process(STEP)
		lowest = minf(lowest, instance._current_bob())
	t.check(not EventInstance.WHEELS_BY_LOOK.has(instance.def.look), "a dog walker has no wheels")
	t.check(lowest < -WheelBob.HEIGHT,
			"its stride lifts it further than a vehicle's body rises (%.3f)" % lowest)
	instance.free()

## **The badge is the thing's own picture, wheels included**: `icon_for()` of a vehicle that rolls
## is its side body, and `icon_wheels_for()` is the side view's wheels the badge draws over it on
## the same canvas; every other look answers nothing, so its badge is one picture as it was.
func _test_a_vehicle_badge_draws_its_wheels(t) -> void:
	for look: EventDef.Look in EventInstance.WHEELS_BY_LOOK.keys():
		var wheels := EventInstance.icon_wheels_for(look)
		var body := EventInstance.icon_for(look)
		t.check(wheels == str((EventInstance.WHEELS_BY_LOOK[look] as Dictionary)["side"]),
				"look %d's badge draws its side view's wheels (%s)" % [look, wheels])
		t.check(AtlasLibrary.native_size(StringName(wheels)) == AtlasLibrary.native_size(
				StringName(body)), "and they fit the badge's own rectangle for %s" % body)
	t.check(EventInstance.icon_wheels_for(EventDef.Look.DELIVERY_VAN).is_empty(),
			"a parked van's badge is its one picture")
	t.check(EventInstance.icon_wheels_for(EventDef.Look.DOG_WALKER).is_empty(),
			"and so is everything that does not roll")
