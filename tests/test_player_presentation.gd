extends RefCounted
## A reproducible run choice reaches every player view and survives the day's lifecycle.

const STATE_SCRIPT = preload("res://src/autoload/game_state.gd")
const MAIN_SCRIPT = preload("res://src/main.gd")
const VIEWS: Array[String] = ["side", "front_diagonal", "front", "front_diagonal",
		"side", "back_diagonal", "back", "back_diagonal"]
const POSES: Array[String] = ["a", "c", "b"]

func run(t) -> void:
	_test_seeded_equal_choice_and_lifetime(t)
	_test_main_binds_both_complete_families_before_drawing(t)
	_test_every_family_source_is_a_baked_region(t)

func _test_seeded_equal_choice_and_lifetime(t) -> void:
	var state := STATE_SCRIPT.new()
	var observed: Dictionary = {}
	for seed_value in range(1, 33):
		state.start_run(seed_value)
		var selected: bool = state.player_is_male
		observed[selected] = true
		# The independent stream must make one uniform inclusive two-way draw. This also pins
		# seed replay without requiring a statistical sample to land at exactly half.
		var expected_rng: RandomNumberGenerator = state.run_rng("player-presentation")
		t.check(selected == (expected_rng.randi_range(0, 1) == 1),
				"the presentation is the run stream's equal two-way draw")
		state.day = 9
		state.begin_day()
		state.finish_day(GameEnums.DayResult.WON)
		state.begin_day()
		state.finish_day(GameEnums.DayResult.LOST_TIMEOUT)
		t.check(state.player_is_male == selected, "winning, retrying and starting days retain the choice")
		state.start_run(seed_value)
		t.check(state.player_is_male == selected, "replaying a seed reproduces the presentation")
	t.check(observed.size() == 2, "the seed sweep exercises both families")
	state.free()

func _test_main_binds_both_complete_families_before_drawing(t) -> void:
	var saved := GameState.player_is_male
	var main := MAIN_SCRIPT.new()
	for male in [false, true]:
		GameState.player_is_male = male
		var rig: Stroller = main._make_player()
		t.check(rig.is_male == male and not rig.is_inside_tree(),
				"ordinary and escape construction share a choice bound before the first draw")
		t.add_child(rig)
		rig.set_physics_process(false)
		rig.stand_aside()
		rig.step_back_in()
		rig.reset_at(Vector2.ZERO)
		for carrying in [false, true]:
			rig.carrying = carrying
			for direction in range(8):
				rig._view_direction = direction
				for frame in range(3):
					var path := "res://assets/rig/%s_%s%s_%s.svg" % [
							"father" if male else "mother", "carrying_" if carrying else "",
							VIEWS[direction], POSES[frame]]
					var source := rig._mother_source(frame)
					t.check(source == path, "every pose/state/facing stays in its selected family")
					t.check(rig._mother_is_mirrored() == EightDirection.is_mirrored(direction),
							"both presentations retain the same west-facing mirrors")
					rig._mother_texture(frame)
			t.check(rig.is_male == male and GameState.player_is_male == male,
					"standing aside, continuing, resetting and resolving either state never reroll")
		rig.free()
	main.free()
	GameState.player_is_male = saved

## Every path the rig can draw is a name the bake actually knows — the completeness check
## `assets/atlases/membership.json` wants. **Which page each one is on is
## `tests/test_atlas_loading.gd`'s**, since that is a claim about what a run loads rather than
## about the presentation choice this suite is for; what the pixels of a region owe their caller
## is `tests/test_visuals.gd`'s.
func _test_every_family_source_is_a_baked_region(t) -> void:
	var sources := Stroller.family_sources()
	t.check(not sources.is_empty(), "the family exports at least one source")
	var families: Dictionary = {}
	for path: String in sources:
		var name := AtlasLibrary.region_name_for(path)
		t.check(AtlasLibrary.has_region(name), "%s is baked" % path)
		families[path.get_file().split("_")[0]] = true
	t.check(families.has("father") and families.has("mother") and families.has("pram"),
			"the family covers both parents and the shared stroller")
	var indicators := Stroller.indicator_sources()
	t.check(not indicators.is_empty(), "the indicators export at least one source")
	for path: String in indicators:
		var name := AtlasLibrary.region_name_for(path)
		t.check(AtlasLibrary.has_region(name), "%s is baked" % path)
		t.check(AtlasLibrary.group_of(name) == Stroller.INDICATOR_ATLAS,
				"%s is on the indicators' own page" % path)
