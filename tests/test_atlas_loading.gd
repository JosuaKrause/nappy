extends RefCounted
## When a baked page may be read from disk, and which page each picture is on.
##
## PLAYTEST-109: *"we cannot start loading something in the frame we need it"* and *"don't unload
## anything that might be needed in one day and in the next"*. `AtlasLibrary.acquire()` is a
## blocking `load()` in whatever frame calls it, so the answer is a loading window a boot opens
## and shuts by name, and a residency that holds every group any day draws for the life of the
## process. This suite holds the three halves of that none of the other atlas suites has a home
## for: the groups a run actually loads (one parent, never the other), the rule about when a page
## may arrive, and that two consecutive days never reload one.
##
## **The offending `acquire()` itself is deliberately not exercised**, the same restraint
## `tests/test_atlas_library.gd` and `tests/test_atlas_stroller_crowd.gd` each state for their own
## `region()` calls: it ends in a `push_error`, and an engine error in a suite makes the gate red
## whether or not a test expected it (M164). `AtlasLibrary.moment_for_a_load()` answers what a
## read from disk *would* be called without performing one, which is the same claim with no noise.
##
## The boot's own residency is driven through `main._hold_every_page_a_day_draws()` rather than a
## copy of its list, so a group added to `main.RESIDENT_GROUPS` is a group this suite is asking
## about. `main` is never added to the tree here, the same way `tests/test_main.gd` drives it.

const MAIN_SCRIPT := preload("res://src/main.gd")
const CITY_SCENE := preload("res://scenes/world/city.tscn")
const SEED := 4242

func run(t) -> void:
	AtlasLibrary.reset_for_tests()
	_test_each_parent_has_a_page_of_their_own(t)
	_test_the_indicators_share_the_ui_page(t)
	_test_a_boot_holds_one_parent_and_never_the_other(t)
	_test_a_page_may_only_be_read_in_a_window(t)
	_test_two_days_never_reload_a_page(t)
	AtlasLibrary.reset_for_tests()

# ------------------------------------------------------------------ the groups ---

## The split PLAYTEST-109 asked for — *"putting both genders in the player atlas is a bit wasteful
## since it's guaranteed to not use half of it"* — as the bake actually wrote it: each parent's
## sixty views on a page of their own, and the five pram views, which either parent pushes, on a
## third the run holds whichever parent it drew.
func _test_each_parent_has_a_page_of_their_own(t) -> void:
	var by_group := Stroller.sources_by_group()
	t.check(by_group.size() == 3, "the rig's pictures are spread over three groups (%d)"
			% by_group.size())
	var seen: Dictionary = {}
	for group: StringName in by_group.keys():
		var sources: Array[String] = by_group[group]
		t.check(not sources.is_empty(), "%s: there were sources to check at all" % group)
		for path: String in sources:
			var name := StringName(path)
			t.check(AtlasLibrary.has_region(name), "%s is baked" % path)
			t.check(AtlasLibrary.group_of(name) == group,
					"%s is on the '%s' page" % [path, group])
			t.check(not seen.has(name), "%s is on exactly one page" % path)
			seen[name] = group
	t.check((by_group[Stroller.MOTHER_ATLAS] as Array[String]).size()
			== (by_group[Stroller.FATHER_ATLAS] as Array[String]).size(),
			"the two parents carry the same number of views, so neither page is the other's tail")
	t.check(Stroller.stroller_sources().size() == 5, "the pram's five views are the shared group")
	t.check(Stroller.parent_atlas(false) == Stroller.MOTHER_ATLAS
			and Stroller.parent_atlas(true) == Stroller.FATHER_ATLAS,
			"the run's choice names the page it draws from")

## *"the UI and head indicators could be combined"* — one group, and the same page as the buttons,
## which is what "combined" has to mean for it to save anything. The marks are still drawn by
## their own pass and tinted on their own; a page is not a pass.
func _test_the_indicators_share_the_ui_page(t) -> void:
	t.check(Stroller.INDICATOR_ATLAS == &"ui", "the indicators name the UI's own group")
	t.check(not &"head_indicators" in AtlasLibrary.groups(),
			"and the head indicators are no longer a group of their own")
	for path: String in Stroller.indicator_sources():
		var name := StringName(path)
		t.check(AtlasLibrary.has_region(name), "%s is baked" % path)
		t.check(AtlasLibrary.group_of(name) == &"ui", "%s is on the UI's page" % path)
	t.check(AtlasLibrary.group_of(SaveIndicator._ICON) == &"ui",
			"beside the screen furniture it now shares that page with")

# ----------------------------------------------------------------- the parents ---

## A boot takes the run's own parent and drops the other, and nothing over a run of several days
## — a city built and torn down, two crowds, the rig in and out of the tree — ever asks for the
## page the run cannot draw. The drop matters because the held restart (`main._restart_run()`)
## reloads the scene into the same process and rerolls the choice: without it one process that
## restarted once would be holding both, which is the waste the split exists to remove.
func _test_a_boot_holds_one_parent_and_never_the_other(t) -> void:
	var saved := GameState.player_is_male
	var main: Node2D = MAIN_SCRIPT.new()
	AtlasLibrary.reset_for_tests()
	for male in [false, true]:
		GameState.player_is_male = male
		main._hold_every_page_a_day_draws(AtlasLibrary.MOMENT_STARTUP,
				MAIN_SCRIPT.NO_FURTHER_GROUPS)
		var mine := Stroller.parent_atlas(male)
		var theirs := Stroller.parent_atlas(not male)
		t.check(AtlasLibrary.is_acquired(mine),
				"the boot holds the '%s' page the run draws from" % mine)
		t.check(not AtlasLibrary.is_acquired(theirs),
				"and holds nothing of '%s', which this run can never draw" % theirs)
		for day in [1, 2, 3]:
			var city := _city(t)
			city.crowd.start_day(day, _rng("parent-%s-%d" % [male, day]))
			var rig := _rig(t, male)
			t.check(not AtlasLibrary.is_acquired(theirs),
					"day %d builds a city, a crowd and the rig without ever asking for '%s'"
					% [day, theirs])
			rig.free()
			city.free()
		t.check(AtlasLibrary.reference_count(mine) == 1,
				"and the run's own parent is back to the boot's single reference between days")
	t.check(not AtlasLibrary.is_acquired(Stroller.MOTHER_ATLAS),
			"a second boot that rerolled the choice gave the first run's parent back")
	main.free()
	GameState.player_is_male = saved
	AtlasLibrary.reset_for_tests()

# -------------------------------------------------------------------- the rule ---

## The three states of `moment_for_a_load()`, and the one thing a consumer's own `acquire()` does
## once a page is resident: bump a count and read nothing.
##
## `MOMENT_UNMANAGED` is not a hole in the rule for tests — it is the state of a process where no
## boot sequence has claimed the loading moments, which is every suite that builds a `Stroller`, a
## `City` or a `Crowd` by hand, and where there is no played frame for a load to stutter. The
## moment `main` boots, the rule is on for the rest of the process.
func _test_a_page_may_only_be_read_in_a_window(t) -> void:
	AtlasLibrary.reset_for_tests()
	t.check(AtlasLibrary.moment_for_a_load() == AtlasLibrary.MOMENT_UNMANAGED,
			"with no boot, nothing owns the loading moments")
	AtlasLibrary.open_loading_window(AtlasLibrary.MOMENT_DAY_BRIEF)
	t.check(AtlasLibrary.moment_for_a_load() == AtlasLibrary.MOMENT_UNMANAGED,
			"and a brief's own window cannot claim them, so driving that screen in a test "
			+ "never turns the rule on for the suites after it")
	AtlasLibrary.claim_the_loading_moments(AtlasLibrary.MOMENT_STARTUP)
	t.check(AtlasLibrary.moment_for_a_load() == AtlasLibrary.MOMENT_STARTUP,
			"an open window names the moment a load would belong to")
	AtlasLibrary.open_loading_window(AtlasLibrary.MOMENT_DAY_BRIEF)
	t.check(AtlasLibrary.moment_for_a_load() == AtlasLibrary.MOMENT_DAY_BRIEF,
			"and inside a claim the brief is the second moment a page may arrive in")
	AtlasLibrary.open_loading_window(AtlasLibrary.MOMENT_STARTUP)
	AtlasLibrary.hold_for_the_process(&"ui")
	t.check(AtlasLibrary.last_load_moment(&"ui") == AtlasLibrary.MOMENT_STARTUP,
			"and the page that arrived in it records that moment")
	t.check(AtlasLibrary.is_resident(&"ui") and AtlasLibrary.reference_count(&"ui") == 1,
			"a residency is one reference, not one per call")
	AtlasLibrary.hold_for_the_process(&"ui")
	t.check(AtlasLibrary.reference_count(&"ui") == 1, "and asking for it twice is not two")
	AtlasLibrary.close_loading_window()
	# The refusal itself is what this must not perform — see the class note. This is the same
	# claim: a page that had to be read from disk at this instant would be called OUTSIDE, which
	# is the value `acquire()` raises its engine error on.
	t.check(AtlasLibrary.moment_for_a_load() == AtlasLibrary.MOMENT_OUTSIDE,
			"with the moments claimed and the window shut, a read from disk would be OUTSIDE")
	AtlasLibrary.acquire(&"ui")
	t.check(AtlasLibrary.reference_count(&"ui") == 2,
			"a consumer acquiring a resident page outside every window is only a count")
	t.check(AtlasLibrary.last_load_moment(&"ui") == AtlasLibrary.MOMENT_STARTUP,
			"and reads nothing, so the page still records the boot that actually loaded it")
	AtlasLibrary.release(&"ui")
	t.check(AtlasLibrary.is_acquired(&"ui"),
			"releasing a consumer's reference cannot drop a resident page")
	AtlasLibrary.release_the_loading_moments()
	t.check(AtlasLibrary.moment_for_a_load() == AtlasLibrary.MOMENT_UNMANAGED,
			"and a boot that leaves the tree hands the moments back for the next one")
	AtlasLibrary.reset_for_tests()

# -------------------------------------------------------------------- the days ---

## *"don't unload anything that might be needed in one day and in the next."* The check is the
## page **object**, not the reference count: a count that dips to nought and comes back would
## look identical from the outside and would have cost a blocking read from disk in between.
func _test_two_days_never_reload_a_page(t) -> void:
	AtlasLibrary.reset_for_tests()
	var saved := GameState.player_is_male
	GameState.player_is_male = false
	var main: Node2D = MAIN_SCRIPT.new()
	main._hold_every_page_a_day_draws(AtlasLibrary.MOMENT_STARTUP, MAIN_SCRIPT.NO_FURTHER_GROUPS)
	main.free()

	var city := _city(t)
	city.crowd.start_day(1, _rng("day-1"))
	var rig := _rig(t, false)
	var first := _page_objects()
	t.check(first.size() >= MAIN_SCRIPT.RESIDENT_GROUPS.size(),
			"there were pages to compare (%d)" % first.size())
	# The whole day torn down the way quitting to the title tears it down: the rig out of the
	# tree, the city freed, every consumer's `_exit_tree()` release run.
	rig.free()
	city.crowd.clear()
	city.free()
	for group: StringName in first.keys():
		t.check(AtlasLibrary.is_acquired(group),
				"'%s' survives the day it was drawn in" % group)

	var tomorrow := _city(t)
	tomorrow.crowd.start_day(2, _rng("day-2"))
	var rig_tomorrow := _rig(t, false)
	var second := _page_objects()
	var reloaded: Array[String] = []
	for group: StringName in first.keys():
		if first[group] != second.get(group):
			reloaded.append(String(group))
	t.check(reloaded.is_empty(),
			"the next day draws the very same page objects, none re-read from disk (%s)"
			% ", ".join(reloaded))
	rig_tomorrow.free()
	tomorrow.crowd.clear()
	tomorrow.free()
	GameState.player_is_male = saved
	AtlasLibrary.reset_for_tests()

# ------------------------------------------------------------------- the rigs ---

func _rng(tag: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("test_atlas_loading:%s" % tag)
	return rng

func _city(t) -> City:
	var city: City = CITY_SCENE.instantiate()
	t.add_child(city)
	city.build(CityGenerator.generate(SEED))
	return city

## A hand-built rig, the shape `tests/test_stroller.gd` uses: a `Camera2D` named for the lookup
## `_ready()` does, and physics off so nothing moves.
func _rig(t, male: bool) -> Stroller:
	var rig := Stroller.new()
	rig.is_male = male
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	rig.add_child(camera)
	t.add_child(rig)
	rig.set_physics_process(false)
	return rig

## One live page texture per acquired group, taken through `region()` so the object compared is
## the one a draw call would actually reach rather than the library's own bookkeeping.
func _page_objects() -> Dictionary:
	var pages: Dictionary = {}
	for group: StringName in AtlasLibrary.groups():
		if not AtlasLibrary.is_acquired(group):
			continue
		var sample := _a_region_of(group)
		if sample == &"":
			continue
		var region := AtlasLibrary.region(sample)
		if region != null:
			pages[group] = region.atlas
	return pages

func _a_region_of(group: StringName) -> StringName:
	for name: StringName in AtlasLibrary.region_names():
		if AtlasLibrary.group_of(name) == group:
			return name
	return &""
