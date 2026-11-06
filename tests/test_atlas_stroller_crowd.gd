extends RefCounted
## The stroller, the head indicators and the crowd draw from `AtlasLibrary` regions rather than
## from individually preloaded textures or a runtime packer. `tests/test_stroller.gd`,
## `tests/test_stroller_gait.gd`, `tests/test_walker_views.gd` and `tests/test_car_views.gd` pin
## the drawing selection itself; this suite holds the two things specific to the move onto the
## atlas that none of those files has a natural home for: a consumer's own group is acquired for
## exactly the lifetime `assets/atlases/membership.json` states for it, and a day's crowd does not
## leave its page held once it is gone. Each lifetime is read off the run log's load and release
## lines for the page (`tests/atlas_page_log.gd`).
##
## **Which page each of her pictures is on is `tests/test_atlas_loading.gd`'s**, together with the
## rule about when a page may be read from disk at all. The holds watched here are what that rule
## rests on: with the boot holding every group resident, a consumer's acquire and release is only
## ever a count.
##
## **What a released group answers `region()` — null, with a `push_error` naming the region — is
## deliberately not exercised here**, the same restraint `tests/test_atlas_library.gd` states for
## itself: the error would be a real engine error in the run's own output, and an engine error in
## a suite makes the gate red whether or not a test expected it. Every check below reads the run
## log, without ever calling `region()` on a group it already knows is not acquired.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const PageLog := preload("res://tests/atlas_page_log.gd")
## The seed of the run the city is handed (`RunCity.with_own_run()`).
const RUN_SEED := 2
const SEED := 4242

func run(t) -> void:
	_test_stroller_acquires_for_the_whole_run_and_releases_on_exit(t)
	_test_clear_keeps_the_page_and_a_second_day_still_holds_one_reference(t)
	_test_a_direct_clear_with_no_day_started_is_a_safe_no_op(t)
	_test_a_crowd_freed_without_clear_still_releases_its_page(t)

# ------------------------------------------------------------------ stroller ---

func _rig(t, atlas: AtlasLibrary) -> Stroller:
	var rig := Stroller.new()
	rig.atlas = atlas
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	rig.add_child(camera)
	t.add_child(rig)
	rig.set_physics_process(false)
	return rig

## Her three groups — the run's own parent, the pram they share, and the UI page the marks over
## her head are on — are acquired the moment she is ready, and `_exit_tree()` is the only thing
## that ever releases them. In a booted game each of these is a count on a page the boot already
## holds; with no boot behind this rig they are the references that load and drop the pages,
## which is what makes the pairing visible at all.
func _test_stroller_acquires_for_the_whole_run_and_releases_on_exit(t) -> void:
	var pages := PageLog.new()
	var atlas := AtlasLibrary.new()
	var groups: Array[StringName] = [Stroller.parent_atlas(false), Stroller.STROLLER_ATLAS,
			Stroller.INDICATOR_ATLAS]
	var rig := _rig(t, atlas)
	t.check(not rig.is_male, "the rig this file builds draws the mother's page")
	for group in groups:
		t.check(pages.held(group),
				"'%s' is acquired the moment she is ready" % group)
	t.check(pages.loads(Stroller.parent_atlas(true)) == 0,
			"and the parent she is not is never read at all")
	rig.free()
	for group in groups:
		t.check(pages.releases(group) == 1,
				"leaving the tree releases '%s'" % group)
	pages.stop()

# ---------------------------------------------------------------------- crowd ---

func _rng(tag: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("test_atlas_stroller_crowd:%s" % tag)
	return rng

func _city(t, atlas: AtlasLibrary) -> City:
	var city: City = RunCity.with_own_run(CITY_SCENE, RUN_SEED)
	city.atlas = atlas
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
##
## A second reference the second day's `start_day()` took on top of the first would leave the page
## held once the city is freed, so the one release line at the end is what says it took none.
func _test_clear_keeps_the_page_and_a_second_day_still_holds_one_reference(t) -> void:
	var pages := PageLog.new()
	var atlas := AtlasLibrary.new()
	var city := _city(t, atlas)
	t.check(pages.loads(Crowd.ATLAS_GROUP) == 0,
			"nothing has asked for the crowd's page before the first day")
	city.crowd.start_day(1, _rng("day1"))
	t.check(pages.held(Crowd.ATLAS_GROUP), "a day's crowd holds its own page")
	city.crowd.clear()
	t.check(pages.releases(Crowd.ATLAS_GROUP) == 0,
			"clearing the crowd keeps the page held, not released and reloaded between two days")
	city.crowd.start_day(2, _rng("day2"))
	t.check(pages.loads(Crowd.ATLAS_GROUP) == 1 and pages.releases(Crowd.ATLAS_GROUP) == 0,
			"a second day's start_day() draws on the page it already holds")
	city.crowd.clear()
	city.free()
	t.check(pages.releases(Crowd.ATLAS_GROUP) == 1,
			"freeing the crowd node is what finally gives the page back, with nothing left over")
	pages.stop()

## `main._build_the_finale_city()`'s own shape — "never `Crowd.start_day()`: a cleared crowd is the
## whole of 'nobody in it', and clearing is the one call this file makes into `src/crowd/`" — calls
## `clear()` with no day ever started. `clear()` never touches `ATLAS_GROUP` at all, so this holds
## independently of whether a day ever ran; pinned anyway as the shape the finale actually
## exercises.
func _test_a_direct_clear_with_no_day_started_is_a_safe_no_op(t) -> void:
	var pages := PageLog.new()
	var atlas := AtlasLibrary.new()
	var city := _city(t, atlas)
	city.crowd.clear()
	t.check(pages.loads(Crowd.ATLAS_GROUP) == 0,
			"a direct clear with no day started holds nothing")
	city.free()
	pages.stop()

## The leak `clear()` cannot catch, since it never releases at all: a `Crowd` freed mid-day
## — the city torn down on quitting to the title screen while a day is still running, or exactly
## this test freeing its city without ever calling `clear()` first. The library's counts outlive
## the freed node (in a booted game the library is the sitting's), so `Crowd._exit_tree()` is the
## only thing standing between this and a reference held for the rest of the process.
func _test_a_crowd_freed_without_clear_still_releases_its_page(t) -> void:
	var pages := PageLog.new()
	var atlas := AtlasLibrary.new()
	var city := _city(t, atlas)
	city.crowd.start_day(1, _rng("freed-without-clear"))
	t.check(pages.held(Crowd.ATLAS_GROUP),
			"the day's crowd holds its page before the city is torn down")
	city.free()
	t.check(not pages.held(Crowd.ATLAS_GROUP),
			"freeing the city mid-day releases the crowd's page too, with no clear() in between")
	pages.stop()
