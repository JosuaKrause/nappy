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

const BakedRegions := preload("res://tests/baked_regions.gd")
const StreetMap := preload("res://tests/fixtures/street_map.gd")
const PageLog := preload("res://tests/atlas_page_log.gd")

func run(t) -> void:
	_test_stroller_acquires_for_the_whole_run_and_releases_on_exit(t)
	_test_clear_keeps_the_page_and_a_second_day_still_holds_one_reference(t)
	_test_a_direct_clear_with_no_day_started_is_a_safe_no_op(t)
	_test_a_crowd_freed_without_clear_still_releases_its_page(t)
	_test_every_agent_the_crowd_makes_draws_from_the_crowds_library(t)

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
	var atlas := AtlasLibrary.new()
	var pages := PageLog.new(atlas)
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

## The real crowd over a bare world and a street-only map, with the library handed in where the
## game hands its own: no city, lights, streets or player are built around it. A day is started
## with nobody to place (`populate` off), since the page is taken on the first day whether or not
## anyone walks it.
func _crowd(t, atlas: AtlasLibrary) -> Crowd:
	var crowd := Crowd.new()
	crowd.atlas = atlas
	var world := WorldContext.new()
	t.add_child(world)
	crowd.setup(world, StreetMap.full(), null, null)
	world.add_child(crowd)
	return crowd

func _start(crowd: Crowd, day: int, tag: String) -> void:
	crowd.start_day(day, _rng(tag), Vector2.INF, false)

## The crowd's own lifetime, per `assets/atlases/membership.json`'s `crowd` entry: "the crowd
## node's own life: taken by the first day's crowd and held until the node itself is freed, since a
## page two days both draw is never released between them" — PLAYTEST-109, "don't unload anything
## that might be needed in one day and in the next". `Crowd.start_day()` acquires `ATLAS_GROUP` once,
## on the first day a crowd is ever built, and `clear()` — called at the start of every `start_day()`
## as well as directly — never releases it; only freeing the node does, which
## `_test_a_crowd_freed_without_clear_still_releases_its_page()` below covers.
##
## A second reference the second day's `start_day()` took on top of the first would leave the page
## held once the crowd is freed, so the one release line at the end is what says it took none.
func _test_clear_keeps_the_page_and_a_second_day_still_holds_one_reference(t) -> void:
	var atlas := AtlasLibrary.new()
	var pages := PageLog.new(atlas)
	var crowd := _crowd(t, atlas)
	t.check(pages.loads(Crowd.ATLAS_GROUP) == 0,
			"nothing has asked for the crowd's page before the first day")
	_start(crowd, 1, "day1")
	t.check(pages.held(Crowd.ATLAS_GROUP), "a day's crowd holds its own page")
	crowd.clear()
	t.check(pages.releases(Crowd.ATLAS_GROUP) == 0,
			"clearing the crowd keeps the page held, not released and reloaded between two days")
	_start(crowd, 2, "day2")
	t.check(pages.loads(Crowd.ATLAS_GROUP) == 1 and pages.releases(Crowd.ATLAS_GROUP) == 0,
			"a second day's start_day() draws on the page it already holds")
	crowd.clear()
	crowd.get_parent().free()
	t.check(pages.releases(Crowd.ATLAS_GROUP) == 1,
			"freeing the crowd node is what finally gives the page back, with nothing left over")
	pages.stop()

## `main._build_the_finale_city()`'s own shape — "never `Crowd.start_day()`: a cleared crowd is the
## whole of 'nobody in it', and clearing is the one call this file makes into `src/crowd/`" — calls
## `clear()` with no day ever started. `clear()` never touches `ATLAS_GROUP` at all, so this holds
## independently of whether a day ever ran; pinned anyway as the shape the finale actually
## exercises.
func _test_a_direct_clear_with_no_day_started_is_a_safe_no_op(t) -> void:
	var atlas := AtlasLibrary.new()
	var pages := PageLog.new(atlas)
	var crowd := _crowd(t, atlas)
	crowd.clear()
	t.check(pages.loads(Crowd.ATLAS_GROUP) == 0,
			"a direct clear with no day started holds nothing")
	crowd.get_parent().free()
	pages.stop()

## The leak `clear()` cannot catch, since it never releases at all: a `Crowd` freed mid-day
## — the city torn down on quitting to the title screen while a day is still running, or exactly
## this test freeing its crowd without ever calling `clear()` first. The library's counts outlive
## the freed node (in a booted game the library is the sitting's), so `Crowd._exit_tree()` is the
## only thing standing between this and a reference held for the rest of the process.
func _test_a_crowd_freed_without_clear_still_releases_its_page(t) -> void:
	var atlas := AtlasLibrary.new()
	var pages := PageLog.new(atlas)
	var crowd := _crowd(t, atlas)
	_start(crowd, 1, "freed-without-clear")
	t.check(pages.held(Crowd.ATLAS_GROUP),
			"the day's crowd holds its page before the crowd is torn down")
	crowd.get_parent().free()
	t.check(not pages.held(Crowd.ATLAS_GROUP),
			"freeing the crowd mid-day releases the crowd's page too, with no clear() in between")
	pages.stop()

## The crowd hands each agent it makes the library it holds the crowd's page on, so an agent's look
## draws its regions from the page the crowd holds. An agent handed none has no library to draw from.
func _test_every_agent_the_crowd_makes_draws_from_the_crowds_library(t) -> void:
	var atlas := AtlasLibrary.new()
	var crowd := _crowd(t, atlas)
	crowd.start_day(1, _rng("agents-draw"), Vector2.INF, true)
	var region: StringName = BakedRegions.on(Crowd.ATLAS_GROUP)[0]
	var found := 0
	var drawing := 0
	for agent in crowd.agents():
		found += 1
		if agent.picture_region(region) != null:
			drawing += 1
	t.check(found > 0, "a populated day makes agents (%d)" % found)
	t.check(drawing == found, "every agent draws a region from the crowd's library (%d of %d)" % [drawing, found])
	crowd.get_parent().queue_free()
