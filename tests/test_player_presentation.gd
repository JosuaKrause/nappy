extends RefCounted
## A reproducible run choice reaches every player view and survives the day's lifecycle.

const STATE_SCRIPT = preload("res://src/run/run_state.gd")
const Boot := preload("res://tests/booted_main.gd")
const Seat := preload("res://tests/seat.gd")
## The save every boot is handed, so nothing here reaches `user://save.json`.
const _SCRATCH_SAVE := "user://test_player_presentation_scratch.json"
const VIEWS: Array[String] = ["side", "front_diagonal", "front", "front_diagonal",
		"side", "back_diagonal", "back", "back_diagonal"]
const POSES: Array[String] = ["a", "c", "b"]

## The picture of the mother's pose `frame` at the view she is drawn in now, off her pose, read
## from the library she was handed.
func _mother_texture(rig: Stroller, frame: int) -> Texture2D:
	return rig.atlas.region(StringName(rig.pose(1.0).mother_sources[frame]))

func run(t) -> void:
	t.gives_back_observers()
	_test_seeded_equal_choice_and_lifetime(t)
	await _test_main_binds_both_complete_families_before_drawing(t)
	_test_every_family_source_is_a_baked_region(t)

func _test_seeded_equal_choice_and_lifetime(t) -> void:
	var state := STATE_SCRIPT.new()
	var observed: Dictionary = {}
	for seed_value in range(1, 33):
		state.start_run(seed_value)
		var selected: bool = state.header.player_is_male
		observed[selected] = true
		state.header.day = 9
		state.calendar.begin_day()
		state.calendar.finish_day(GameEnums.DayResult.WON)
		state.calendar.begin_day()
		state.calendar.finish_day(GameEnums.DayResult.LOST_TIMEOUT)
		t.check(state.header.player_is_male == selected, "winning, retrying and starting days retain the choice")
		state.start_run(seed_value)
		t.check(state.header.player_is_male == selected, "replaying a seed reproduces the presentation")
	t.check(observed.size() == 2, "the seed sweep exercises both families")
	state.free()

## Real boots of `main` for each family (`--parent`), a day's and the escape's, whose rig is caught
## the moment it enters the tree (`SceneTree.node_added`), before anything has drawn it: the choice
## is bound by then on both ways in.
func _test_main_binds_both_complete_families_before_drawing(t) -> void:
	for male in [false, true]:
		var parent := "father" if male else "mother"
		var in_the_escape: Array[bool] = []
		var escape_seat := Seat.new(t)
		var escape: Boot.Booted = await _boot_catching(t, escape_seat,
				["--parent", parent, "--start-escape"], in_the_escape)
		Telemetry.end_run()
		escape.free_all()
		escape_seat.end()
		var on_a_day: Array[bool] = []
		var seat := Seat.new(t)
		var booted: Boot.Booted = await _boot_catching(t, seat, ["--parent", parent], on_a_day)
		var rig := Boot.player(booted.main)
		t.check(in_the_escape == [male] and on_a_day == [male] and rig != null
				and rig.is_male == male,
				"ordinary and escape construction share a choice bound before the first draw")
		rig.set_physics_process(false)
		rig.stand_aside()
		rig.step_back_in()
		rig.reset_at(Vector2.ZERO)
		for carrying in [false, true]:
			rig.carrying = carrying
			for direction in range(8):
				rig.reset_at(Vector2.ZERO, Vector2.from_angle(direction * PI / 4.0))
				for frame in range(3):
					var path := "rig/%s_%s%s_%s" % [
							"father" if male else "mother", "carrying_" if carrying else "",
							VIEWS[direction], POSES[frame]]
					var source := rig.pose(1.0).mother_sources[frame]
					t.check(source == path, "every pose/state/facing stays in its selected family")
					t.check(rig.pose(1.0).mirrored == EightDirection.is_mirrored(direction),
							"both presentations retain the same west-facing mirrors")
					t.check(rig.pose(1.0).view == direction and _mother_texture(rig, frame) != null,
							"the facing settles the view and the family resolves a picture for it")
			t.check(rig.is_male == male and seat.run.header.player_is_male == male,
					"standing aside, continuing, resetting and resolving either state never reroll")
		Telemetry.end_run()
		booted.free_all()
		seat.end()

## A boot of `main` over `seat`'s run on `words`, with the family of every stroller that entered the
## tree during it, at the moment it entered, appended to `entered`.
func _boot_catching(t, seat: Seat, words: Array, entered: Array[bool]) -> Boot.Booted:
	var catch := func(node: Node) -> void:
		if node is Stroller:
			entered.append((node as Stroller).is_male)
	t.get_tree().node_added.connect(catch)
	var booted: Boot.Booted = await seat.boot(t, _SCRATCH_SAVE, words)
	t.get_tree().node_added.disconnect(catch)
	return booted

## Every path the rig can draw is a name the bake actually knows — the completeness check
## `assets/atlases/membership.json` wants. **Which page each one is on is
## `tests/test_atlas_loading.gd`'s**, since that is a claim about what a run loads rather than
## about the presentation choice this suite is for; what the pixels of a region owe their caller
## is `tests/test_visuals.gd`'s. The marks over her head are on the UI's page, which
## `tests/test_atlas_loading.gd` checks.
func _test_every_family_source_is_a_baked_region(t) -> void:
	var sources := Stroller.family_sources()
	t.check(not sources.is_empty(), "the family exports at least one source")
	var families: Dictionary = {}
	for path: String in sources:
		var name := StringName(path)
		t.check(AtlasTable.baked().has_region(name), "%s is baked" % path)
		families[path.get_file().split("_")[0]] = true
	t.check(families.has("father") and families.has("mother") and families.has("pram"),
			"the family covers both parents and the shared stroller")
