extends RefCounted
## A reproducible run choice reaches every player view and survives the day's lifecycle: the run
## keeps it, and the rig draws only the family it is handed.

const STROLLER_SCENE: PackedScene = preload("res://scenes/player/stroller.tscn")
const VIEWS: Array[String] = ["side", "front_diagonal", "front", "front_diagonal",
		"side", "back_diagonal", "back", "back_diagonal"]
const POSES: Array[String] = ["a", "c", "b"]

## The picture of the mother's pose `frame` at the view she is drawn in now, off her pose, read
## from the library she was handed (`library`).
func _mother_texture(library: AtlasLibrary, rig: Stroller, frame: int) -> Texture2D:
	return library.region(StringName(rig.pose(1.0).mother_sources[frame]))

func run(t: TestRunner) -> void:
	_test_seeded_equal_choice_and_lifetime(t)
	_test_each_family_stays_in_its_own_poses(t)
	_test_every_family_source_is_a_baked_region(t)

func _test_seeded_equal_choice_and_lifetime(t: TestRunner) -> void:
	var state := RunState.new()
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

## A rig of each family, handed its choice before it enters the tree, the way `main` hands it
## (`Stroller.draw_as_father()`), and no boot, run or city: every pose, state and facing stays in the chosen
## family, and standing aside, continuing, resetting and resolving either state never reroll it.
## **That `main` binds the choice before the first draw, on a day's way in and on the escape's, is
## `tests/test_main.gd`'s** (`_test_main_binds_the_family_before_the_first_draw`).
func _test_each_family_stays_in_its_own_poses(t: TestRunner) -> void:
	for male: bool in [false, true]:
		var rig: Stroller = STROLLER_SCENE.instantiate()
		rig.draw_as_father(male)
		var library := AtlasLibrary.new()
		rig.use_atlas(library)
		t.add_child(rig)
		rig.set_physics_process(false)
		rig.stand_aside()
		rig.step_back_in()
		rig.reset_at(Vector2.ZERO)
		for carrying: bool in [false, true]:
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
					t.check(rig.pose(1.0).view == direction
							and _mother_texture(library, rig, frame) != null,
							"the facing settles the view and the family resolves a picture for it")
			t.check(rig.pose(1.0).mother_sources[0].begins_with("rig/father_") == male,
					"standing aside, continuing, resetting and resolving either state never reroll")
		rig.free()

## Every path the rig can draw is a name the bake actually knows — the completeness check
## `assets/atlases/membership.json` wants. **Which page each one is on is
## `tests/test_atlas_loading.gd`'s**, since that is a claim about what a run loads rather than
## about the presentation choice this suite is for; what the pixels of a region owe their caller
## is `tests/test_visuals.gd`'s. The marks over her head are on the UI's page, which
## `tests/test_atlas_loading.gd` checks.
func _test_every_family_source_is_a_baked_region(t: TestRunner) -> void:
	var sources: Array[String] = []
	for views: Array[String] in [
			Stroller.MOTHER_FRONT, Stroller.MOTHER_BACK, Stroller.MOTHER_SIDE,
			Stroller.MOTHER_FRONT_DIAGONAL, Stroller.MOTHER_BACK_DIAGONAL,
			Stroller.MOTHER_CARRYING_FRONT, Stroller.MOTHER_CARRYING_BACK,
			Stroller.MOTHER_CARRYING_SIDE, Stroller.MOTHER_CARRYING_FRONT_DIAGONAL,
			Stroller.MOTHER_CARRYING_BACK_DIAGONAL,
			Stroller.FATHER_FRONT, Stroller.FATHER_BACK, Stroller.FATHER_SIDE,
			Stroller.FATHER_FRONT_DIAGONAL, Stroller.FATHER_BACK_DIAGONAL,
			Stroller.FATHER_CARRYING_FRONT, Stroller.FATHER_CARRYING_BACK,
			Stroller.FATHER_CARRYING_SIDE, Stroller.FATHER_CARRYING_FRONT_DIAGONAL,
			Stroller.FATHER_CARRYING_BACK_DIAGONAL]:
		sources.append_array(views)
	sources.append_array([Stroller.PRAM_SIDE, Stroller.PRAM_FRONT, Stroller.PRAM_BACK,
			Stroller.PRAM_FRONT_DIAGONAL, Stroller.PRAM_BACK_DIAGONAL])
	t.check(not sources.is_empty(), "the family exports at least one source")
	var families: Dictionary = {}
	for path: String in sources:
		var name := StringName(path)
		t.check(AtlasTable.baked().has_region(name), "%s is baked" % path)
		families[path.get_file().split("_")[0]] = true
	t.check(families.has("father") and families.has("mother") and families.has("pram"),
			"the family covers both parents and the shared stroller")
