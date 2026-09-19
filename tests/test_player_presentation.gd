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
	_test_warming_and_atlas_cover_both_presentations(t)

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
					t.check(source.resource_path == path, "every pose/state/facing stays in its selected family")
					t.check(rig._mother_is_mirrored() == EightDirection.is_mirrored(direction),
							"both presentations retain the same west-facing mirrors")
					rig._mother_texture(frame)
			t.check(rig.is_male == male and GameState.player_is_male == male,
					"standing aside, continuing, resetting and resolving either state never reroll")
		rig.free()
	main.free()
	GameState.player_is_male = saved
	TextureAtlas.reset_for_tests()

func _test_warming_and_atlas_cover_both_presentations(t) -> void:
	var sources := Stroller.family_sources()
	for svg in [false, true]:
		TextureAtlas.reset_for_tests()
		TextureResolver.reset_for_tests(svg)
		TextureResolver.warm()
		var loaded := TextureResolver.load_count()
		TextureAtlas.request(Stroller.FAMILY_ATLAS, sources)
		TextureAtlas.collect(Stroller.FAMILY_ATLAS, true)
		var atlas: Texture2D = null
		var families: Dictionary = {}
		for source: Texture2D in sources:
			var resolved := TextureResolver.resolve(source)
			t.check((resolved == source) if svg else (resolved != source),
					"every family source honors PNG/default and exact SVG fallback")
			var packed := TextureAtlas.texture_for(Stroller.FAMILY_ATLAS, source, source)
			t.check(packed is AtlasTexture and packed.get_size() == source.get_size(),
					"every registered source retains native size inside the atlas")
			if packed is AtlasTexture:
				if atlas == null:
					atlas = (packed as AtlasTexture).atlas
				t.check((packed as AtlasTexture).atlas == atlas, "both complete families share one atlas")
			families[source.resource_path.get_file().split("_")[0]] = true
		t.check(families.has("father") and families.has("mother") and families.has("pram"),
				"the atlas covers both parents and the shared stroller")
		t.check(TextureResolver.load_count() == loaded, "packing every family after warm loads nothing late")
	TextureAtlas.reset_for_tests()
	TextureResolver.reset_for_tests(DevFlags.svg_requested())
