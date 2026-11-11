@warning_ignore_start("untyped_declaration")
extends RefCounted
## When a baked page may be read from disk, and which page each picture is on.
##
## PLAYTEST-109: *"we cannot start loading something in the frame we need it"* and *"don't unload
## anything that might be needed in one day and in the next"*. `AtlasLibrary.acquire()` is a
## blocking `load()` in whatever frame calls it, so the answer is a loading window a boot opens
## and shuts by name. This suite holds the two halves of that need no boot: the groups a run
## draws from (one page per parent, the indicators on the UI's page) and the rule about when a page
## may arrive. What a booted game holds and never reloads, across days and restarts, is
## `tests/test_atlas_boot.gd`'s.
##
## **The offending `acquire()` itself is deliberately not exercised**, the same restraint
## `tests/test_atlas_library.gd` and `tests/test_atlas_stroller_crowd.gd` each state for their own
## `region()` calls: it ends in a `push_error`, and an engine error in a suite makes the gate red
## whether or not a test expected it (M164). `AtlasLibrary.moment_for_a_load()` answers what a
## read from disk *would* be called without performing one, which is the same claim with no noise.

const HeadIndicators := preload("res://tests/head_indicators.gd")
const BakedRegions := preload("res://tests/baked_regions.gd")
const PageLog := preload("res://tests/atlas_page_log.gd")

func run(t: TestRunner) -> void:
	await PhysicsTicks.settle(t)
	_test_each_parent_has_a_page_of_their_own(t)
	_test_the_indicators_share_the_ui_page(t)
	_test_a_page_may_only_be_read_in_a_window(t)

# ------------------------------------------------------------------ the groups ---

## The split PLAYTEST-109 asked for — *"putting both genders in the player atlas is a bit wasteful
## since it's guaranteed to not use half of it"* — as the bake actually wrote it: each parent's
## sixty views on a page of their own, and the five pram views, which either parent pushes, on a
## third the run holds whichever parent it drew.
func _test_each_parent_has_a_page_of_their_own(t: TestRunner) -> void:
	var seen: Dictionary = {}
	var drawn_by := {}
	for male: bool in [false, true]:
		var page := Stroller.parent_atlas(male)
		var rig := Stroller.new()
		rig.draw_as_father(male)
		var camera := Camera2D.new()
		camera.name = "Camera2D"
		rig.add_child(camera)
		t.add_child(rig)
		# Every view she is drawn in, pushing and carrying, on the eight facings; the pram's with them.
		var views: Dictionary = {}
		var prams: Dictionary = {}
		for carrying in [false, true]:
			rig.carrying = carrying
			for direction in range(8):
				rig.reset_at(Vector2.ZERO, Vector2.from_angle(direction * PI / 4.0))
				var pose := rig.pose(1.0)
				for path: String in pose.mother_sources:
					views[path] = true
				prams[pose.pram_source] = true
		t.check(not views.is_empty(), "%s: there were views to check at all" % page)
		for path: String in views:
			var name := StringName(path)
			t.check(AtlasTable.baked().has_region(name), "%s is baked" % path)
			t.check(AtlasTable.baked().group_of(name) == page,
					"%s is on the '%s' page" % [path, page])
			t.check(not seen.has(name), "%s is on exactly one page" % path)
			seen[name] = page
		t.check(prams.size() == 5, "the pram has its five views (%d)" % prams.size())
		for path: String in prams:
			t.check(AtlasTable.baked().group_of(StringName(path)) == Stroller.STROLLER_ATLAS,
					"%s is on the page the two parents share" % path)
		drawn_by[male] = views.size()
		rig.free()
	t.check(drawn_by[false] == drawn_by[true],
			"the two parents carry the same number of views, so neither page is the other's tail")
	t.check(Stroller.parent_atlas(false) == Stroller.MOTHER_ATLAS
			and Stroller.parent_atlas(true) == Stroller.FATHER_ATLAS,
			"the run's choice names the page it draws from")

## *"the UI and head indicators could be combined"* — one group, and the same page as the buttons,
## which is what "combined" has to mean for it to save anything. The marks are still drawn by
## their own pass and tinted on their own; a page is not a pass.
func _test_the_indicators_share_the_ui_page(t: TestRunner) -> void:
	t.check(not &"head_indicators" in AtlasTable.baked().groups(),
			"and the head indicators are no longer a group of their own")
	for path: String in HeadIndicators.ALL:
		var name := StringName(path)
		t.check(AtlasTable.baked().has_region(name), "%s is baked" % path)
		t.check(AtlasTable.baked().group_of(name) == &"ui", "%s is on the UI's page" % path)
	# The screen furniture the indicators share the page with is swept by
	# `test_atlas_leaf_consumers.gd`'s `ui/` walk.
	for name in BakedRegions.names():
		if String(name).begins_with("ui/"):
			t.check(AtlasTable.baked().group_of(name) == &"ui", "%s is on the UI's page" % name)


# -------------------------------------------------------------------- the rule ---

## The three states of `moment_for_a_load()`, and the one thing a consumer's own `acquire()` does
## once a page is resident: bump a count and read nothing. What was read, and in which moment, is
## the run log's load line for the page.
##
## `MOMENT_UNMANAGED` is not a hole in the rule for tests — it is the state of a library no boot
## sequence has claimed the loading moments on, which is every one a suite builds along with a
## `Stroller`, a `City` or a `Crowd` by hand, and where there is no played frame for a load to
## stutter. The moment `main` boots, the rule is on for the sitting's library until it leaves.
func _test_a_page_may_only_be_read_in_a_window(t: TestRunner) -> void:
	var atlas := AtlasLibrary.new()
	var pages := PageLog.new(atlas)
	t.check(atlas.moment_for_a_load() == AtlasLibrary.MOMENT_UNMANAGED,
			"with no boot, nothing owns the loading moments")
	atlas.open_loading_window(AtlasLibrary.MOMENT_DAY_BRIEF)
	t.check(atlas.moment_for_a_load() == AtlasLibrary.MOMENT_UNMANAGED,
			"and a brief's own window cannot claim them, so driving that screen in a test "
			+ "never turns the rule on for the suites after it")
	atlas.claim_the_loading_moments(AtlasLibrary.MOMENT_STARTUP)
	t.check(atlas.moment_for_a_load() == AtlasLibrary.MOMENT_STARTUP,
			"an open window names the moment a load would belong to")
	atlas.open_loading_window(AtlasLibrary.MOMENT_DAY_BRIEF)
	t.check(atlas.moment_for_a_load() == AtlasLibrary.MOMENT_DAY_BRIEF,
			"and inside a claim the brief is the second moment a page may arrive in")
	atlas.open_loading_window(AtlasLibrary.MOMENT_STARTUP)
	atlas.hold_for_the_process(&"ui")
	t.check(pages.last_moment(&"ui") == AtlasLibrary.MOMENT_STARTUP,
			"and the page that arrived in it records that moment")
	atlas.hold_for_the_process(&"ui")
	atlas.close_loading_window()
	# The refusal itself is what this must not perform — see the class note. This is the same
	# claim: a page that had to be read from disk at this instant would be called OUTSIDE, which
	# is the value `acquire()` raises its engine error on.
	t.check(atlas.moment_for_a_load() == AtlasLibrary.MOMENT_OUTSIDE,
			"with the moments claimed and the window shut, a read from disk would be OUTSIDE")
	atlas.acquire(&"ui")
	t.check(pages.loads(&"ui") == 1,
			"a consumer acquiring a resident page outside every window is only a count")
	t.check(pages.last_moment(&"ui") == AtlasLibrary.MOMENT_STARTUP,
			"and reads nothing, so the page still records the boot that actually loaded it")
	atlas.release(&"ui")
	t.check(pages.releases(&"ui") == 0,
			"releasing a consumer's reference cannot drop a resident page")
	atlas.stop_holding(&"ui")
	t.check(pages.releases(&"ui") == 1,
			"a residency is one reference, not one per call: asked for twice, it is given back once")
	atlas.release_the_loading_moments()
	t.check(atlas.moment_for_a_load() == AtlasLibrary.MOMENT_UNMANAGED,
			"and a boot that leaves the tree hands the moments back for the next one")
	pages.stop()

# -------------------------------------------------------------------- the days ---


# ------------------------------------------------------------------ the boot ---








# ------------------------------------------------------------------- the rigs ---





