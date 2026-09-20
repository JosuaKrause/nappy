extends RefCounted
## The stroller, the head indicators and the crowd draw from `AtlasLibrary` regions rather than
## from individually preloaded textures or a runtime packer. `tests/test_stroller.gd`,
## `tests/test_stroller_gait.gd`, `tests/test_walker_views.gd` and `tests/test_car_views.gd` pin
## the drawing selection itself; this suite holds the three things specific to the move onto the
## atlas that none of those files has a natural home for: a consumer's own group is acquired for
## exactly the lifetime `assets/atlases/membership.json` states for it, a day's crowd does not
## leave its page held once it is gone, and the body/trim tint split survives being two baked
## regions instead of two loaded textures.
##
## **What a released group answers `region()` — null, with a `push_error` naming the region — is
## deliberately not exercised here**, the same restraint `tests/test_atlas_library.gd` states for
## itself: the error would be a real engine error in the run's own output, and an engine error in
## a suite makes the gate red whether or not a test expected it. Every check below is a state this
## suite can read — `is_acquired()`, `reference_count()`, `has_region()`, `native_size()` — without
## ever calling `region()` on a group it already knows is not acquired.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const SEED := 4242

func run(t) -> void:
	AtlasLibrary.reset_for_tests()
	_test_stroller_acquires_for_the_whole_run_and_releases_on_exit(t)
	_test_clear_keeps_the_page_and_a_second_day_still_holds_one_reference(t)
	_test_a_direct_clear_with_no_day_started_is_a_safe_no_op(t)
	_test_a_crowd_freed_without_clear_still_releases_its_page(t)
	_test_walker_body_and_trim_are_separate_regions_on_every_view(t)
	_test_car_body_and_trim_are_separate_regions_on_every_view(t)
	_test_the_strollers_body_and_pram_share_a_page_the_indicators_do_not(t)
	AtlasLibrary.reset_for_tests()

# ------------------------------------------------------------------ stroller ---

func _rig(t) -> Stroller:
	var rig := Stroller.new()
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	rig.add_child(camera)
	t.add_child(rig)
	rig.set_physics_process(false)
	return rig

## The whole run's own lifetime, from `assets/atlases/membership.json`'s own words: "the player is
## on screen from the first frame of a day". `Stroller._ready()` acquires both of her groups and
## `_exit_tree()` is the only thing that ever releases them.
func _test_stroller_acquires_for_the_whole_run_and_releases_on_exit(t) -> void:
	t.check(not AtlasLibrary.is_acquired(Stroller.FAMILY_ATLAS),
			"nothing holds the stroller's own page before she exists")
	t.check(not AtlasLibrary.is_acquired(Stroller.INDICATOR_ATLAS),
			"nor the head indicators' page")
	var rig := _rig(t)
	t.check(AtlasLibrary.is_acquired(Stroller.FAMILY_ATLAS),
			"the stroller's own group is acquired the moment she is ready")
	t.check(AtlasLibrary.is_acquired(Stroller.INDICATOR_ATLAS),
			"and so is the head indicators' group")
	rig.free()
	t.check(not AtlasLibrary.is_acquired(Stroller.FAMILY_ATLAS),
			"leaving the tree releases the stroller's own group")
	t.check(not AtlasLibrary.is_acquired(Stroller.INDICATOR_ATLAS),
			"and the head indicators' group with it")

# ---------------------------------------------------------------------- crowd ---

func _rng(tag: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("test_atlas_stroller_crowd:%s" % tag)
	return rng

func _city(t) -> City:
	var city: City = CITY_SCENE.instantiate()
	t.add_child(city)
	city.build(CityGenerator.generate(SEED))
	return city

## The crowd's own lifetime, per `assets/atlases/membership.json`'s `crowd` entry: "the crowd
## node's own life: taken by the first day's crowd and held until the node itself is freed, since a
## page two days both draw is never released between them" — PLAYTEST-109, "don't unload anything
## that might be needed in one day and in the next". `Crowd.start_day()` acquires `ATLAS_GROUP` once,
## on the first day a crowd is ever built, and `clear()` — called at the start of every `start_day()`
## as well as directly — never releases it; only freeing the node does, which
## `_test_a_crowd_freed_without_clear_still_releases_its_page()` below covers.
func _test_clear_keeps_the_page_and_a_second_day_still_holds_one_reference(t) -> void:
	var city := _city(t)
	t.check(not AtlasLibrary.is_acquired(Crowd.ATLAS_GROUP),
			"nothing has asked for the crowd's page before the first day")
	city.crowd.start_day(1, _rng("day1"))
	t.check(AtlasLibrary.is_acquired(Crowd.ATLAS_GROUP)
			and AtlasLibrary.reference_count(Crowd.ATLAS_GROUP) == 1,
			"a day's crowd holds exactly one reference on its own page")
	city.crowd.clear()
	t.check(AtlasLibrary.is_acquired(Crowd.ATLAS_GROUP)
			and AtlasLibrary.reference_count(Crowd.ATLAS_GROUP) == 1,
			"clearing the crowd keeps the page held, not released and reloaded between two days")
	city.crowd.start_day(2, _rng("day2"))
	t.check(AtlasLibrary.reference_count(Crowd.ATLAS_GROUP) == 1,
			"a second day's start_day() does not take a second reference on top of the one it "
			+ "already holds")
	city.crowd.clear()
	city.free()
	t.check(not AtlasLibrary.is_acquired(Crowd.ATLAS_GROUP),
			"freeing the crowd node is what finally gives the page back")

## `main._build_the_finale_city()`'s own shape — "never `Crowd.start_day()`: a cleared crowd is the
## whole of 'nobody in it', and clearing is the one call this file makes into `src/crowd/`" — calls
## `clear()` with no day ever started. `clear()` never touches `ATLAS_GROUP` at all, so this holds
## independently of whether a day ever ran; pinned anyway as the shape the finale actually
## exercises.
func _test_a_direct_clear_with_no_day_started_is_a_safe_no_op(t) -> void:
	var city := _city(t)
	city.crowd.clear()
	t.check(not AtlasLibrary.is_acquired(Crowd.ATLAS_GROUP),
			"a direct clear with no day started holds nothing")
	city.free()

## The leak `clear()` cannot catch, since it never releases at all: a `Crowd` freed mid-day
## — the city torn down on quitting to the title screen while a day is still running, or exactly
## this test freeing its city without ever calling `clear()` first. `AtlasLibrary`'s counts are
## static and outlive the freed node, so `Crowd._exit_tree()` is the only thing standing between
## this and a reference held for the rest of the process.
func _test_a_crowd_freed_without_clear_still_releases_its_page(t) -> void:
	var city := _city(t)
	city.crowd.start_day(1, _rng("freed-without-clear"))
	t.check(AtlasLibrary.is_acquired(Crowd.ATLAS_GROUP),
			"the day's crowd holds its page before the city is torn down")
	city.free()
	t.check(not AtlasLibrary.is_acquired(Crowd.ATLAS_GROUP),
			"freeing the city mid-day releases the crowd's page too, with no clear() in between")

# --------------------------------------------------------------- tint regression ---
# `_draw_body()` tints the body layer with the agent's own `colour` and draws the trim above it
# untinted — the split that keeps a crowd from reading as one silhouette in one colour. It only
# holds if body and trim are two distinct baked regions; a bake that ever folded the two views of
# one part into a single region would tint both at once the moment either drew.

func _test_walker_body_and_trim_are_separate_regions_on_every_view(t) -> void:
	for view in CrowdAgent.WALKER_BODY_BY_VIEW.keys():
		var body := AtlasLibrary.region_name_for(CrowdAgent.WALKER_BODY_BY_VIEW[view])
		var trim := AtlasLibrary.region_name_for(CrowdAgent.WALKER_TRIM_BY_VIEW[view])
		var body_b := AtlasLibrary.region_name_for(CrowdAgent.WALKER_BODY_BY_VIEW_B[view])
		var trim_b := AtlasLibrary.region_name_for(CrowdAgent.WALKER_TRIM_BY_VIEW_B[view])
		t.check(body != trim, "walker %s: body and trim (gait a) are separate regions" % view)
		t.check(body_b != trim_b, "walker %s: body and trim (gait b) are separate regions" % view)

func _test_car_body_and_trim_are_separate_regions_on_every_view(t) -> void:
	for view in CrowdAgent.CAR_BODY_BY_VIEW.keys():
		var body := AtlasLibrary.region_name_for(CrowdAgent.CAR_BODY_BY_VIEW[view])
		var trim := AtlasLibrary.region_name_for(CrowdAgent.CAR_TRIM_BY_VIEW[view])
		t.check(body != trim, "car %s: body and trim are separate regions" % view)

## The stroller has no per-agent tint (her family is drawn at native colour), but the same
## principle applies one level up: the body/pram family and the head indicators are drawn by two
## separate passes tinted on their own (`Stroller.FAMILY_ATLAS`'s own doc), which only holds if a
## family picture and an indicator picture are never the same baked region.
func _test_the_strollers_body_and_pram_share_a_page_the_indicators_do_not(t) -> void:
	var family_regions: Dictionary = {}
	for path: String in Stroller.family_sources():
		family_regions[AtlasLibrary.region_name_for(path)] = true
	for path: String in Stroller.indicator_sources():
		var name := AtlasLibrary.region_name_for(path)
		t.check(not family_regions.has(name),
				"indicator %s is not also one of the family's own regions" % path)
		t.check(AtlasLibrary.group_of(name) == Stroller.INDICATOR_ATLAS,
				"%s is baked on the indicators' own page, not the family's" % path)
