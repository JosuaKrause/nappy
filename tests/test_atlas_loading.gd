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
## about. That `main` is never added to the tree, the same way `tests/test_main.gd` drives it: it
## is handed a `Sitting` of the test's own, whose library it holds the pages on, and the cities and
## rigs the test builds are handed that library as `main` hands its own. Each test builds its own
## library, so no count it reads depends on a suite before it.
##
## Two tests boot the real `main.tscn` instead: one, on the day and in the escape's building, asks
## that everything it built draws from the one library its sitting holds; the other reads the run
## log across a played day, a held restart and day 14's hand-over for a page loaded on a library of
## a node's own.

const MAIN_SCRIPT := preload("res://src/main.gd")
const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
const CITY_SCENE := preload("res://scenes/world/city.tscn")
const UI := preload("res://tests/ui_screens.gd")
const SEED := 4242
## A save of the suite's own, handed to every boot, so nothing here reaches `user://save.json`.
const _SCRATCH_SAVE := "user://test_atlas_loading_scratch.json"

func run(t) -> void:
	t.gives_back_observers()
	_test_each_parent_has_a_page_of_their_own(t)
	_test_the_indicators_share_the_ui_page(t)
	_test_a_boot_holds_one_parent_and_never_the_other(t)
	_test_a_page_may_only_be_read_in_a_window(t)
	_test_two_days_never_reload_a_page(t)
	_test_a_boot_hands_its_one_library_to_everything_it_draws(t)
	await _test_no_boot_loads_a_page_on_a_library_of_its_own(t)

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
			t.check(AtlasTable.baked().has_region(name), "%s is baked" % path)
			t.check(AtlasTable.baked().group_of(name) == group,
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
	t.check(not &"head_indicators" in AtlasTable.baked().groups(),
			"and the head indicators are no longer a group of their own")
	for path: String in Stroller.indicator_sources():
		var name := StringName(path)
		t.check(AtlasTable.baked().has_region(name), "%s is baked" % path)
		t.check(AtlasTable.baked().group_of(name) == &"ui", "%s is on the UI's page" % path)
	t.check(AtlasTable.baked().group_of(SaveIndicator._ICON) == &"ui",
			"beside the screen furniture it now shares that page with")

# ----------------------------------------------------------------- the parents ---

## A boot takes the run's own parent and drops the other, and nothing over a run of several days
## — a city built and torn down, two crowds, the rig in and out of the tree — ever asks for the
## page the run cannot draw. The drop matters because the held restart (`main._restart_run()`)
## reloads the scene into the same process and rerolls the choice: without it one process that
## restarted once would be holding both, which is the waste the split exists to remove.
func _test_a_boot_holds_one_parent_and_never_the_other(t) -> void:
	var saved := GameState.header.player_is_male
	var main: Node2D = MAIN_SCRIPT.new()
	var sitting := Sitting.new()
	main.use_sitting(sitting)
	var atlas := sitting.atlas
	for male in [false, true]:
		GameState.header.player_is_male = male
		main._hold_every_page_a_day_draws(AtlasLibrary.MOMENT_STARTUP,
				MAIN_SCRIPT.NO_FURTHER_GROUPS)
		var mine := Stroller.parent_atlas(male)
		var theirs := Stroller.parent_atlas(not male)
		t.check(atlas.is_acquired(mine),
				"the boot holds the '%s' page the run draws from" % mine)
		t.check(not atlas.is_acquired(theirs),
				"and holds nothing of '%s', which this run can never draw" % theirs)
		for day in [1, 2, 3]:
			var city := _city(t, atlas)
			city.crowd.start_day(day, _rng("parent-%s-%d" % [male, day]))
			var rig := _rig(t, male, atlas)
			t.check(not atlas.is_acquired(theirs),
					"day %d builds a city, a crowd and the rig without ever asking for '%s'"
					% [day, theirs])
			rig.free()
			city.free()
		t.check(atlas.reference_count(mine) == 1,
				"and the run's own parent is back to the boot's single reference between days")
	t.check(not atlas.is_acquired(Stroller.MOTHER_ATLAS),
			"a second boot that rerolled the choice gave the first run's parent back")
	main.free()
	sitting.free()
	GameState.header.player_is_male = saved

# -------------------------------------------------------------------- the rule ---

## The three states of `moment_for_a_load()`, and the one thing a consumer's own `acquire()` does
## once a page is resident: bump a count and read nothing.
##
## `MOMENT_UNMANAGED` is not a hole in the rule for tests — it is the state of a library no boot
## sequence has claimed the loading moments on, which is every one a suite builds along with a
## `Stroller`, a `City` or a `Crowd` by hand, and where there is no played frame for a load to
## stutter. The moment `main` boots, the rule is on for the sitting's library until it leaves.
func _test_a_page_may_only_be_read_in_a_window(t) -> void:
	var atlas := AtlasLibrary.new()
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
	t.check(atlas.last_load_moment(&"ui") == AtlasLibrary.MOMENT_STARTUP,
			"and the page that arrived in it records that moment")
	t.check(atlas.is_resident(&"ui") and atlas.reference_count(&"ui") == 1,
			"a residency is one reference, not one per call")
	atlas.hold_for_the_process(&"ui")
	t.check(atlas.reference_count(&"ui") == 1, "and asking for it twice is not two")
	atlas.close_loading_window()
	# The refusal itself is what this must not perform — see the class note. This is the same
	# claim: a page that had to be read from disk at this instant would be called OUTSIDE, which
	# is the value `acquire()` raises its engine error on.
	t.check(atlas.moment_for_a_load() == AtlasLibrary.MOMENT_OUTSIDE,
			"with the moments claimed and the window shut, a read from disk would be OUTSIDE")
	atlas.acquire(&"ui")
	t.check(atlas.reference_count(&"ui") == 2,
			"a consumer acquiring a resident page outside every window is only a count")
	t.check(atlas.last_load_moment(&"ui") == AtlasLibrary.MOMENT_STARTUP,
			"and reads nothing, so the page still records the boot that actually loaded it")
	atlas.release(&"ui")
	t.check(atlas.is_acquired(&"ui"),
			"releasing a consumer's reference cannot drop a resident page")
	atlas.release_the_loading_moments()
	t.check(atlas.moment_for_a_load() == AtlasLibrary.MOMENT_UNMANAGED,
			"and a boot that leaves the tree hands the moments back for the next one")

# -------------------------------------------------------------------- the days ---

## *"don't unload anything that might be needed in one day and in the next."* The check is the
## page **object**, not the reference count: a count that dips to nought and comes back would
## look identical from the outside and would have cost a blocking read from disk in between.
func _test_two_days_never_reload_a_page(t) -> void:
	var saved := GameState.header.player_is_male
	GameState.header.player_is_male = false
	var main: Node2D = MAIN_SCRIPT.new()
	var sitting := Sitting.new()
	main.use_sitting(sitting)
	var atlas := sitting.atlas
	main._hold_every_page_a_day_draws(AtlasLibrary.MOMENT_STARTUP, MAIN_SCRIPT.NO_FURTHER_GROUPS)
	main.free()

	var city := _city(t, atlas)
	city.crowd.start_day(1, _rng("day-1"))
	var rig := _rig(t, false, atlas)
	var first := _page_objects(atlas)
	t.check(first.size() >= MAIN_SCRIPT.RESIDENT_GROUPS.size(),
			"there were pages to compare (%d)" % first.size())
	# The whole day torn down the way quitting to the title tears it down: the rig out of the
	# tree, the city freed, every consumer's `_exit_tree()` release run.
	rig.free()
	city.crowd.clear()
	city.free()
	for group: StringName in first.keys():
		t.check(atlas.is_acquired(group),
				"'%s' survives the day it was drawn in" % group)

	var tomorrow := _city(t, atlas)
	tomorrow.crowd.start_day(2, _rng("day-2"))
	var rig_tomorrow := _rig(t, false, atlas)
	var second := _page_objects(atlas)
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
	sitting.free()
	GameState.header.player_is_male = saved

# ------------------------------------------------------------------ the boot ---

## **One library per sitting, and everything a boot builds draws from it.** The pages a boot holds
## for the process are held on the library its `Sitting` holds, and a node that acquired or drew on
## a library of its own would load its page again outside the boot's window, unmanaged, and write a
## second load line for it. So every node under a booted `main` that holds a library — the city and
## its furniture, crowd and events, her, the screens' buttons and lines, the badge, the symbol, and
## in the escape's building the interior and its events — holds the sitting's, on the day and in
## the building alike. A node with an `atlas` it was never handed fails this by name.
func _test_a_boot_hands_its_one_library_to_everything_it_draws(t) -> void:
	var saved_section: int = GameState.facts.escape_section
	var saved_day := GameState.header.day
	for section: int in [DaySpec.Section.NONE, DaySpec.Section.BUILDING]:
		GameState.start_run(SEED)
		if section != DaySpec.Section.NONE:
			GameState.header.day = Tuning.RUN_LENGTH_DAYS
		GameState.facts.escape_section = section
		var main: Node2D = MAIN_SCENE.instantiate()
		main.configure(RunConfig.parse(PackedStringArray(["--no-save", "--no-telemetry"]), "", true))
		t.add_child(main)
		t.get_tree().process_frame.emit()
		t.get_tree().process_frame.emit()
		var where := "the day" if section == DaySpec.Section.NONE else "the building"
		var atlas: AtlasLibrary = main._sitting.atlas
		var holders := 0
		var strays: Array[String] = []
		var stack: Array[Node] = [main]
		while not stack.is_empty():
			var node: Node = stack.pop_back()
			stack.append_array(node.get_children())
			if node is Sitting or not "atlas" in node:
				continue
			holders += 1
			if node.get("atlas") != atlas and strays.size() < 5:
				strays.append(str(main.get_path_to(node)))
		t.check(holders > 10, "%s: the boot built nodes that draw from a library (%d)"
				% [where, holders])
		t.check(strays.is_empty(), "%s: every one draws from the sitting's library (not: %s)"
				% [where, ", ".join(strays)])
		t.check(atlas.is_resident(Crowd.ATLAS_GROUP) and atlas.is_resident(EventPictures.ATLAS_GROUP),
				"%s: and the sitting's library is the one holding the boot's pages" % where)
		t.get_tree().paused = false
		main.free()
	GameState.facts.escape_section = saved_section
	GameState.header.day = saved_day
	GameState.start_run(SEED)

## **A missed hand-off is red wherever and whenever the node is made.** A node handed no library
## makes its own the first time it acquires, and a library no boot has claimed the loading moments
## on loads its page freely and calls the load `unmanaged` (`AtlasLibrary.MOMENT_UNMANAGED`): no
## engine error and no `OUTSIDE` line, only the run log's load line. The tree walk above sees only
## the nodes standing two frames into a boot. So this reads the run log across a boot whose day is
## started from the title and played for a second, the held restart's reload into a second boot,
## and day 14's hand-over into the escape's boot, all three taking the one sitting parked in a home
## of the test's own (`main.use_sitting_home()`, standing for the tree's root), and no page may be
## loaded in the unmanaged anywhere in it.
func _test_no_boot_loads_a_page_on_a_library_of_its_own(t) -> void:
	var saved_section: int = GameState.facts.escape_section
	var saved_day := GameState.header.day
	GameState.facts.escape_section = DaySpec.Section.NONE
	var home := Node.new()
	t.add_child(home)
	var save := GameSave.new(_SCRATCH_SAVE)
	var reloads: Array[int] = []
	var lines: Array[String] = []

	Telemetry.begin_memory_log()
	var log: TelemetryLog = Telemetry.current_log()
	var first := await _boot_in(t, home, save, reloads)
	await _press_tap(t, first)
	for _i in 60:
		await t.get_tree().physics_frame
	(_one(first, "PauseScreen") as PauseScreen).restart_requested.emit()
	t.check(reloads.size() == 1, "the held restart reloads")
	var parked := home.get_node_or_null(NodePath(Sitting.NODE_NAME))
	t.check(parked != null and _sittings_in(home) == [parked],
			"the held restart parks the one sitting in the home")
	lines.append_array(log.lines)
	_shut(t, first)

	# The restart closed the run log; the reloaded boot's lines go in a fresh one.
	Telemetry.begin_memory_log()
	log = Telemetry.current_log()
	var second := await _boot_in(t, home, save, reloads)
	await _press_tap(t, second)
	# Day 14 after the hand-over (`DayEnd.hands_over_to_the_escape`): every task done, a win.
	GameState.header.day = Tuning.RUN_LENGTH_DAYS
	GameState.resistance.progress = Tuning.RESISTANCE_GOAL
	GameState.resistance.sabotage_done = true
	(_one(second, "DayController") as DayController).day_finished.emit(GameEnums.DayResult.WON)
	var summary := _one(second, "DaySummary")
	await UI.frames(t)
	UI.push(summary, UI.touch_at(UI.centre(UI.button(summary, "Continue")), true))
	await UI.frames(t)
	t.check(reloads.size() == 2 and GameState.facts.escape_section == DaySpec.Section.BUILDING,
			"continuing past day 14's summary reloads into the escape's building")
	t.check(parked != null and _sittings_in(home) == [parked],
			"and the second boot took the parked sitting and parks the same one again, and no other")
	_shut(t, second)
	var escape := await _boot_in(t, home, save, reloads)
	t.check(_one(escape, "InteriorScene") != null, "and that boot builds the building")
	lines.append_array(log.lines)
	_shut(t, escape)

	var loads := 0
	var at_startup := 0
	var unmanaged: Array[String] = []
	for line in lines:
		if not ("atlas page" in line and " loaded in the " in line):
			continue
		loads += 1
		if ("loaded in the %s" % AtlasLibrary.MOMENT_STARTUP) in line:
			at_startup += 1
		if ("loaded in the %s" % AtlasLibrary.MOMENT_UNMANAGED) in line:
			unmanaged.append(line.strip_edges())
	t.check(at_startup > 0, "the log heard the boots load their pages (%d loads)" % loads)
	t.check(unmanaged.is_empty(), "no page was loaded on a library of a node's own (%s)"
			% " | ".join(unmanaged.slice(0, 3)))

	Telemetry.end_run()
	home.free()
	save.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(_SCRATCH_SAVE))
	t.get_tree().paused = false
	GameState.facts.escape_section = saved_section
	GameState.header.day = saved_day
	GameState.start_run(SEED)

## The real `main.tscn` handed the suite's scratch save, a reload that only counts, and the `home`
## its sitting is parked in and taken from, put in the tree with the two frames its `_ready()`
## awaits let pass.
func _boot_in(t, home: Node, save: GameSave, reloads: Array[int]) -> Node2D:
	var main: Node2D = MAIN_SCENE.instantiate()
	main.configure(RunConfig.parse(PackedStringArray(["--no-save", "--no-telemetry", "--seed",
			str(SEED)]), "", true))
	main.use_save(save)
	main.use_sitting_home(home)
	main.use_reload(func() -> void: reloads.append(1))
	t.add_child(main)
	await t.get_tree().process_frame
	await t.get_tree().process_frame
	return main

func _shut(t, main: Node2D) -> void:
	t.get_tree().paused = false
	main.free()

## A press on the title's tap button, pushed through the viewport where the layout draws it.
func _press_tap(t, main: Node2D) -> void:
	var title := _one(main, "TitleScreen")
	await UI.frames(t)
	UI.push(title, UI.touch_at(UI.centre(UI.button(title, "Tap")), true))
	await UI.frames(t)

## The one node under `root` whose script's class or file is named `type_name`, or null.
func _one(root: Node, type_name: String) -> Node:
	var found: Array[Node] = []
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		stack.append_array(node.get_children())
		var script: Script = node.get_script()
		if script and (script.get_global_name() == type_name
				or script.resource_path.get_file().get_basename().to_pascal_case() == type_name):
			found.append(node)
	return found[0] if found.size() == 1 else null

## The `Sitting` nodes parked directly under `home`, whatever the tree named them: a second one is
## renamed on entering, so reading `Sitting.NODE_NAME` alone would find the first and miss it.
func _sittings_in(home: Node) -> Array[Node]:
	var sittings: Array[Node] = []
	for child in home.get_children():
		if child is Sitting:
			sittings.append(child)
	return sittings

# ------------------------------------------------------------------- the rigs ---

func _rng(tag: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("test_atlas_loading:%s" % tag)
	return rng

func _city(t, atlas: AtlasLibrary) -> City:
	var city: City = RunCity.of_the_run(CITY_SCENE)
	city.atlas = atlas
	t.add_child(city)
	city.build(CityGenerator.generate(SEED))
	return city

## A hand-built rig, the shape `tests/test_stroller.gd` uses: a `Camera2D` named for the lookup
## `_ready()` does, and physics off so nothing moves; handed `atlas` as `main._make_player()` hands
## the sitting's.
func _rig(t, male: bool, atlas: AtlasLibrary) -> Stroller:
	var rig := Stroller.new()
	rig.atlas = atlas
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
func _page_objects(atlas: AtlasLibrary) -> Dictionary:
	var pages: Dictionary = {}
	for group: StringName in AtlasTable.baked().groups():
		if not atlas.is_acquired(group):
			continue
		var sample := _a_region_of(group)
		if sample == &"":
			continue
		var region := atlas.region(sample)
		if region != null:
			pages[group] = region.atlas
	return pages

func _a_region_of(group: StringName) -> StringName:
	for name: StringName in AtlasTable.baked().region_names():
		if AtlasTable.baked().group_of(name) == group:
			return name
	return &""
