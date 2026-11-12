extends RefCounted
## The posters on the walls: where a sheet may go, how the walls fill day by day, the pasting-over
## rule, what a save and a lost day do to them.
##
## What a picture of a front can judge — whether the sheets read at walking distance — is the
## stills' job; this holds what a picture cannot: that no sheet is ever on a window, a door, a fire
## escape or her own block, that nothing is up before day 4 and each day's walls add to the last,
## that a kind never arrives before its day, and that the whole thing is the same from the same
## seed and given back whole by a lost day. And the tears: that a push tears and walking past does
## not, that the marble bag's shares are exact and its draws reproducible, and that a pursuit marble
## sends the pursuer on foot (`tests/test_pursuer_on_foot.gd` holds what he is and how he comes).
##
## **Every test makes a run of its own and hands it to the city** (`RunCity.with_own_run()`), and the
## tears are made the way the game makes them: a real `Stroller` in the city, a held movement key
## (`Input.action_press()`) and real physics ticks (`tests/physics_ticks.gd`, one tick a frame), the
## city's buildings stopping her at the wall. What a test reads is what the game exposes: the run's
## `PosterState`, what the fronts are handed to draw (`Building.posters`, `Building.neighbor_taken`),
## the signals the counter listens to and the pursuer the events hold.
##
## **Its cities come from the cache of generated cities** (`tests/city_map_cache.gd`): each
## seed's city is generated once in the test process and every case is handed a copy of its own,
## the same city `CityGenerator.generate()` builds for the seed.

const MapCache := preload("res://tests/city_map_cache.gd")
const CITY_SCENE := preload("res://scenes/world/city.tscn")
const STROLLER_SCENE := preload("res://scenes/player/stroller.tscn")
const SEEDS := [4242, 90210]
const POSTER_VIEW := preload("res://tests/fixtures/poster_view.gd")
## The day the pushes are made on: a day whose crews and tears run (`FIRST_DAY` on).
const DAY := 5
## How much faster than real time the long stretches run (`Engine.time_scale`), so a wait takes fewer
## ticks. Every time a check compares is in seconds, counted in ticks at this scale.
const SCALE := 2.0
## The held movement keys a push is made with.
const KEYS: Array[StringName] = [&"move_left", &"move_right", &"move_up", &"move_down"]

var _map: CityMap
var _city: City
var _run: RunState
var _her: Stroller
var _walls: PosterWalls
var _seen := {"torn": 0, "pursuit": 0}

func run(t: TestRunner) -> void:
	await PhysicsTicks.settle(t)
	_test_a_tear_is_the_poster_through_the_mask_then_the_overlay(t)
	_test_a_prepared_art_applies_the_mask_then_the_overlay_to_the_page_it_is_given(t)
	_test_the_torn_pictures_belong_to_the_art_a_city_is_handed(t)
	_test_the_wanted_notice_crosses_out_a_taken_neighbor(t)
	await _test_the_wall_draws_the_crossed_notice_from_the_run(t)
	_test_the_state_survives_a_round_trip_and_a_lost_day(t)
	_test_the_walls_fill_the_way_the_run_asks(t)
	_test_the_marble_bag_is_exact_and_reproducible(t)
	await _test_a_push_tears_and_walking_past_does_not(t)
	await _test_a_push_held_off_the_wall_does_not_tear(t)
	await _test_the_tears_draw_the_marbles(t)
	await _test_a_held_push_tears_every_sheet_she_slides_past(t)
	await _test_a_door_in_the_wall_does_not_end_the_slide(t)
	await _test_a_crew_under_a_covered_corner_does_not_paste(t)

# ----------------------------------------------------------------- the rig ---

## A real city on `seed_value`'s map in the tree, over a run of its own on day `day`, and a real
## `Stroller` in it that the events are handed, as `main` hands them (`EventManager.use_player()`).
## The day is started with every dawn already pasted, so the walls hold what a test puts on them.
func _open(t: TestRunner, seed_value: int, day := DAY) -> void:
	_map = MapCache.of(seed_value)
	_city = RunCity.with_own_run(CITY_SCENE, seed_value)
	_run = _city.run
	t.add_child(_city)
	_city.build(_map)
	_run.header.day = day
	_run.posters.pasted_through = day
	_walls = _city.poster_walls()
	_walls.start_day(day, null)
	_her = STROLLER_SCENE.instantiate()
	t.add_child(_her)
	_city.events.use_player(_her)
	_seen = {"torn": 0, "pursuit": 0}

func _close() -> void:
	_steer(Vector2.ZERO)
	_her.free()
	_city.free()

func _count_a_tear() -> void:
	_seen["torn"] += 1

func _count_a_pursuit() -> void:
	_seen["pursuit"] += 1

## Holds the movement keys for a heading, as a player holds them: each axis pressed with the
## strength of its component, all four let go for `Vector2.ZERO`.
func _steer(heading: Vector2) -> void:
	for key in KEYS:
		Input.action_release(key)
	if heading.x != 0.0:
		Input.action_press(&"move_right" if heading.x > 0.0 else &"move_left", minf(1.0, absf(heading.x)))
	if heading.y != 0.0:
		Input.action_press(&"move_down" if heading.y > 0.0 else &"move_up", minf(1.0, absf(heading.y)))

## Lets `seconds` of game time pass on real ticks.
func _wait(t: TestRunner, seconds: float) -> void:
	await PhysicsTicks.pass_ticks(t, PhysicsTicks.ticks_for(seconds, SCALE), Callable(), SCALE)

## Lets ticks pass one at a time until `done` answers true, at most `seconds` of game time; answers
## whether it did.
func _wait_until(t: TestRunner, done: Callable, seconds: float) -> bool:
	for i in PhysicsTicks.ticks_for(seconds, SCALE):
		if done.call():
			return true
		await PhysicsTicks.pass_ticks(t, 1, Callable(), SCALE)
	return done.call()

## Puts her, facing north, `depth` px below the face of the wall `dx` px in from the west edge of
## the front tile `tile`, standing, and holds `heading`. At 22px (`PLAYER_BODY_RADIUS` and
## `Stroller.PRAM_BODY_RADIUS`) the pram's body is against the face.
func _stand_at(tile: Vector2i, dx: float, heading: Vector2, depth := 24.0) -> void:
	var rect := _map.tile_rect_to_world(Rect2i(tile, Vector2i.ONE))
	_her.facing = Vector2.UP
	_her.teleport_to(Vector2(rect.position.x + dx, rect.position.y + depth))
	_steer(heading)

## Every front tile by the building it is in front of, from the buildings' own blank ground-floor
## cells, each building's tiles west to east: the same cells `PosterWalls` reads, found without it.
func _fronts_by_building() -> Array[Array]:
	var fronts := _walls.fronts()
	var found: Array[Array] = []
	for building in _city.buildings():
		var tiles: Array[Vector2i] = []
		for rect in building.blank_ground_floor_cells():
			var front := _map.world_to_tile(building.global_position
					+ Vector2(rect.get_center().x, Building.TILE * 0.5))
			if fronts.has(front):
				tiles.append(front)
		if not tiles.is_empty():
			tiles.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.x < b.x)
			found.append(tiles)
	return found

## The building whose front is `tile`, or null.
func _building_of(tile: Vector2i) -> Building:
	for building in _city.buildings():
		for rect in building.blank_ground_floor_cells():
			if _map.world_to_tile(building.global_position
					+ Vector2(rect.get_center().x, Building.TILE * 0.5)) == tile:
				return building
	return null

## The longest stretch of touching front cells in one building, at most `most` of them, west to east.
func _longest_run(most: int) -> Array[Vector2i]:
	var best: Array[Vector2i] = []
	for tiles in _fronts_by_building():
		var run: Array[Vector2i] = []
		for tile: Vector2i in tiles:
			if not run.is_empty() and tile.x != run[-1].x + 1:
				run = []
			run.append(tile)
			if run.size() > best.size():
				best.assign(run)
	return best.slice(0, most)

func _paste_all(run: Array[Vector2i]) -> void:
	_run.posters.reset()
	for tile in run:
		_run.posters.paste(tile, PosterArt.Kind.RULES, false, 1)

func _torn_in(run: Array[Vector2i]) -> int:
	var n := 0
	for tile in run:
		if _run.posters.is_torn(tile):
			n += 1
	return n

# ---------------------------------------------------------------- the tears ---

func _test_a_tear_is_the_poster_through_the_mask_then_the_overlay(t: TestRunner) -> void:
	# What a prepared art answers for each torn poster, checked pixel by pixel against the baked
	# pictures it is made of. Three kinds of pixel are told apart, each required to turn up so the
	# test cannot pass over a picture that has none: where the overlay is clear and the mask is not
	# fully opaque the poster shows through the mask's alpha (the mask's branch), where the overlay is
	# opaque the overlay's own colour is what is left (the overlay's), and where it is partly
	# transparent the result is the poster over which the overlay is blended with source-over.
	var atlas := AtlasLibrary.new()
	atlas.acquire(PosterArt.ATLAS_GROUP)
	var art := PosterArt.new()
	art.prepare(atlas)
	var page := atlas.page_image(PosterArt.ATLAS_GROUP)
	var table := AtlasTable.baked()
	var through_mask := 0
	var under_overlay := 0
	var blended := 0
	var wrong := 0
	for kind: PosterArt.Kind in PosterArt.SHEETS:
		var poster := page.get_region(table.region_rect(PosterArt.SHEETS[kind]))
		for tear in PosterArt.TEARS:
			var torn_texture := art.texture_for(atlas, kind, tear, false)
			t.check(torn_texture is ImageTexture, "a prepared art answers a composed picture for kind %d tear %d" % [kind, tear])
			if not torn_texture is ImageTexture:
				continue
			var mask := page.get_region(table.region_rect(PosterArt.TEAR_MASKS[tear]))
			var overlay := page.get_region(table.region_rect(PosterArt.TEAR_OVERLAYS[tear]))
			var torn := torn_texture.get_image()
			for y in poster.get_height():
				for x in poster.get_width():
					var got := torn.get_pixel(x, y)
					var paper := poster.get_pixel(x, y)
					var over := overlay.get_pixel(x, y)
					var alpha := paper.a * mask.get_pixel(x, y).a
					if over.a < 0.001:
						if paper.a > 0.5 and mask.get_pixel(x, y).a < 0.999:
							through_mask += 1
						if absf(got.a - alpha) > 0.02 or (alpha > 0.5 and absf(got.r - paper.r) > 0.02):
							wrong += 1
					elif over.a > 0.999:
						under_overlay += 1
						if absf(got.r - over.r) > 0.02 or absf(got.g - over.g) > 0.02 or got.a < 0.98:
							wrong += 1
					else:
						blended += 1
						var out_a := over.a + alpha * (1.0 - over.a)
						if absf(got.a - out_a) > 0.02:
							wrong += 1
	t.check(wrong == 0, "every pixel is the poster through the mask, or the overlay over it (%d off)" % wrong)
	t.check(through_mask + under_overlay + blended > 0,
			"the baked tears had pixels to compare (%d, %d, %d)" % [through_mask, under_overlay, blended])
	atlas.release(PosterArt.ATLAS_GROUP)

## No baked tear has a pixel the mask alone decides, so the recipe's two branches are held on a page
## made for it: a stand-in atlas hands the art a copy of the real page with the RULES poster, tear A's
## mask and its overlay painted by the test. The poster is solid, the mask's left half keeps the paper
## and its right half keeps a quarter of it, and the overlay is clear in the top rows, half
## transparent black in the next and opaque blue in the last. A mask the art ignored, or an overlay it
## did not blend, gives a different picture at the pixels each row names.
func _test_a_prepared_art_applies_the_mask_then_the_overlay_to_the_page_it_is_given(t: TestRunner) -> void:
	var real := AtlasLibrary.new()
	real.acquire(PosterArt.ATLAS_GROUP)
	var table := AtlasTable.baked()
	var page := real.page_image(PosterArt.ATLAS_GROUP)
	var sheet := table.region_rect(PosterArt.SHEETS[PosterArt.Kind.RULES])
	var mask_rect := table.region_rect(PosterArt.TEAR_MASKS[0])
	var overlay_rect := table.region_rect(PosterArt.TEAR_OVERLAYS[0])
	t.check(sheet.size == mask_rect.size and sheet.size == overlay_rect.size,
			"the poster, mask and overlay are one size, which the recipe relies on")
	var w := sheet.size.x
	var h := sheet.size.y
	for y in h:
		for x in w:
			page.set_pixel(sheet.position.x + x, sheet.position.y + y, Color(0.8, 0.2, 0.1, 1.0))
			page.set_pixel(mask_rect.position.x + x, mask_rect.position.y + y,
					Color(1, 1, 1, 1.0 if x < w / 2 else 0.25))
			var over := Color(0, 0, 0, 0)
			if y >= h * 3 / 4:
				over = Color(0, 0, 1, 1)
			elif y >= h / 2:
				over = Color(0, 0, 0, 0.5)
			page.set_pixel(overlay_rect.position.x + x, overlay_rect.position.y + y, over)
	var atlas := _PageAtlas.new()
	atlas.page = page
	var art := PosterArt.new()
	art.prepare(atlas)
	var torn := art.texture_for(atlas, PosterArt.Kind.RULES, 0, false).get_image()
	var left := 1
	var right := w - 2
	var clear_row := 1
	var half_row := h / 2 + 1
	var blue_row := h - 2
	var kept := torn.get_pixel(left, clear_row)
	t.check(absf(kept.r - 0.8) < 0.01 and absf(kept.a - 1.0) < 0.01,
			"where the mask keeps the paper and the overlay is clear the poster is untouched")
	t.check(absf(torn.get_pixel(right, clear_row).a - 0.25) < 0.02,
			"where the mask keeps a quarter and the overlay is clear a quarter of the paper is left (%.2f)"
					% torn.get_pixel(right, clear_row).a)
	t.check(absf(torn.get_pixel(left, half_row).a - 1.0) < 0.02
			and torn.get_pixel(left, half_row).r < 0.5,
			"a half transparent overlay darkens whole paper and leaves it opaque")
	t.check(absf(torn.get_pixel(right, half_row).a - 0.625) < 0.02,
			"a half transparent overlay over a quarter of the paper leaves 0.5 + 0.25 * 0.5 (%.2f)"
					% torn.get_pixel(right, half_row).a)
	var blue := torn.get_pixel(right, blue_row)
	t.check(blue.b > 0.98 and blue.r < 0.02 and blue.a > 0.98,
			"an opaque overlay is what is left over any paper")
	real.release(PosterArt.ATLAS_GROUP)

## An atlas whose page is the one the test made, for `PosterArt.prepare()`.
class _PageAtlas extends AtlasLibrary:
	var page: Image

	## Overrides AtlasLibrary.page_image.
	func page_image(_group: StringName) -> Image:
		return page

## The composed torn pictures belong to the `PosterArt` instance, not to the class: two instances
## compose their own, a prepared one composes nothing the second time, and a city built with one
## hands that very one to its walls and every front they dress, so what `main` keeps across days
## is what the fronts draw through.
func _test_the_torn_pictures_belong_to_the_art_a_city_is_handed(t: TestRunner) -> void:
	var atlas := AtlasLibrary.new()
	atlas.acquire(PosterArt.ATLAS_GROUP)
	var art := PosterArt.new()
	var other := PosterArt.new()
	var kind := PosterArt.Kind.LEADER
	t.check(art.texture_for(atlas, kind, 0, false) == PosterArt.sheet(atlas, kind, false),
			"before it is prepared an art answers the intact sheet, never a missing picture")
	art.prepare(atlas)
	var composed := art.texture_for(atlas, kind, 0, false)
	t.check(composed != PosterArt.sheet(atlas, kind, false) and composed is ImageTexture,
			"a prepared art answers its composed torn picture")
	art.prepare(atlas)
	t.check(art.texture_for(atlas, kind, 0, false) == composed, "preparing again composes nothing")
	t.check(other.texture_for(atlas, kind, 0, false) == PosterArt.sheet(atlas, kind, false),
			"another art holds none of the first's pictures")
	_map = MapCache.of(SEEDS[0])
	_city = RunCity.with_own_run(CITY_SCENE, SEEDS[0])
	_city.atlas = atlas
	_city.poster_art = art
	t.add_child(_city)
	_city.build(_map)
	_walls = _city.poster_walls()
	var fronts: Array = _walls.fronts().keys()
	var dressed := not fronts.is_empty()
	for tile: Vector2i in fronts:
		var building := _building_of(tile)
		dressed = dressed and building != null and building.poster_art == art
	t.check(_walls.art == art and dressed, "the city's art reaches its walls and every front they dress")
	_city.free()
	atlas.release(PosterArt.ATLAS_GROUP)

## The wanted notice is the one-X copy until the neighbor has been taken — day 10 behind her and
## its warning not among the steps she completed — and the two-X copy after, intact or torn.
func _test_the_wanted_notice_crosses_out_a_taken_neighbor(t: TestRunner) -> void:
	var atlas := AtlasLibrary.new()
	atlas.acquire(PosterArt.ATLAS_GROUP)
	var run := RunState.new()
	run.start_run(SEEDS[0])
	var plain := atlas.region(PosterArt.SHEETS[PosterArt.Kind.WANTED])
	var crossed := atlas.region(PosterArt.WANTED_CROSSED)
	t.check(plain != null and crossed != null, "both copies of the wanted notice are baked")
	run.header.day = ResistanceHappenings.NEIGHBOR_DAY + 2
	run.resistance.completed_steps = [ResistanceSteps.warning_step().index]
	t.check(PosterArt.sheet(atlas, PosterArt.Kind.WANTED, run.neighbor_was_taken()) == plain,
			"a warned neighbor's face is not crossed out")
	run.resistance.completed_steps = []
	t.check(PosterArt.sheet(atlas, PosterArt.Kind.WANTED, run.neighbor_was_taken()) == crossed,
			"a taken neighbor's face is crossed out")
	t.check(PosterArt.sheet(atlas, PosterArt.Kind.LEADER, run.neighbor_was_taken()) == atlas.region(
			PosterArt.SHEETS[PosterArt.Kind.LEADER]), "and no other kind changes")
	atlas.release(PosterArt.ATLAS_GROUP)

## **The crossed notice reaches the wall from the run's state.** No front holds a run:
## `PosterWalls` asks the run whether the neighbor was taken and hands each `Building` the answer
## with its cells (`Building.neighbor_taken`), at dawn and after a tear, and the building draws its
## sheets through `PosterArt.texture_for()` with that flag. So a taken neighbor in the run is a
## crossed notice on the wall, intact at dawn and torn after a tear, and a warned one is the plain
## notice. The tear is made by a push, on real ticks.
func _test_the_wall_draws_the_crossed_notice_from_the_run(t: TestRunner) -> void:
	var atlas := AtlasLibrary.new()
	atlas.acquire(PosterArt.ATLAS_GROUP)
	var day := ResistanceHappenings.NEIGHBOR_DAY + 2
	await _open(t, SEEDS[0], day)
	var tiles: Array = _walls.fronts().keys()
	tiles.sort()
	t.check(not tiles.is_empty(), "there is a front to paste the wanted notice on")
	if tiles.is_empty():
		_close()
		atlas.release(PosterArt.ATLAS_GROUP)
		return
	var tile: Vector2i = tiles[0]
	var building := _building_of(tile)
	var plain := atlas.region(PosterArt.SHEETS[PosterArt.Kind.WANTED])
	var crossed := atlas.region(PosterArt.WANTED_CROSSED)
	var drawn := func() -> Texture2D:
		var cell: Dictionary = _run.posters.sheet_at(tile)
		return building.poster_art.texture_for(atlas, int(cell["kind"]), int(cell["tear"]),
				building.neighbor_taken)
	_run.posters.paste(tile, PosterArt.Kind.WANTED, false, 1)

	_run.resistance.completed_steps = []
	_walls.start_day(day, null)
	t.check(building.neighbor_taken, "at dawn, a taken neighbor in the run reaches the front")
	t.check(drawn.call() == crossed, "and the front draws the crossed wanted notice")

	_run.resistance.completed_steps = [ResistanceSteps.warning_step().index]
	_walls.start_day(day, null)
	t.check(not building.neighbor_taken and drawn.call() == plain,
			"a warned neighbor's front draws the plain notice at dawn")

	_run.resistance.completed_steps = []
	_stand_at(tile, 1.0, Vector2.UP)
	var torn := await _wait_until(t, func() -> bool: return _run.posters.is_torn(tile), 3.0)
	t.check(torn, "a push tears the wanted notice")
	var which := int(_run.posters.sheet_at(tile)["tear"])
	t.check(building.neighbor_taken, "after a tear, the run's taken neighbor reaches the front")
	t.check(drawn.call() == building.poster_art.texture_for(atlas, PosterArt.Kind.WANTED, which, true)
			and drawn.call() != building.poster_art.texture_for(atlas, PosterArt.Kind.WANTED, which, false),
			"and the torn sheet is the crossed notice torn")

	_close()
	atlas.release(PosterArt.ATLAS_GROUP)

# ----------------------------------------------------------------- the state ---

func _test_the_state_survives_a_round_trip_and_a_lost_day(t: TestRunner) -> void:
	var state := PosterState.new()
	state.paste(Vector2i(3, 4), PosterArt.Kind.RULES, false, 1)
	state.paste(Vector2i(3, 4), PosterArt.Kind.LEADER, true, -1)
	state.pasted_through = 5
	state.photograph()
	state.tear(Vector2i(3, 4), 2)
	state.paste(Vector2i(9, 4), PosterArt.Kind.CURFEW, false, 1)
	for _tear in 3:
		state.count_a_tear()
	var cell: Dictionary = state.sheet_at(Vector2i(3, 4))
	t.check(int(cell["under"]) == PosterArt.Kind.RULES and int(cell["kind"]) == PosterArt.Kind.LEADER,
			"a sheet pasted over with an offset keeps the old one beneath it")
	var data := JSON.parse_string(JSON.stringify(state.to_data())) as Dictionary
	var loaded := PosterState.new()
	loaded.restore(data)
	t.check(loaded.to_data() == state.to_data(), "the walls survive a trip through a save file")
	loaded.give_back()
	t.check(loaded.cells.size() == 1 and loaded.has_intact_sheet(Vector2i(3, 4)) \
			and loaded.tears_made() == 0 and loaded.pasted_through == 5,
			"a lost day gives back the morning's walls: the tear, the crew's sheet and the count go")
	state.paste(Vector2i(3, 4), PosterArt.Kind.UNIFORM, false, 1)
	t.check(int(state.sheet_at(Vector2i(3, 4))["under"]) == PosterState.NONE \
			and not state.is_torn(Vector2i(3, 4)),
			"a sheet pasted exactly over a torn one replaces it")

# ----------------------------------------------------------------- the walls ---

func _test_the_walls_fill_the_way_the_run_asks(t: TestRunner) -> void:
	for seed_value: int in SEEDS:
		var map := MapCache.of(seed_value)
		var city := RunCity.with_own_run(CITY_SCENE, seed_value)
		var run := city.run
		t.add_child(city)
		city.build(map)
		var walls := city.poster_walls()
		t.check(walls.fronts().size() > 0, "seed %d: there are fronts to paste on (%d)"
				% [seed_value, walls.fronts().size()])
		_check_every_front_is_blank_wall(t, city, map, seed_value)
		var state := CityState.new()
		var before := 0
		var covered_on: Dictionary = {}
		for day in range(1, Tuning.RUN_LENGTH_DAYS + 1):
			state.begin_day(map.block_plans, day)
			run.posters.photograph()
			city.start_day(state, day, run.calendar.day_rng(day, "closures"))
			var cells := run.posters.cells
			if day < PosterWalls.FIRST_DAY:
				t.check(cells.is_empty(), "seed %d: nothing is on a wall on day %d" % [seed_value, day])
			for tile: Vector2i in cells:
				var kind := int(run.posters.sheet_at(tile)["kind"])
				t.check(day >= int(PosterWalls.KIND_FIRST_DAY[kind]),
						"seed %d day %d: no %s sheet before day %d" % [seed_value, day,
						PosterArt.Kind.keys()[kind], PosterWalls.KIND_FIRST_DAY[kind]])
			t.check(cells.size() >= before, "seed %d day %d: the walls add to yesterday's (%d, %d)"
					% [seed_value, day, before, cells.size()])
			before = cells.size()
			covered_on[day] = before
			if day == PosterWalls.FIRST_DAY:
				_check_the_density_floor(t, city, map, seed_value, day, FIRST_DAY_VIEW_FLOOR,
						FIRST_DAY_ROUTE_FLOOR)
			if day == Tuning.RUN_LENGTH_DAYS:
				_check_the_density_floor(t, city, map, seed_value, day, LAST_DAY_VIEW_FLOOR,
						LAST_DAY_ROUTE_FLOOR)
			if day == 6:
				_check_a_retry_pastes_the_same_dawn(t, city, state, day, seed_value)
		t.check(int(covered_on[PosterWalls.FIRST_DAY]) > 0,
				"seed %d: some posters are already up on day 4's morning" % seed_value)
		t.check(int(covered_on[Tuning.RUN_LENGTH_DAYS]) > 2 * int(covered_on[PosterWalls.FIRST_DAY]),
				"seed %d: the walls never lose a sheet by dawn and hold at least twice day 4's by the end (%d on day 4, %d on day %d)"
				% [seed_value, covered_on[PosterWalls.FIRST_DAY],
				covered_on[Tuning.RUN_LENGTH_DAYS], Tuning.RUN_LENGTH_DAYS])
		var offset := 0
		for tile: Vector2i in run.posters.cells:
			if int(run.posters.sheet_at(tile)["under"]) != PosterState.NONE:
				offset += 1
		t.check(offset > 0 and offset * 2 < run.posters.cells.size(),
				"seed %d: some sheets show an older one beneath, and most do not (%d of %d)"
				% [seed_value, offset, run.posters.cells.size()])
		city.free()

## The density floors ("on the first day with posters it's very hard to find one -- increase the
## probability throughout -- even the end doesn't have many posters"). Walking any route the day
## offers, a screen's worth of wall around her has a sheet on it at least `view_floor` of the
## time, and a whole route passes at least `route_floor` distinct sheets in view. The floors sit
## below what `tests/probes/merry_elk_poster_density.gd` measures over eight seeds. The route
## floor is per route, and the day-4 one is only two sheets, so the first day's promise is the
## view share pooled over the routes, not every route. The floors are guards against the walls
## thinning out: the route floors pass at the rates before merry-elk too, and whether the view
## floors would fail at them is not checked.
const FIRST_DAY_VIEW_FLOOR := 0.45
const FIRST_DAY_ROUTE_FLOOR := 2
const LAST_DAY_VIEW_FLOOR := 0.78
const LAST_DAY_ROUTE_FLOOR := 10

func _check_the_density_floor(t: TestRunner, city: City, map: CityMap, seed_value: int, day: int,
		view_floor: float, route_floor: int) -> void:
	var walked: Dictionary = POSTER_VIEW.walk(city, map)
	var cells := int(walked["cells"])
	var share := float(walked["with_sheet"]) / maxi(1, cells)
	var fewest: int = (walked["routes"] as Array).min() if not (walked["routes"] as Array).is_empty() \
			else 0
	t.check(cells > 0 and share >= view_floor,
			"seed %d day %d: a sheet is in view along the routes at least %d%% of the way (%.0f%%)"
			% [seed_value, day, roundi(view_floor * 100.0), share * 100.0])
	t.check(fewest >= route_floor,
			"seed %d day %d: every route passes at least %d sheets in view (fewest %d)"
			% [seed_value, day, route_floor, fewest])

## Every front tile is in front of a blank ground-floor cell of a building off her home block, and
## the cell is a real column of that building — so a sheet is never on a window, a door, a fire
## escape's column, a storefront or a portico.
func _check_every_front_is_blank_wall(t: TestRunner, city: City, map: CityMap, seed_value: int) -> void:
	var blank := {}
	for building in city.buildings():
		for rect in building.blank_ground_floor_cells():
			var front := map.world_to_tile(building.global_position
					+ Vector2(rect.get_center().x, Building.TILE * 0.5))
			blank[front] = building
	var fronts := city.poster_walls().fronts()
	var wrong: Array[String] = []
	for tile: Vector2i in fronts:
		var building: Building = blank.get(tile)
		if building == null or building.is_on_home_block() or building.power_station:
			wrong.append(str(tile))
	t.check(wrong.is_empty(), "seed %d: every poster cell is blank wall off her block (%s)"
			% [seed_value, ", ".join(wrong.slice(0, 5))])

## A lost day gives the walls back and the retry's dawn pastes them again, identically.
func _check_a_retry_pastes_the_same_dawn(t: TestRunner, city: City, state: CityState, day: int,
		seed_value: int) -> void:
	var run := city.run
	var first := run.posters.to_data()
	run.posters.give_back()
	run.posters.pasted_through = mini(run.posters.pasted_through, day - 1)
	city.start_day(state, day, run.calendar.day_rng(day, "closures"))
	t.check(run.posters.to_data()["cells"] == first["cells"],
			"seed %d: a retried day %d pastes the same dawn" % [seed_value, day])

# ------------------------------------------------------------- the marble bag ---

## The pre-bag's one marble is the run's first tear and it is safe; every bag after it holds exactly
## one pursuit in ten, whatever order the draws come out in; the same seed draws the same marbles;
## and a bag brought forward by `skip()` draws on exactly as the one that was drawn from.
func _test_the_marble_bag_is_exact_and_reproducible(t: TestRunner) -> void:
	var bags := 20
	var a := MarbleBag.new(PosterWalls.TEAR_PRE_BAG, PosterWalls.TEAR_BAG, 4242)
	var first: Array[bool] = []
	for i in PosterWalls.TEAR_PRE_BAG.size() + bags * PosterWalls.TEAR_BAG.size():
		first.append(a.draw())
	t.check(not first[0], "the run's first tear never brings a pursuer")
	var per_bag := PosterWalls.TEAR_BAG.count(true)
	var uneven: Array[String] = []
	var positions := {}
	for b in bags:
		var start := PosterWalls.TEAR_PRE_BAG.size() + b * PosterWalls.TEAR_BAG.size()
		var bag := first.slice(start, start + PosterWalls.TEAR_BAG.size())
		if bag.count(true) != per_bag:
			uneven.append("bag %d: %d" % [b, bag.count(true)])
		positions[bag.find(true)] = true
	t.check(uneven.is_empty(), "every bag after the pre-bag holds exactly %d pursuit(s) (%s)"
			% [per_bag, ", ".join(uneven)])
	t.check(positions.size() > 3, "and where in its bag the pursuit comes is drawn, not fixed (%d places)"
			% positions.size())
	var again := MarbleBag.new(PosterWalls.TEAR_PRE_BAG, PosterWalls.TEAR_BAG, 4242)
	var same := true
	for drawn in first:
		same = same and again.draw() == drawn
	t.check(same, "the same seed draws the same marbles")
	var skipped := MarbleBag.new(PosterWalls.TEAR_PRE_BAG, PosterWalls.TEAR_BAG, 4242)
	skipped.skip(17)
	var resumed := true
	for i in range(17, first.size()):
		resumed = resumed and skipped.draw() == first[i]
	t.check(resumed, "a bag skipped forward draws on exactly as the drawn one does")

# ---------------------------------------------------------------- the push ---

## **A crew under a corner the joystick's controls cover does not paste** (dappled-swan's
## the-sightings, the filer's reading that a crew's pasting is a sighting): a `poster_crew` standing on
## a front, with the day's own visible area laid so the crew is only under the left corner, pastes
## nothing in the joystick scheme over several of `PosterWalls.PASTE_EVERY`, and pastes in the tap
## scheme with the same view. The walls work the crews on the ticks they have a player to watch for,
## so a real `Stroller` stands in the city.
func _test_a_crew_under_a_covered_corner_does_not_paste(t: TestRunner) -> void:
	await _open(t, SEEDS[0])
	var tiles: Array = _walls.fronts().keys()
	tiles.sort()
	t.check(not tiles.is_empty(), "there is a front for a crew to stand at")
	if tiles.is_empty():
		_close()
		return
	var tile: Vector2i = tiles[0]
	var at := _map.tile_to_world(tile)
	var crew := _city.events.spawn_extra(EventCatalogue.by_id("poster_crew"), at)
	# She stands where the camera's view puts the crew only under the left corner the controls cover.
	var corner := TouchCover.joystick().left.get_center() - ScreenOrientation.DESIGN_SIZE * 0.5
	_her.teleport_to(at - corner * 0.5)
	await _wait(t, 0.5)
	for joystick: bool in [true, false]:
		# A day started again clears what the crews were working at.
		_walls.start_day(DAY, null)
		_run.posters.reset()
		_run.posters.pasted_through = DAY
		_city.events.use_controls(TouchCover.joystick() if joystick else null)
		await _wait(t, 0.2)
		t.check(_city.events.sees(at) != joystick,
				"%s scheme: the crew is %s from where she stands" % ["joystick" if joystick else "tap",
				"under the corner" if joystick else "in view"])
		# The tap scheme's crew is done with its first sheet at `FIRST_PASTE_AFTER`; the joystick's is
		# given two `PASTE_EVERY` more than that to paste nothing.
		await _wait(t, PosterWalls.FIRST_PASTE_AFTER + 2.0 * PosterWalls.PASTE_EVERY if joystick
				else PosterWalls.FIRST_PASTE_AFTER + 0.5)
		var pasted := _run.posters.cells.size()
		t.check((pasted == 0) == joystick,
				"%s scheme: a crew only under the left corner pasted %d sheets"
				% ["joystick" if joystick else "tap", pasted])
	_city.events.retire(crew)
	_close()

## A push tears nothing that is not a push: walking along the wall, even drifting into it, along a
## wall of intact sheets. Her heading has to point into the wall (`PosterWalls.PRESS_INTO`).
func _test_a_push_tears_and_walking_past_does_not(t: TestRunner) -> void:
	await _open(t, SEEDS[0])
	var tiles: Array = _walls.fronts().keys()
	t.check(tiles.size() > 25, "there are fronts to push against (%d)" % tiles.size())
	var run := _longest_run(6)
	t.check(run.size() >= 3, "there is a wall of at least three cells to walk along (%d)" % run.size())
	if tiles.size() <= 25 or run.size() < 3:
		_close()
		return
	var span := float(run.size()) * Tuning.TILE_SIZE / Tuning.WALK_SPEED
	_paste_all(run)
	_stand_at(run[0], 1.0, Vector2.RIGHT)
	await _wait(t, span)
	t.check(_torn_in(run) == 0, "walking along the wall tears nothing")
	_stand_at(run[0], 1.0, Vector2(1.0, -0.2))
	await _wait(t, span)
	t.check(_torn_in(run) == 0 and _her.global_position.x > _map.tile_to_world(run[1]).x,
			"and drifting into it while walking along it tears nothing")

	_paste_all(run)
	var tile := run[0]
	_stand_at(tile, 1.0, Vector2.UP)
	await _wait(t, PosterWalls.PRESS_TO_TEAR * 0.75)
	_steer(Vector2.ZERO)
	await _wait(t, 0.2)
	_stand_at(tile, 1.0, Vector2.UP)
	await _wait(t, PosterWalls.PRESS_TO_TEAR * 0.75)
	t.check(_run.posters.has_intact_sheet(tile), "letting go before the time is up starts it again")
	await _wait(t, PosterWalls.PRESS_TO_TEAR * 0.5 + 0.1)
	t.check(_run.posters.is_torn(tile), "a push held for the time tears the sheet")
	t.check(_run.posters.tears_made() == 1, "and counts one tear")

	# The diagonal slides her along the wall at walking speed, so the sheet she stands before when
	# the time is up is the one she has slid to: a wall of sheets, one of them comes down.
	_steer(Vector2.ZERO)
	await _wait(t, 0.2)
	_paste_all(run)
	_stand_at(tile, 1.0, Vector2(1.0, -1.0))
	var torn := await _wait_until(t, func() -> bool: return _torn_in(run) > 0,
			PosterWalls.PRESS_TO_TEAR + 0.4)
	t.check(torn, "a diagonal into the wall is a push too")
	_run.posters.paste(tile, PosterArt.Kind.CURFEW, false, 1)
	t.check(_run.posters.has_intact_sheet(tile), "a torn sheet pasted again is whole")
	_close()

## A heading into the wall from back on the sidewalk is a walk toward it, not a push: a bollard
## across the front tile holds her past `PosterWalls.PRESS_REACH` of the face, pressing north.
func _test_a_push_held_off_the_wall_does_not_tear(t: TestRunner) -> void:
	await _open(t, SEEDS[0])
	var tile: Vector2i = _longest_run(1)[0]
	var rect := _map.tile_rect_to_world(Rect2i(tile, Vector2i.ONE))
	var bollard := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(Tuning.TILE_SIZE * 1.5, 8.0)
	shape.shape = box
	bollard.add_child(shape)
	bollard.position = Vector2(rect.get_center().x, rect.position.y + 2.0)
	_city.add_child(bollard)
	_run.posters.paste(tile, PosterArt.Kind.RULES, false, 1)
	_stand_at(tile, Tuning.TILE_SIZE * 0.5, Vector2.UP, Tuning.TILE_SIZE - 1.0)
	await _wait(t, 2.0)
	var back := _her.global_position.y - rect.position.y
	t.check(back > PosterWalls.PRESS_REACH and back < Tuning.TILE_SIZE,
			"she is held on the front tile, back of the push's reach (%.1fpx from the face)" % back)
	t.check(_run.posters.has_intact_sheet(tile),
			"a heading into the wall from back on the sidewalk tears nothing")
	bollard.free()
	await _wait(t, PosterWalls.PRESS_TO_TEAR + 0.2)
	t.check(_run.posters.is_torn(tile), "and the same push at the face tears it")
	_close()

## The tears' marbles, one push to a fresh sheet each: the pre-bag and two whole bags after it. The
## run's first tear sends nobody, two whole bags send exactly two pursuers, every tear and every
## pursuer tells the counter once, a lost day gives the tears back so the retry draws the same
## marbles again, and a marble drawn while a pursuer is on his way sends nobody more.
func _test_the_tears_draw_the_marbles(t: TestRunner) -> void:
	await _open(t, SEEDS[0])
	var tiles: Array = _walls.fronts().keys()
	tiles.sort()
	var tears := PosterWalls.TEAR_PRE_BAG.size() + 2 * PosterWalls.TEAR_BAG.size()
	t.check(tiles.size() > tears, "there are fronts to tear (%d)" % tiles.size())
	if tiles.size() <= tears:
		_close()
		return
	EventBus.poster_torn.connect(_count_a_tear)
	EventBus.poster_pursuit_sent.connect(_count_a_pursuit)
	_run.posters.photograph()
	var first_marbles := await _tear_one_sheet_each(t, tiles, tears)
	t.check(_run.posters.tears_made() == tears, "every push tore its sheet (%d of %d)"
			% [_run.posters.tears_made(), tears])
	t.check(not first_marbles[0], "the run's first tear sends nobody")
	t.check(first_marbles.count(true) == 2, "two whole bags of tears send exactly two pursuers (%d)"
			% first_marbles.count(true))
	t.check(_seen["torn"] == tears, "every tear tells the counter (%d of %d)" % [_seen["torn"], tears])
	t.check(_seen["pursuit"] == first_marbles.count(true),
			"and every pursuer a tear sent tells it too, once each (%d)" % _seen["pursuit"])
	_run.posters.give_back()
	var again := await _tear_one_sheet_each(t, tiles, tears)
	t.check(again == first_marbles, "a lost day gives the tears back and the retry draws the same marbles")
	await _let_the_pursuer_go(t)
	var before: int = _seen["pursuit"]
	_city.events.send_a_pursuer()
	_city.events.send_a_pursuer()
	t.check(_seen["pursuit"] == before + 1,
			"a second marble while the pursuer is on his way sends nobody, told to the counter once")
	EventBus.poster_torn.disconnect(_count_a_tear)
	EventBus.poster_pursuit_sent.disconnect(_count_a_pursuit)
	_close()

## Pushes `count` fresh sheets down one at a time, her held north against each wall, and answers for
## each whether its tear sent a pursuer. A pursuer sent is let go once he is in the world, so the
## next marble is asked about on its own.
func _tear_one_sheet_each(t: TestRunner, tiles: Array, count: int) -> Array[bool]:
	var sent: Array[bool] = []
	for i in count:
		var tile: Vector2i = tiles[i]
		_run.posters.paste(tile, PosterArt.Kind.RULES, false, 1)
		var pursuits: int = _seen["pursuit"]
		_stand_at(tile, Tuning.TILE_SIZE * 0.5, Vector2.UP)
		await _wait_until(t, func() -> bool: return _run.posters.is_torn(tile), 2.0)
		sent.append(_seen["pursuit"] > pursuits)
		if sent[-1]:
			await _let_the_pursuer_go(t, true)
	return sent

## Waits for the pursuer a tear sent to be in the world, takes him out of it, and lets a tick pass.
## `expected` says one was sent, so that he must come into the world within the wait.
func _let_the_pursuer_go(t: TestRunner, expected := false) -> void:
	var def := EventCatalogue.on_foot_on(DaySpec.for_day(_city.events.world.day))
	var found: Array[EventInstance] = []
	await _wait_until(t, func() -> bool:
		found.assign(_city.events.instances().filter(func(e: EventInstance) -> bool:
				return e.def == def))
		return not found.is_empty(), 3.0)
	if expected:
		t.check(not found.is_empty(), "the pursuer a tear sent comes into the world")
	for pursuer in found:
		_city.events.retire(pursuer)
	await PhysicsTicks.pass_ticks(t, 2, Callable(), SCALE)

# ---------------------------------------------------------------- the slide ---

## A push held along a wall of intact sheets: the first takes `PRESS_TO_TEAR`, then every next sheet
## tears as she comes in front of it, at the speed a diagonal slides her (the old once-per-timer
## rule skipped a sheet in two at this speed: each tear left the next cell's count to start from
## zero). Letting go re-arms the wait; walking past without a push tears nothing; and each sheet
## torn draws its own marble.
func _test_a_held_push_tears_every_sheet_she_slides_past(t: TestRunner) -> void:
	await _open(t, SEEDS[0])
	var run := _longest_run(6)
	t.check(run.size() >= 3, "there is a wall of at least three cells to slide along (%d)" % run.size())
	if run.size() < 3:
		_close()
		return
	var sheets := run.size()
	var diagonal := Vector2(1.0, -1.0)
	var last_left := _map.tile_rect_to_world(Rect2i(run[-1], Vector2i.ONE)).position.x
	var reached_the_last := func() -> bool: return _her.global_position.x > last_left + 8.0
	var guard := float(sheets) * Tuning.TILE_SIZE / 40.0 + PosterWalls.PRESS_TO_TEAR

	# She stops against the first sheet until it gives (a heading straight into the wall), then
	# slides on with the push held (the diagonal).
	_paste_all(run)
	_stand_at(run[0], 1.0, Vector2.UP)
	await _wait_until(t, func() -> bool: return _run.posters.is_torn(run[0]),
			PosterWalls.PRESS_TO_TEAR + 0.2)
	_steer(diagonal)
	await _wait_until(t, reached_the_last, guard)
	t.check(reached_the_last.call(), "she slid along the whole run")
	t.check(_torn_in(run) == sheets, "a diagonal held along %d adjacent sheets tears all of them (%d)"
			% [sheets, _torn_in(run)])
	t.check(_run.posters.tears_made() == sheets, "and draws one marble for each (%d)" % _run.posters.tears_made())

	# The first sheet of a push still waits for the time.
	_steer(Vector2.ZERO)
	await _wait(t, 0.1)
	_paste_all(run)
	_stand_at(run[0], 1.0, Vector2.UP)
	await _wait(t, PosterWalls.PRESS_TO_TEAR * 0.75)
	t.check(_torn_in(run) == 0, "the first sheet of a push still waits for the time")
	var passed := await _wait_until(t, func() -> bool: return _torn_in(run) > 0,
			PosterWalls.PRESS_TO_TEAR)
	t.check(passed and _torn_in(run) == 1 and _run.posters.is_torn(run[0]),
			"and tears once it has passed")

	# The push a player makes: a diagonal held while walking into the wall, never stopping, slides
	# her along at walking speed (the wall keeps her speed along it), so the 0.4s covers about 37px,
	# more than a 32px cell. Entering the wall 20px into the first cell, that sheet is slid past before it elapses and
	# escapes, the second tears, and every sheet after it comes down as she reaches it (the old rule
	# restarted the count after each tear and so skipped every second one).
	_steer(Vector2.ZERO)
	await _wait(t, 0.1)
	_paste_all(run)
	_stand_at(run[0], 20.0, diagonal)
	await _wait_until(t, reached_the_last, guard)
	t.check(_run.posters.has_intact_sheet(run[0]),
			"the sheet she was already past when the time elapsed escapes the first tear")
	var rest_torn := true
	for i in range(1, sheets):
		rest_torn = rest_torn and _run.posters.is_torn(run[i])
	t.check(rest_torn, "and every sheet after the first tear comes down as she reaches it")
	t.check(_run.posters.tears_made() == sheets - 1, "one marble each (%d)" % _run.posters.tears_made())

	# Letting go re-arms the wait: the next sheet she stands before takes the time again.
	_steer(Vector2.ZERO)
	await _wait(t, 0.2)
	_run.posters.paste(run[0], PosterArt.Kind.RULES, false, 1)
	_stand_at(run[0], 1.0, Vector2.UP)
	await _wait(t, PosterWalls.PRESS_TO_TEAR * 0.75)
	t.check(_run.posters.has_intact_sheet(run[0]),
			"after letting go the next push waits for the time again")
	_close()

## A door, a portico or a fire escape's column is a front tile with no sheet. Crossing one at
## walking speed takes under 0.4s, so a slide that ended there would start its count again and the
## sheet after the door would escape. The door is a real one: a front tile of the city between two
## cells of the same wall that carry no sheet. A push held across it tears the sheet beyond at once;
## turning out of the wall in the doorway, or walking off the front, ends the slide so that the next
## push waits for the time again.
func _test_a_door_in_the_wall_does_not_end_the_slide(t: TestRunner) -> void:
	await _open(t, SEEDS[0])
	var fronts := _walls.fronts()
	var run: Array[Vector2i] = []
	for tile: Vector2i in fronts:
		var door := tile + Vector2i.RIGHT
		# A front by the map's own reading (the sidewalk in front of a building) that no sheet goes on.
		if not fronts.has(door) and fronts.has(door + Vector2i.RIGHT) \
				and _map.pavement_inward(door) == Vector2i.UP \
				and _map.tile_at(door + Vector2i.UP) == GameEnums.TileType.BUILDING \
				and (run.is_empty() or tile < run[0]):
			run.assign([tile, door, door + Vector2i.RIGHT])
	t.check(run.size() == 3, "there are two cells with a door between them to push across")
	if run.size() != 3:
		_close()
		return
	var diagonal := Vector2(1.0, -1.0)
	var across := func() -> bool: return _run.posters.is_torn(run[2])
	_run.posters.paste(run[0], PosterArt.Kind.RULES, false, 1)
	_run.posters.paste(run[2], PosterArt.Kind.RULES, false, 1)
	# She stands against the first sheet until it gives, then slides across the door to the third.
	_stand_at(run[0], 1.0, Vector2.UP)
	var first := await _wait_until(t, func() -> bool: return _run.posters.is_torn(run[0]),
			PosterWalls.PRESS_TO_TEAR + 0.2)
	t.check(first, "the sheet before the door tears")
	_steer(diagonal)
	var crossed := await _wait_until(t, across, 3.0 * Tuning.TILE_SIZE / 40.0)
	t.check(crossed, "a push held across a door tears the next sheet at once")
	var tears: int = _run.posters.tears_made()
	var beyond_door := _map.tile_rect_to_world(Rect2i(run[2], Vector2i.ONE)).position.x
	t.check(_her.global_position.x > beyond_door and tears == 2,
			"she tore it as she came in front of it, not before the door (%d tears)" % tears)

	# Turning out of the wall in the doorway ends the slide: the next sheet waits for the time.
	_stand_at(run[1], 4.0, Vector2.RIGHT)
	await _wait(t, 0.1)
	# The diagonal is held before she is put in front of the sheet, so that the walls have read
	# the new heading by the first tick she is there.
	_steer(diagonal)
	await _wait(t, 0.1)
	_run.posters.paste(run[2], PosterArt.Kind.RULES, false, 1)
	_stand_at(run[2], 1.0, diagonal)
	await _wait(t, PosterWalls.PRESS_TO_TEAR * 0.75)
	t.check(_run.posters.has_intact_sheet(run[2]),
			"turning out of the wall in the doorway ends the slide")

	# Leaving the front altogether ends it too: a point far from the wall is no front tile.
	_run.posters.paste(run[0], PosterArt.Kind.RULES, false, 1)
	_stand_at(run[0], 1.0, Vector2.UP)
	await _wait_until(t, func() -> bool: return _run.posters.is_torn(run[0]),
			PosterWalls.PRESS_TO_TEAR + 0.2)
	_steer(diagonal)
	await _wait(t, 0.5)
	_stand_at(run[1], 4.0, diagonal, 5.0 * Tuning.TILE_SIZE)
	await _wait(t, 0.1)
	# The diagonal is held before she is put in front of the sheet, so that the walls have read
	# the new heading by the first tick she is there.
	_steer(diagonal)
	await _wait(t, 0.1)
	_run.posters.paste(run[2], PosterArt.Kind.RULES, false, 1)
	_stand_at(run[2], 1.0, diagonal)
	await _wait(t, PosterWalls.PRESS_TO_TEAR * 0.75)
	t.check(_run.posters.has_intact_sheet(run[2]), "walking off the front ends the slide")
	_close()
